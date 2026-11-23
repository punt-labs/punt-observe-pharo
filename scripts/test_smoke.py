"""Inspector rejection coverage without a VM or network."""

import unittest

from smoke import log_lines


class SmokeInspectorTest(unittest.TestCase):
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
