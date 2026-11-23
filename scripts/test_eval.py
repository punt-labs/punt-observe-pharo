"""Eval status must never be inferred from diagnostics or marker substrings."""

from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import os
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

import eval_check


class EvalTest(unittest.TestCase):
    def setUp(self):
        directory = TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.source = Path(directory.name) / "check.st"
        self.source.write_text("{ 'diagnostics'. true }", encoding="utf-8")

    def evaluate(self, body, code=0):
        response = subprocess.CompletedProcess([], code, body, "")
        with patch.object(eval_check.subprocess, "run", return_value=response), redirect_stdout(StringIO()), redirect_stderr(StringIO()):
            return eval_check.run(self.source, "8430")

    def test_exact_success_marker_with_surrounding_whitespace(self):
        self.assertEqual(self.evaluate(" \t'PUNT-OK'\r\n"), 0)

    def test_failure_body_containing_marker_is_rejected(self):
        bodies = ("'Tests: 1 Passed: 0 Failures: 1 /scratch/PUNT-OK/case'",
                  "Error: 'PUNT-OK'", "'PUNT-OK'\nextra", "PUNT-OK", "'PUNT-FAILED'")
        for body in bodies:
            with self.subTest(body=body):
                self.assertEqual(self.evaluate(body), 1)

    def test_empty_response_is_rejected(self):
        self.assertEqual(self.evaluate(""), 1)

    def test_transport_failure_cannot_be_success(self):
        self.assertEqual(self.evaluate("'PUNT-OK'", code=22), 1)

    def test_shell_rejects_marker_in_failure_body(self):
        curl = self.source.parent / "curl"
        curl.write_text("#!/bin/sh\nprintf '%s\\n' 'failure /scratch/PUNT-OK/case'\n", encoding="utf-8")
        curl.chmod(0o700)
        environment = os.environ | {"PATH": str(curl.parent) + os.pathsep + os.environ["PATH"]}
        script = Path(__file__).with_name("eval")
        result = subprocess.run(["sh", str(script), str(self.source)], env=environment,
                                text=True, capture_output=True, check=False)
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("failure /scratch/PUNT-OK/case", result.stdout)

    def test_smalltalk_literal_escapes_quotes(self):
        self.assertEqual(eval_check.literal("a'b"), "'a''b'")


if __name__ == "__main__":
    unittest.main()
