# Installed-path smoke

Run `make smoke` with `python3` on macOS or on Linux x86_64 (`/proc` must be
available on Linux). No running dev image is needed. Every invocation downloads
a fresh Pharo 12 image and VM, installs the baseline from this checkout using the
pinned upstream dependencies, and retains artifacts under `.tmp/smoke-*`.

The installed entry point exits its image:

```smalltalk
PuntObserveSmoke runRole: 'cli' records: 0 fail: false spawn: false
```

Use it only in a command-line image, not the dev REPL. `records:` emits DEBUG
records of approximately 47 KB. `fail: true` logs and persists only a failed
terminal outcome and exits nonzero. `spawn: true` starts a detached image with
discarded standard streams and waits for its correlated completion marker.

The Python inspector checks private paths, modes and ownership, rotation and
retained-window continuity, line framing/control escaping, fixed fixture
redaction, SQLite integrity, all three telemetry kinds and independently
calculated identifier HMACs. It forces a rollback journal to check its mode. The
held-lock case uses a startup barrier, holds the rotate lock through four
two-second write attempts,
checks four counted drops and one notice, then verifies a later run recovers.
Each telemetry veto first runs in its own empty HOME, then runs against an
enabled seed database to prove no new rows or file changes.

The report prints every check and exits nonzero for findings, malformed output,
unexpected process exits or timeouts. Setup output is in `setup.log`; individual
case directories contain stdout/stderr and JSON results. Fixture secrets are
synthetic and intentionally embedded in the installed image, but must never
appear in application logs or telemetry. Inspector rejection tests run with:

```sh
python3 -m unittest discover -s scripts -p test_smoke.py
```
