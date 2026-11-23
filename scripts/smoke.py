"""Installed-path smoke orchestration and fail-closed inspection, standard library only."""

import base64
from contextlib import closing, suppress
import hashlib
import hmac
import json
import os
from pathlib import Path
import re
import sqlite3
import stat
import subprocess
import sys
import time
import unicodedata


TOOL = "punt-observe-smoke"
BOUND = 5242880
RAW_SUBJECT = b"smoke-raw-subject-identifier"
SECRETS = (b"fixture-user", b"fixture-pass", b"/private", b"fixture-query", b"fixture-fragment",
           b"fixture.example.invalid", b"FIXTURE-BEARER-SECRET", b"smoke.customer@example.invalid")
PAYLOAD = ("p" * 93 + " ") * 500
LINE = re.compile(r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \[(DEBUG|INFO|WARNING|ERROR)\] ([a-z][a-z0-9-]*): (.*)")


def log_lines(data, allow_empty=False):
    if not data and allow_empty:
        return []
    if not data or not data.endswith(b"\n"):
        raise ValueError("empty log or unterminated record")
    text = data.decode("utf-8")
    if any((ord(char) < 32 and char != "\n") or 127 <= ord(char) <= 159
           or ord(char) in (8232, 8233) or unicodedata.category(char) == "Cf" for char in text):
        raise ValueError("raw control character")
    lines = text[:-1].split("\n")
    if any(len(line.encode()) + 1 > 65536 for line in lines):
        raise ValueError("record exceeds 64 KiB")
    if not all(LINE.fullmatch(line) for line in lines):
        raise ValueError("invalid line format")
    return lines


class Smoke:
    def __init__(self, root):
        self.root = root.resolve()
        self.image = self.root / "installed" / "Pharo.image"
        self.vm = self.root / "installed" / "pharo-vm" / "lib" / "pharo"
        self.failures = 0
        self.children = []

    def check(self, condition, label):
        print(f"{'PASS' if condition else 'FAIL'} {label}", flush=True)
        self.failures += not condition
        return condition

    def launch(self, name, home, role="cli", records=0, fail=False, spawn=False, overrides=None, barrier=False):
        directory = self.root / name
        directory.mkdir()
        home.mkdir(parents=True, exist_ok=True)
        env = dict(os.environ, HOME=str(home), LD_LIBRARY_PATH=str(self.vm.parent) + os.pathsep + os.environ.get("LD_LIBRARY_PATH", ""))
        for key in ("PUNT_TELEMETRY", "PUNT_OBSERVE_SMOKE_TELEMETRY", "PUNT_SMOKE_CONFIG_DISABLED",
                    "PUNT_SMOKE_READY", "PUNT_SMOKE_GO", "PUNT_SMOKE_CHILD_DONE"):
            env.pop(key, None)
        env.update(PUNT_SMOKE_REPORT=str(directory / "result.json"), PUNT_SMOKE_CORRELATION=f"smoke-{name}")
        env.update(overrides or {})
        if barrier:
            env.update(PUNT_SMOKE_READY=str(directory / "ready"), PUNT_SMOKE_GO=str(directory / "go"))
        expression = f"PuntObserveSmoke runRole: '{role}' records: {records} fail: {str(fail).lower()} spawn: {str(spawn).lower()}"
        with (directory / "stdout").open("wb") as out, (directory / "stderr").open("wb") as err:
            process = subprocess.Popen([str(self.vm), "--headless", str(self.image), "--no-default-preferences", "eval", expression],
                                       env=env, cwd=directory, stdin=subprocess.DEVNULL, stdout=out, stderr=err)
        self.children.append(process)
        return process, directory

    def finish(self, child, expected=0, drops=False, timeout=90):
        process, directory = child
        try:
            code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            raise RuntimeError(f"{directory.name}: image hung") from None
        if code != expected:
            raise RuntimeError(f"{directory.name}: exit {code}, expected {expected}; see {directory / 'stderr'}")
        report = json.loads((directory / "result.json").read_text())
        self.check(report["outcome"] == ("failed" if expected else "ok"), f"{directory.name}: exit={code}, symmetric outcome={report['outcome']}")
        self.check(report["worker_stopped"] and report["telemetry_dropped"] == 0, f"{directory.name}: bounded worker shutdown, no telemetry drops")
        if not drops:
            self.check(all(value == 0 for value in report["log_drops"].values()), f"{directory.name}: all log drop counters zero")
        return report

    def wait_ready(self, children):
        deadline = time.monotonic() + 30
        while not all((directory / "ready").exists() for _, directory in children):
            if time.monotonic() > deadline or any(process.poll() is not None for process, _ in children):
                for process, _ in children:
                    if process.poll() is None:
                        process.kill()
                        process.wait()
                raise RuntimeError("image failed or timed out before barrier")
            time.sleep(.01)

    def paths(self, home):
        labs = home / ".punt-labs"
        tool = labs / TOOL
        return labs, tool, tool / "logs"

    def inspect(self, home, backups=0, telemetry=True):
        labs, tool, logs = self.paths(home)
        active = logs / f"{TOOL}.log"
        files = [logs / f"{TOOL}.log.{index}" for index in range(backups, 0, -1)] + [active]
        lock = logs / f"{TOOL}.log.rotate.lock"
        database, salt = tool / "telemetry.db", labs / "telemetry.salt"
        dirs = (labs, tool, logs)
        self.check(all(stat.S_ISDIR(path.lstat().st_mode) and stat.S_IMODE(path.stat().st_mode) == 0o700 for path in dirs), f"{home.name}: exact directories {tool.relative_to(home)}/logs; all 0700")
        expected = set(files + [lock])
        self.check(set(logs.iterdir()) == expected, f"{home.name}: exact log/lock names, {backups} backups (maximum 5)")
        self.check(set(labs.iterdir()) == ({tool, salt} if telemetry else {tool}), f"{home.name}: exact shared salt/tool paths")
        sidecars = [Path(str(database) + suffix) for suffix in ("-journal", "-wal", "-shm") if Path(str(database) + suffix).exists()]
        self.check(set(tool.iterdir()) == ({logs, database, *sidecars} if telemetry else {logs}), f"{home.name}: exact tool files, no unexpected database/sidecar paths")
        private = files + [lock] + ([database, salt] if telemetry else []) + sidecars
        modes = subprocess.check_output(["stat", "-c", "%a", *map(str, private)], text=True).splitlines()
        self.check(all(mode == "600" for mode in modes) and all(stat.S_ISREG(path.lstat().st_mode) for path in private), f"{home.name}: stat confirms all files 0600, including lock/db/salt and {len(sidecars)} present sidecars")
        sizes = [path.stat().st_size for path in files]
        self.check(backups <= 5 and all(size <= BOUND for size in sizes), f"{home.name}: log byte bounds <= {BOUND}; sizes={sizes}")
        data = b"".join(path.read_bytes() for path in files)
        lines = []
        for path in files:
            lines.extend(log_lines(path.read_bytes()))
        self.check(True, f"{home.name}: {len(lines)} complete lines match timestamp/level/component format; no raw C0/C1/U+2028/Cf controls")
        self.check(all(secret not in data for secret in (*SECRETS, RAW_SUBJECT)), f"{home.name}: URL credentials/query/fragment, Bearer, email and raw identifier absent from logs")
        self.check(any("[WARNING] smoke-" in line for line in lines), f"{home.name}: redacted WARNING fixture exercised")
        if telemetry:
            rows = self.inspect_database(database, salt, data, home.name)
        else:
            self.check(not database.exists() and not salt.exists(), f"{home.name}: no telemetry.db or salt created")
            rows = []
        return lines, rows

    def inspect_database(self, database, salt, logs, label):
        with closing(sqlite3.connect(f"file:{database}?mode=ro", uri=True)) as db:
            integrity = db.execute("PRAGMA integrity_check").fetchone()[0]
            rows = db.execute("SELECT signal, attributes FROM signals").fetchall()
        kinds = {row[0] for row in rows}
        self.check(integrity == "ok" and {"span", "event", "counter"} <= kinds, f"{label}: SQLite integrity={integrity}; span/event/counter rows present ({len(rows)} total)")
        key = salt.read_bytes()
        expected = hmac.new(key, RAW_SUBJECT, hashlib.sha256).hexdigest()
        subjects = [json.loads(attributes)["subject"] for kind, attributes in rows if kind == "span"]
        self.check(len(key) == 32 and bool(subjects) and all(re.fullmatch(r"[0-9a-f]{64}", subject) and subject == expected for subject in subjects), f"{label}: subject is installation-salted 64-hex HMAC-SHA256, salt is 32 bytes/0600")
        blob = database.read_bytes()
        self.check(all(secret not in blob for secret in (*SECRETS, RAW_SUBJECT)), f"{label}: raw identifier and fixture secrets absent from database bytes")
        self.check(all(value not in blob and value not in logs for value in (key, key.hex().encode(), key.hex().upper().encode(), base64.b64encode(key))), f"{label}: salt bytes/hex/base64 absent from database and logs")
        with closing(sqlite3.connect(database)) as probe:
            try:
                probe.execute("BEGIN IMMEDIATE")
                probe.execute("UPDATE signals SET schema_version=schema_version+1")
                journal = Path(str(database) + "-journal")
                self.check(journal.is_file() and stat.S_IMODE(journal.stat().st_mode) == 0o600, f"{label}: rollback journal forced by open transaction; mode 0600")
            finally:
                probe.rollback()
        return rows

    def ordinary(self, name, fail=False, spawn=False):
        home = self.root / f"home-{name}"
        report = self.finish(self.launch(name, home, role=name, fail=fail, spawn=spawn), expected=1 if fail else 0)
        lines, rows = self.inspect(home)
        terminal = [line for line in lines if f"smoke-{name}: Smoke run" in line]
        expected = "failed" if fail else "ok"
        self.check(any(f"outcome={expected}" in line for line in terminal) and not any(f"outcome={'ok' if fail else 'failed'}" in line for line in terminal), f"{name}: terminal log outcome {expected}, never opposite outcome")
        self.check(all(json.loads(attributes)["outcome"] == expected for kind, attributes in rows if kind == "span"), f"{name}: telemetry outcome agrees with exit status")
        if spawn:
            directory = self.root / name
            child = json.loads((directory / "result.json.child.json").read_text())
            self.check(child["outcome"] == "ok" and child["session_id"] == child["process_id"] and child["session_id"] != report["session_id"] and child["stdio"] == ["/dev/null"] * 3, "spawn: child completed in a detached session; all three standard streams are /dev/null")
            child_lines = [line for line in lines if "[INFO] child-image: Background work" in line]
            self.check(len(child_lines) == 3 and all(f"correlation={report['correlation']} outcome={outcome}" in line for line, outcome in zip(child_lines, ("spawnIntent", "started", "completed"))), "spawn: correlated child intent/start/complete records present in order")
            self.check(all(sum(kind == expected_kind for kind, _ in rows) >= 2 for expected_kind in ("span", "event", "counter")), "spawn: both parent and child persisted each telemetry kind")

    def concurrent(self):
        home = self.root / "home-concurrent"
        children = [self.launch(f"writer-{index}", home, role=f"writer-{index}", records=300, barrier=True) for index in range(3)]
        self.wait_ready(children)
        for _, directory in children:
            (directory / "go").write_text("go")
        for child in children:
            self.finish(child)
        lines, rows = self.inspect(home, backups=5)
        self.check(all(sum(kind == expected_kind for kind, _ in rows) >= 3 for expected_kind in ("span", "event", "counter")), "concurrent: all 3 images persisted span/event/counter rows")
        tags = {index: [] for index in range(3)}
        for line in lines:
            if "[DEBUG] writer:" in line:
                match = re.fullmatch(r".*\[DEBUG\] writer: TAG-writer-([012])-(\d+) (.*)END-writer-\1-\2", line)
                if not match or match[3] != PAYLOAD:
                    raise ValueError("corrupted/interleaved writer tag or payload")
                tags[int(match[1])].append(int(match[2]))
        self.check(all(indexes and indexes == list(range(min(indexes), 301)) for indexes in tags.values()), "concurrent: all 3 writer tags intact, no retained-window gaps/duplicates/interleaving")
        self.check(3 * 300 * len(PAYLOAD) > 6 * BOUND, "concurrent: 900 ~47 KB DEBUG records exceed six files (>5 rollovers)")

    def held_lock(self):
        home = self.root / "home-held-lock"
        child = self.launch("held-lock", home, role="locked", barrier=True)
        self.wait_ready([child])
        lock = self.paths(home)[2] / f"{TOOL}.log.rotate.lock"
        holder = subprocess.Popen(["flock", "-x", "-w", "5", str(lock), "sh", "-c", "printf ready; cat >/dev/null"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        try:
            if holder.stdout.read(5) != b"ready":
                raise RuntimeError("flock holder did not start")
            started = time.monotonic()
            (child[1] / "go").write_text("go")
            report = self.finish(child, drops=True, timeout=15)
            elapsed = time.monotonic() - started
        finally:
            with suppress(BrokenPipeError):
                holder.stdin.close()
            try:
                try:
                    holder.wait(timeout=5)
                except subprocess.TimeoutExpired as error:
                    holder.kill()
                    holder.wait()
                    raise RuntimeError("flock holder did not terminate") from error
            finally:
                holder.stdout.close()
                if child[0].poll() is None:
                    child[0].kill()
                    child[0].wait()
        counts = report["log_drops"]
        self.check(2 < elapsed < 15 and counts["lockTimeout"] == 4 and sum(counts.values()) == 4, f"held-lock: CLI flock held {elapsed:.2f}s; 4 records skipped/count=4; bounded run, no hang")
        self.check((child[1] / "stderr").read_text().count("diagnostic record skipped (lockTimeout)") == 1, "held-lock: one rate-limited metadata-only timeout notice")
        self.check((self.paths(home)[2] / f"{TOOL}.log").stat().st_size == 0, "held-lock: skipped records were not written")
        self.finish(self.launch("after-lock", home, role="recovered"))
        self.inspect(home)
        self.check(True, "held-lock: later installed run writes successfully after release")

    def off_switch(self, name, overrides):
        home = self.root / f"home-{name}"
        report = self.finish(self.launch(name, home, overrides=overrides))
        self.check(not report["telemetry_enabled"], f"{name}: telemetry veto leaves no worker/queue")
        self.inspect(home, telemetry=False)
        self.finish(self.launch(name + "-seed", home))
        database = self.paths(home)[1] / "telemetry.db"
        with closing(sqlite3.connect(f"file:{database}?mode=ro", uri=True)) as db:
            seeded = db.execute("SELECT COUNT(*) FROM signals").fetchone()[0]
        self.check(seeded >= 3, f"{name}: enabled seed run populated existing database")
        before = database.read_bytes()
        report = self.finish(self.launch(name + "-again", home, overrides=overrides))
        self.check(not report["telemetry_enabled"] and database.read_bytes() == before, f"{name}: veto against existing database creates no new rows (database byte-for-byte unchanged)")

    def run(self):
        self.check(not (self.root / "bootstrap-home" / ".punt-labs").exists(), "baseline installation has no logging/telemetry filesystem side effects")
        self.ordinary("success")
        self.ordinary("fail", fail=True)
        self.ordinary("spawn", spawn=True)
        self.concurrent()
        self.held_lock()
        self.off_switch("global-off", {"PUNT_TELEMETRY": "off"})
        self.off_switch("tool-off", {"PUNT_OBSERVE_SMOKE_TELEMETRY": "off"})
        self.off_switch("config-off", {"PUNT_SMOKE_CONFIG_DISABLED": "1"})
        print(f"SMOKE {'FAILED' if self.failures else 'OK'}: {self.failures} findings", flush=True)
        return bool(self.failures)

    def close(self):
        for process in self.children:
            if process.poll() is None:
                process.kill()
                process.wait()


if __name__ == "__main__":
    runner = Smoke(Path(sys.argv[1]))
    try:
        sys.exit(runner.run())
    except (OSError, ValueError, RuntimeError, sqlite3.Error, KeyError) as error:
        print(f"FAIL smoke inspection: {error}", file=sys.stderr)
        sys.exit(1)
    finally:
        runner.close()
