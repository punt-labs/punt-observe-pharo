"""PHARO-TEL-2/3: independent image salt, SQLite contention and integrity gate."""

import hashlib
import hmac
import json
import os
from pathlib import Path
import sqlite3
import stat
import subprocess
import sys
import time


def literal(value):
    return "'" + str(value).replace("'", "''") + "'"


def until(predicate, processes, seconds=45):
    deadline = time.monotonic() + seconds
    while not predicate():
        assert all(p.poll() is None for p in processes), "child exited early"
        assert time.monotonic() < deadline, "child barrier deadline"
        time.sleep(0.01)


def main():
    vm, image, directory = sys.argv[1:]
    root = Path(directory)
    home = root / "telemetry-home"
    home.mkdir()
    children = []
    for worker in range(2):
        script = root / f"telemetry-{worker}.st"
        script.write_text(f"""| telemetry started elapsed |
[
telemetry := PuntTelemetry startTool: 'sample-tool' config: PuntTelemetryConfig new schemas: {{ PuntTestObservation }}.
started := Time millisecondClockValue.
[ telemetry worker pipeline isNil ] whileTrue: [
  (Time millisecondsSince: started) > 30000 ifTrue: [ Error signal: 'worker startup deadline' ].
  (Delay forMilliseconds: 10) wait ].
{literal(root / f'ready-tel-{worker}')} asFileReference writeStreamDo: [ :s | s nextPutAll: 'ready' ].
[ {literal(root / 'go-tel')} asFileReference exists ] whileFalse: [ (Delay forMilliseconds: 10) wait ].
started := Time millisecondClockValue.
elapsed := 0.
[ telemetry worker pipeline store transaction: [ ] ] on: Error do: [ :error | elapsed := Time millisecondsSince: started ].
{literal(root / f'elapsed-{worker}')} asFileReference writeStreamDo: [ :s | s print: elapsed ].
[ {literal(root / 'release-tel')} asFileReference exists ] whileFalse: [ (Delay forMilliseconds: 10) wait ].
1 to: 100 do: [ :index | | observation |
  observation := PuntTestObservation new outcome: #ok; items: {worker * 1000} + index; identifier: 'worker-{worker}-' , index asString.
  started := Time millisecondClockValue.
  [ telemetry record: observation ] whileFalse: [
    (Time millisecondsSince: started) > 5000 ifTrue: [ Error signal: 'admission deadline' ].
    (Delay forMilliseconds: 1) wait ] ].
telemetry shutdown.
Smalltalk exit: 0
] on: Error do: [ :error |
  {literal(root / f'error-{worker}')} asFileReference writeStreamDo: [ :s | s nextPutAll: error description ].
  Smalltalk exit: 3 ].
""")
        env = os.environ.copy()
        env["HOME"] = str(home)
        env.pop("PUNT_TELEMETRY", None)
        env.pop("SAMPLE_TOOL_TELEMETRY", None)
        if sys.platform.startswith("linux"):
            env["LD_LIBRARY_PATH"] = str(Path(vm).parent) + os.pathsep + env.get("LD_LIBRARY_PATH", "")
        children.append(subprocess.Popen([vm, "--headless", image, "st", str(script)], env=env,
                                         stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                         stderr=subprocess.DEVNULL))
    try:
        until(lambda: all((root / f"ready-tel-{i}").exists() for i in range(2)), children)
        database = home / ".punt-labs/sample-tool/telemetry.db"
        with sqlite3.connect(database) as connection:
            connection.execute("BEGIN IMMEDIATE")
            (root / "go-tel").touch()
            until(lambda: all((root / f"elapsed-{i}").exists() for i in range(2)), children)
            for i in range(2):
                elapsed = int((root / f"elapsed-{i}").read_text())
                assert 150 <= elapsed <= 1200, f"busy_timeout not bounded: {elapsed}"
            connection.rollback()
        (root / "release-tel").touch()
        for worker, child in enumerate(children):
            code = child.wait(timeout=60)
            error = root / f"error-{worker}"
            assert code == 0, error.read_text() if error.exists() else f"child exited: {code}"
        with sqlite3.connect(database) as connection:
            assert connection.execute("PRAGMA integrity_check").fetchone() == ("ok",)
            assert connection.execute("PRAGMA journal_mode").fetchone() == ("delete",)
            rows = connection.execute("SELECT attributes FROM signals").fetchall()
        assert len(rows) == 200, f"missing records: {len(rows)}"
        salt = (home / ".punt-labs/telemetry.salt").read_bytes()
        assert len(salt) == 32
        attributes = [json.loads(row[0]) for row in rows]
        expected = {hmac.new(salt, f"worker-{w}-{i}".encode(), hashlib.sha256).hexdigest()
                    for w in range(2) for i in range(1, 101)}
        assert {a["identifier"] for a in attributes} == expected
        assert len({a["items"] for a in attributes}) == 200
        data = database.read_bytes()
        assert salt not in data and salt.hex().encode() not in data and b"worker-" not in data
        for path in (home / ".punt-labs").rglob("*"):
            assert stat.S_IMODE(path.stat().st_mode) == (0o700 if path.is_dir() else 0o600), path
        print("PUNT-TELEMETRY-IMAGES-OK: 2 images, 200 rows, atomic salt, bounded busy waits, integrity and modes")
    finally:
        for child in children:
            if child.poll() is None:
                child.kill()
            child.wait()


if __name__ == "__main__":
    main()
