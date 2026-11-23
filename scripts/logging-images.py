"""PHARO-LOG-4/6 acceptance harness; uses only Python's standard library."""

import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import time


def smalltalk_string(value):
    return "'" + str(value).replace("'", "''") + "'"


def main():
    vm, image, directory = sys.argv[1:]
    root = Path(directory)
    home = root / "image-home"
    home.mkdir()
    processes = []
    payload = " ".join(["p" * 93] * 500)
    for worker in range(2):
        script = root / f"writer-{worker}.st"
        outcome = (
            f"PuntLog childCompleted: 'child-{worker}'."
            if worker == 0
            else f"[ Error signal: 'CHILD-PRIVATE-ERROR' ] on: Error do: [ :error | PuntLog childFailed: error correlation: 'child-{worker}' ]."
        )
        script.write_text(
            f"""| logger payload ready go |
logger := PuntLog startTool: 'multi-image' role: 'test'.
PuntLog noticesEnabled: false.
ready := {smalltalk_string(root / f'ready-{worker}')} asFileReference.
ready writeStreamDo: [ :stream | stream nextPutAll: 'ready' ].
go := {smalltalk_string(root / 'go')} asFileReference.
[ go exists ] whileFalse: [ (Delay forMilliseconds: 10) wait ].
PuntLog spawnIntent: 'child-{worker}'.
PuntLog childStarted: 'child-{worker}'.
payload := {smalltalk_string(payload)}.
1 to: 420 do: [ :index |
  (PuntLogSignal new component: 'writer'; message: ('TAG-{worker}-' , index asString , ' ' , payload , ' END-{worker}-' , index asString)) emit ].
{outcome}
PuntLog stop.
Smalltalk exit: 0.
"""
        )
        env = os.environ.copy()
        env["HOME"] = str(home)
        if sys.platform.startswith("linux"):
            env["LD_LIBRARY_PATH"] = str(Path(vm).parent) + os.pathsep + env.get("LD_LIBRARY_PATH", "")
        processes.append(
            subprocess.Popen(
                [vm, "--headless", image, "st", str(script)],
                env=env,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        )
    try:
        deadline = time.monotonic() + 45
        while not all((root / f"ready-{worker}").exists() for worker in range(2)):
            assert all(process.poll() is None for process in processes), "child exited before barrier"
            assert time.monotonic() < deadline, "child startup deadline"
            time.sleep(0.05)
        (root / "go").touch()
        for process in processes:
            assert process.wait(timeout=180) == 0, "child failed"
    finally:
        for process in processes:
            if process.poll() is None:
                process.kill()
                process.wait()

    labs = home / ".punt-labs"
    tool = labs / "multi-image"
    logs = tool / "logs"
    for path in (labs, tool, logs):
        assert stat.S_IMODE(path.stat().st_mode) == 0o700, path
    active = logs / "multi-image.log"
    files = [logs / f"multi-image.log.{index}" for index in range(5, 0, -1)] + [active]
    assert set(logs.iterdir()) == set(files + [logs / "multi-image.log.rotate.lock"])
    sequences = {0: [], 1: []}
    records = 0
    outcomes = []
    for path in files:
        data = path.read_bytes()
        assert len(data) <= 5242880, path
        assert stat.S_IMODE(path.stat().st_mode) == 0o600, path
        assert data.endswith(b"\n"), "partial last record"
        for line in data.decode("utf-8").splitlines():
            match = re.fullmatch(
                r"\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \[INFO\] writer: TAG-([01])-(\d+) (.*) END-\1-\2",
                line,
            )
            if not match:
                assert "[INFO] child-image: Background work" in line, line[:200]
                assert "CHILD-PRIVATE-ERROR" not in line
                outcomes.append(line)
                continue
            worker, index, body = match.groups()
            assert body == payload, "interleaved or corrupted payload"
            sequences[int(worker)].append(int(index))
            records += 1
    for worker, indexes in sequences.items():
        assert indexes, f"missing worker {worker}"
        assert indexes == list(range(min(indexes), 421)), (
            f"worker {worker}: loss/duplicates in retained window; "
            f"range={min(indexes)}..{max(indexes)}, count={len(indexes)}, "
            f"missing={sorted(set(range(min(indexes), 421)) - set(indexes))[:20]}, "
            f"duplicate_count={len(indexes) - len(set(indexes))}"
        )
    assert records > 550, "insufficient retained data"
    assert any("correlation=child-0 outcome=completed" in line for line in outcomes)
    assert any("correlation=child-1 outcome=failed errorClass=Error" in line for line in outcomes)
    assert stat.S_IMODE((logs / "multi-image.log.rotate.lock").stat().st_mode) == 0o600
    print(f"PUNT-IMAGES-OK: 2 independent images, 840 records, >5 rollovers, {records} retained intact")


if __name__ == "__main__":
    main()
