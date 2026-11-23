"""Inspector rejection coverage without a VM or network."""

import unittest
import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
from tempfile import TemporaryDirectory
from unittest.mock import Mock, patch

from smoke import Smoke, log_lines, private_path


class SmokeInspectorTest(unittest.TestCase):
    def test_finish_rejects_opentelemetry_warning_on_stdout(self):
        report = {"outcome": "ok", "worker_stopped": True, "telemetry_dropped": 0, "log_drops": {"ioFailure": 0}}
        for stdout, findings in ((b"", 0), (b"ordinary output\n", 0), (b"OpenTelemetry warning: shutdown failed\n", 1)):
            with self.subTest(stdout=stdout), TemporaryDirectory() as directory:
                path = Path(directory)
                (path / "stdout").write_bytes(stdout)
                (path / "result.json").write_text(json.dumps(report))
                runner = Smoke(path)
                process = Mock()
                process.wait.return_value = 0
                with patch("builtins.print"):
                    self.assertEqual(runner.finish((process, path)), report)
                self.assertEqual(runner.failures, findings)

    def test_private_path_requires_exact_mode_type_and_owner(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / "file"
            path.touch()
            path.chmod(0o600)
            link = Path(directory) / "link"
            link.symlink_to(path)
            self.assertTrue(private_path(path, 0o600, stat.S_ISREG))
            self.assertFalse(private_path(path, 0o700, stat.S_ISREG))
            self.assertFalse(private_path(link, 0o600, stat.S_ISREG))
            with patch("smoke.os.getuid", return_value=os.getuid() + 1):
                self.assertFalse(private_path(path, 0o600, stat.S_ISREG))

    def test_partial_image_launch_reaps_earlier_child(self):
        for filename in ("logging-images.py", "telemetry-images.py"):
            spec = importlib.util.spec_from_file_location("image_gate", Path(__file__).with_name(filename))
            gate = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(gate)
            process = Mock()
            process.poll.return_value = None
            with self.subTest(filename=filename), TemporaryDirectory() as directory:
                with patch.object(sys, "argv", [filename, "/fake/vm", "/fake/image", directory]), patch.object(gate.subprocess, "Popen", side_effect=[process, OSError("synthetic launch failure")]):
                    with self.assertRaisesRegex(OSError, "synthetic launch failure"):
                        gate.main()
                process.kill.assert_called_once()
                process.wait.assert_called_once()

    def test_process_cleanup_is_idempotent_and_reaps_running_children(self):
        runner = Smoke(Path(__file__).parent)
        running = Mock()
        running.poll.side_effect = [None, 0]
        finished = Mock()
        finished.poll.return_value = 0
        runner.children = [running, finished]
        runner.close()
        runner.close()
        running.kill.assert_called_once()
        running.wait.assert_called_once()
        finished.kill.assert_not_called()

    def test_image_gates_refuse_optimized_python(self):
        for script in ("logging-images.py", "telemetry-images.py"):
            with self.subTest(script=script):
                result = subprocess.run([sys.executable, "-O", str(Path(__file__).with_name(script))], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Image gates require enabled assertions", result.stderr)

    def test_normal_line(self):
        line = b"2026-11-24 12:00:00 [INFO] smoke-cli: Smoke run outcome=ok\n"
        self.assertEqual(log_lines(line), [line[:-1].decode()])

    def test_empty_and_partial_logs_rejected(self):
        for data in (b"", b"partial", b"\n", b"2026-11-24 12:00:00 [INFO] smoke-cli: " + b"p" * 65536 + b"\n"):
            with self.subTest(data=data), self.assertRaises(ValueError):
                log_lines(data)
        self.assertEqual(log_lines(b"", allow_empty=True), [])

    def test_forged_lines_and_raw_controls_rejected(self):
        for content in ("forged\nline", "\x1b[31m", "\x00", "\r", "\x85", "\u2028", "\u202e"):
            with self.subTest(content=content), self.assertRaises(ValueError):
                log_lines(f"2026-11-24 12:00:00 [WARNING] smoke-cli: {content}\n".encode())


if __name__ == "__main__":
    unittest.main()
