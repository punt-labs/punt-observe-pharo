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

    def test_missing_process_record_is_removed_by_stop(self):
        self.pidfile.write_text(json.dumps(self.record))
        with patch.object(runtime.os, "pidfd_open", side_effect=ProcessLookupError), patch.object(runtime.signal, "pidfd_send_signal") as send:
            runtime.manage("stop", self.pidfile, self.image, 8430)
        send.assert_not_called()
        self.assertFalse(self.pidfile.exists())

    def test_exit_during_identity_check_removes_record_and_closes_pidfd(self):
        self.pidfile.write_text(json.dumps(self.record))
        with patch.object(runtime.os, "pidfd_open", return_value=67), patch.object(runtime, "identity", side_effect=FileNotFoundError), patch.object(runtime.signal, "pidfd_send_signal", side_effect=ProcessLookupError) as send, patch.object(runtime.os, "close") as close:
            runtime.manage("stop", self.pidfile, self.image, 8430)
        send.assert_called_once_with(67, 0)
        close.assert_called_once_with(67)
        self.assertFalse(self.pidfile.exists())

    def test_missing_identity_without_proof_of_exit_preserves_record(self):
        contents = json.dumps(self.record)
        self.pidfile.write_text(contents)
        with patch.object(runtime.os, "pidfd_open", return_value=67), patch.object(runtime, "identity", side_effect=FileNotFoundError), patch.object(runtime.signal, "pidfd_send_signal") as send, patch.object(runtime.os, "close") as close:
            with self.assertRaises(FileNotFoundError):
                runtime.manage("stop", self.pidfile, self.image, 8430)
        send.assert_called_once_with(67, 0)
        close.assert_called_once_with(67)
        self.assertEqual(self.pidfile.read_text(), contents)

    def test_exit_before_sigterm_removes_record_and_closes_pidfd(self):
        self.pidfile.write_text(json.dumps(self.record))
        with patch.object(runtime, "verified_fd", return_value=67), patch.object(runtime.signal, "pidfd_send_signal", side_effect=ProcessLookupError) as send, patch.object(runtime.os, "close") as close:
            runtime.manage("stop", self.pidfile, self.image, 8430)
        send.assert_called_once_with(67, signal.SIGTERM)
        close.assert_called_once_with(67)
        self.assertFalse(self.pidfile.exists())

    def test_invalid_or_legacy_record_never_signals(self):
        for contents in ("12345", "not-json", "{}", '{"pid": -1}'):
            self.pidfile.write_text(contents)
            with self.subTest(contents=contents), patch.object(runtime.signal, "pidfd_send_signal") as send:
                with self.assertRaises((ValueError, KeyError, TypeError)):
                    runtime.manage("stop", self.pidfile, self.image, 8430)
                send.assert_not_called()

    def test_live_identity_mismatch_preserves_record_without_signalling(self):
        contents = json.dumps(self.record)
        for field, value in (("start", "101"), ("boot", "new-boot")):
            self.pidfile.write_text(contents)
            actual = {key: self.record[key] for key in ("pid", "start", "boot")} | {field: value}
            with self.subTest(field=field), patch.object(runtime.os, "pidfd_open", return_value=67), patch.object(runtime, "identity", return_value=actual), patch.object(runtime.os, "close") as close, patch.object(runtime.signal, "pidfd_send_signal") as send:
                with self.assertRaises(ValueError):
                    runtime.manage("stop", self.pidfile, self.image, 8430)
                close.assert_called_once_with(67)
                send.assert_not_called()
                self.assertEqual(self.pidfile.read_text(), contents)

    def test_unreaped_exit_with_empty_command_removes_record(self):
        self.pidfile.write_text(json.dumps(self.record))
        actual = {key: self.record[key] for key in ("pid", "start", "boot")}
        with patch.object(runtime.os, "pidfd_open", return_value=67), patch.object(runtime, "identity", return_value=actual), patch.object(runtime, "matches_command", return_value=False), patch.object(runtime, "exited", return_value=True), patch.object(runtime.os, "close") as close, patch.object(runtime.signal, "pidfd_send_signal") as send:
            runtime.manage("stop", self.pidfile, self.image, 8430)
        close.assert_called_once_with(67)
        send.assert_not_called()
        self.assertFalse(self.pidfile.exists())

    def test_zombie_leader_with_live_threads_is_not_exited(self):
        proc = Path(self.directory.name) / "proc"
        (proc / "task" / "1").mkdir(parents=True)
        (proc / "task" / "2").mkdir()
        (proc / "stat").write_text("1 (pharo) Z 1 1 1")
        real = runtime.Path
        with patch.object(runtime, "Path", side_effect=lambda path: proc if path == "/proc/1" else real(path)):
            self.assertFalse(runtime.exited(1))
            (proc / "task" / "2").rmdir()
            self.assertTrue(runtime.exited(1))

    def test_live_command_mismatch_preserves_record(self):
        contents = json.dumps(self.record)
        self.pidfile.write_text(contents)
        actual = {key: self.record[key] for key in ("pid", "start", "boot")}
        with patch.object(runtime.os, "pidfd_open", return_value=67), patch.object(runtime, "identity", return_value=actual), patch.object(runtime, "matches_command", return_value=False), patch.object(runtime, "exited", return_value=False), patch.object(runtime.os, "close"), patch.object(runtime.signal, "pidfd_send_signal") as send:
            with self.assertRaises(ValueError):
                runtime.manage("stop", self.pidfile, self.image, 8430)
        send.assert_not_called()
        self.assertEqual(self.pidfile.read_text(), contents)

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
                self.assertEqual(json.loads(self.pidfile.read_text()), stale)
        finally:
            child.terminate()
            child.wait()


if __name__ == "__main__":
    unittest.main()
