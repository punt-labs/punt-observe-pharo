"""Process-incarnation safety without starting another Pharo image."""

import json
import os
from pathlib import Path
import signal
import subprocess
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

import runtime_process as runtime


class RuntimeProcessTest(unittest.TestCase):
    def setUp(self):
        self.directory = TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.pidfile = Path(self.directory.name) / "runtime.pid"
        self.image = Path(self.directory.name) / "Pharo.image"
        self.record = {"pid": 12345, "start": "100", "boot": "boot",
                       "image": str(self.image.resolve()), "port": 8430}

    def test_verified_stop_signals_pinned_descriptor_and_cleans_record(self):
        self.pidfile.write_text(json.dumps(self.record))
        with patch.object(runtime, "verified_fd", return_value=67), patch.object(runtime.signal, "pidfd_send_signal") as send, patch.object(runtime.os, "close") as close:
            runtime.manage("stop", self.pidfile, self.image, 8430)
        send.assert_called_once_with(67, signal.SIGTERM)
        close.assert_called_once_with(67)
        self.assertFalse(self.pidfile.exists())

    def test_empty_stop_is_idempotent(self):
        runtime.manage("stop", self.pidfile, self.image, 8430)
        runtime.manage("stop", self.pidfile, self.image, 8430)

    def test_invalid_or_legacy_record_never_signals(self):
        for contents in ("12345", "not-json", "{}", '{"pid": -1}'):
            self.pidfile.write_text(contents)
            with self.subTest(contents=contents), patch.object(runtime.signal, "pidfd_send_signal") as send:
                with self.assertRaises((ValueError, KeyError, TypeError)):
                    runtime.manage("stop", self.pidfile, self.image, 8430)
                send.assert_not_called()

    def test_identity_mismatch_closes_pidfd_without_signalling(self):
        for field, value in (("start", "101"), ("boot", "new-boot")):
            actual = {key: self.record[key] for key in ("pid", "start", "boot")} | {field: value}
            with self.subTest(field=field), patch.object(runtime.os, "pidfd_open", return_value=67), patch.object(runtime, "identity", return_value=actual), patch.object(runtime.os, "close") as close, patch.object(runtime.signal, "pidfd_send_signal") as send:
                with self.assertRaises(ValueError):
                    runtime.verified_fd(self.record, self.image, 8430)
                close.assert_called_once_with(67)
                send.assert_not_called()

    @unittest.skipUnless(hasattr(os, "pidfd_open"), "Linux pidfd required")
    def test_reused_or_unrelated_live_pid_is_not_killed(self):
        child = subprocess.Popen(["sleep", "30"])
        try:
            record = runtime.identity(child.pid) | {"image": str(self.image.resolve()), "port": 8430}
            for stale in (record | {"start": "0"}, record):
                self.pidfile.write_text(json.dumps(stale))
                with self.subTest(stale=stale), self.assertRaises(ValueError):
                    runtime.manage("stop", self.pidfile, self.image, 8430)
                self.assertIsNone(child.poll())
        finally:
            child.terminate()
            child.wait()


if __name__ == "__main__":
    unittest.main()
