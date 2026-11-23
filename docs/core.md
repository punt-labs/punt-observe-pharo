# Core API

`PuntLibC>>exists:` distinguishes absent paths without a second errno FFI call,
validates the parent, and preserves failures for existing files and symlinks.
Directory creation always validates a non-creating directory open. Do not branch
on `errno` read through a later FFI call: the VM can clobber it between calls.

## Paths and Lifetime

`PuntHome forTool:` accepts ASCII `[a-z][a-z0-9-]{0,63}`. `ensureDirectories`
creates or secures `.punt-labs`, the tool directory and its logs directory.
Accessors return FileReferences: `labsDirectory`, `toolDirectory`,
`logsDirectory`, `logFile`, `lockFile`, `databaseFile`, `saltFile`.
The root must already exist. There is no fallback on failure.

`PuntPrivateFile open:` takes a FileReference beneath secured directories.
`append:` takes a ByteArray, not a String; encode once with `utf8Encoded`.
`inode`, `size`, `metadata`, `descriptor` expose descriptor information for
rotation under a caller-owned lock. Always `close` in an ensure: block.
`open:using:` accepts a PuntLibC-compatible adapter for deterministic tests.

`PuntHome duringHome:do:` is a test-only process-scoped root override.
`libc:` injects a deterministic permission-failure adapter on a home instance.

## ABI

PuntLibC supports Linux x86_64 and macOS 64-bit stat layouts. `stat:` is
deliberately lstat, so symlinks can be identified without following them.
PuntFileStat answers `inode`, `uid`, `mode`, `permissions`, `size`, `isRegular`,
`isDirectory`, `isSymbolicLink`. The current uid comes from `getuid`.
Other bindings: `open:flags:mode:`, `mkdir:mode:`, `close:`,
`write:bytes:count:`, `fstat:`, `rename:to:`, `unlink:`, `fchmod:mode:`,
`link:to:`, `errno`. All native return values are POSIX values; high-level
private operations translate failures to PuntPermissionError.

`tryLock:` always uses LOCK_EX|LOCK_NB. `unlock:` releases it. Raw blocking
operations are private implementation details, not the supported API.
Never execute subprocesses that curl the same image while inside a blocking
libc call.

## Escaping

`PuntEscaper escape:` accepts a String, including empty strings. It preserves
ordinary Unicode and escapes C0, DEL, C1, line/paragraph separators and Unicode
Cf characters as lowercase hex: `\xNN`, `\uNNNN`, or `\UNNNNNNNN` for
supplementary format characters. It does not append a newline or redact secrets;
those are later logging-layer responsibilities.
