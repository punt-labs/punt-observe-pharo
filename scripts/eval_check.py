"""Keep check diagnostics separate from the exact Postern success response."""

import os
from pathlib import Path
import subprocess
import sys
from tempfile import TemporaryDirectory


SUCCESS_RESPONSE = "'PUNT-OK'"


def literal(value):
    return "'" + str(value).replace("'", "''") + "'"


def run(source_path, port):
    source = Path(source_path).read_text(encoding="utf-8")
    scratch = Path(__file__).resolve().parent.parent / ".tmp"
    scratch.mkdir(mode=0o700, exist_ok=True)
    with TemporaryDirectory(prefix="eval-", dir=scratch) as directory:
        report = Path(directory) / "report"
        report.touch(mode=0o600)
        program = f"""| result |
result := Smalltalk compiler evaluate: {literal(source)}.
{literal(report)} asFileReference writeStreamDo: [ :stream | stream nextPutAll: result first ].
result second ifTrue: [ 'PUNT-OK' ] ifFalse: [ 'PUNT-FAILED' ]
"""
        response = subprocess.run(
            ["curl", "--fail", "--silent", "--show-error", "--max-time", "300",
             "-X", "POST", f"http://localhost:{port}/repl",
             "-H", "Content-Type: text/plain", "--data-binary", "@-"],
            input=program, text=True, capture_output=True, check=False)
        diagnostics = report.read_text(encoding="utf-8")
        if diagnostics:
            print(diagnostics.rstrip("\n"))
        print(response.stdout.rstrip("\n"))
        print(response.stderr, file=sys.stderr, end="")
        return 0 if response.returncode == 0 and response.stdout.strip() == SUCCESS_RESPONSE else 1


if __name__ == "__main__":
    sys.exit(run(sys.argv[1], os.environ.get("PORT", "8430")))
