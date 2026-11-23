"""Manage only the recorded Linux process incarnation, using a pinned pidfd."""

import argparse
import json
import os
from pathlib import Path
import signal
import sys


def identity(pid):
    fields = Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
    return {"pid": pid, "start": fields[19],
            "boot": Path("/proc/sys/kernel/random/boot_id").read_text().strip()}


def exited(pid):
    return Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()[0] in ("Z", "X")


def matches_command(pid, image, port):
    directory = Path(f"/proc/{pid}")
    arguments = directory.joinpath("cmdline").read_bytes().decode().split("\0")
    cwd = directory.joinpath("cwd").resolve()
    prefix = "PosternServer startOn: "
    return (directory.joinpath("exe").resolve().name == "pharo"
            and any((cwd / argument).resolve() == image.resolve()
                    for argument in arguments if argument.endswith(".image"))
            and any(argument.startswith(prefix) and argument[len(prefix):].isdigit()
                    and int(argument[len(prefix):]) == port for argument in arguments))


def verified_fd(record, image, port, require_command=True):
    pid = record["pid"]
    if type(pid) is not int or pid <= 0:
        raise ValueError("Invalid PID")
    descriptor = os.pidfd_open(pid)
    try:
        try:
            if (identity(pid) != {key: record[key] for key in ("pid", "start", "boot")}
                    or record["image"] != str(image.resolve()) or record["port"] != port):
                raise ValueError("Process identity mismatch")
            if require_command and not matches_command(pid, image, port):
                if exited(pid):
                    raise ProcessLookupError("Process exited")
                raise ValueError("Process identity mismatch")
        except FileNotFoundError:
            signal.pidfd_send_signal(descriptor, 0)
            raise
        signal.pidfd_send_signal(descriptor, 0)
        return descriptor
    except BaseException:
        os.close(descriptor)
        raise


def record_child(pidfile, pid, image, port):
    descriptor = os.pidfd_open(pid)
    try:
        fields = Path(f"/proc/{pid}/stat").read_text().rsplit(")", 1)[1].split()
        if int(fields[1]) != os.getppid():
            raise ValueError("Not a child of the launching shell")
        record = identity(pid) | {"image": str(image.resolve()), "port": port}
        signal.pidfd_send_signal(descriptor, 0)
        pidfile.write_text(json.dumps(record) + "\n")
        pidfile.chmod(0o600)
    finally:
        os.close(descriptor)


def manage(operation, pidfile, image, port, pid=None):
    if operation == "supported":
        if not hasattr(os, "pidfd_open") or not hasattr(signal, "pidfd_send_signal"):
            raise ValueError("Linux pidfd support required")
        descriptor = os.pidfd_open(os.getpid())
        try:
            signal.pidfd_send_signal(descriptor, 0)
        finally:
            os.close(descriptor)
        return
    if operation == "record":
        record_child(pidfile, pid, image, port)
        return
    if not pidfile.exists() and operation in ("stop", "abort"):
        return
    record = json.loads(pidfile.read_text())
    descriptor = None
    try:
        try:
            descriptor = verified_fd(record, image, port, require_command=operation != "abort")
            if operation != "check":
                signal.pidfd_send_signal(descriptor, signal.SIGTERM)
        except ProcessLookupError:
            if operation != "stop":
                raise
        if operation != "check":
            pidfile.unlink()
    finally:
        if descriptor is not None:
            os.close(descriptor)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=("supported", "record", "check", "stop", "abort"))
    parser.add_argument("pidfile", type=Path)
    parser.add_argument("--pid", type=int)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--port", type=int, required=True)
    arguments = parser.parse_args()
    try:
        manage(**vars(arguments))
    except (OSError, ValueError, KeyError, TypeError, AttributeError):
        print("Refusing to manage process: identity could not be verified", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
