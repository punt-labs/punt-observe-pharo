"""Process-incarnation safety without starting another Pharo image."""

import json
from http.server import BaseHTTPRequestHandler, HTTPServer
import os
from pathlib import Path
import signal
import subprocess
from threading import Thread
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

    def test_eval_sends_token_without_putting_it_in_curl_arguments(self):
        token = "private-test-token"

        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                self.rfile.read(int(self.headers["Content-Length"]))
                self.send_response(200 if self.headers.get("X-Eval-Token") == token else 401)
                self.end_headers()
                self.wfile.write(b"PUNT-OK")

            def log_message(self, *args):
                pass

        server = HTTPServer(("127.0.0.1", 0), Handler)
        self.addCleanup(server.server_close)
        thread = Thread(target=server.serve_forever)
        thread.start()
        try:
            source = Path(self.directory.name) / "eval.st"
            source.write_text("'PUNT-OK'")
            tokenfile = Path(self.directory.name) / "token"
            tokenfile.write_text(token)
            environment = os.environ | {"PORT": str(server.server_port), "EVAL_TOKEN_FILE": str(tokenfile)}
            script = Path(__file__).resolve().parent / "eval"
            result = subprocess.run(["sh", str(script), str(source)], env=environment, capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 0, result.stderr)
            tokenfile.write_text("wrong-token")
            result = subprocess.run(["sh", str(script), str(source)], env=environment, capture_output=True, timeout=5)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("--config -", script.read_text())
        finally:
            server.shutdown()
            thread.join()

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
