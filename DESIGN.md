# Design Decisions

## DES-001: Private Descriptor Boundary

**Date:** 2026-11-23

PuntLibC owns the POSIX ABI. PuntFileStat copies metadata out of a temporary
native buffer; no native pointer escapes. PuntPrivateFile owns one descriptor
and requires explicit close. It writes each byte array in one append call and
signals on a short write, rather than retrying and interleaving records.

Directory opens use O_DIRECTORY and O_NOFOLLOW; file opens use O_NOFOLLOW and
O_NONBLOCK to reject FIFOs without blocking the image. Ownership and type are
checked before descriptor-based fchmod, then mode is verified. Existing modes
are tightened to 0700/0600, including removal of special mode bits. Paths must
be under directories prepared by PuntHome; arbitrary insecure parent trees
are not made safe by opening their final component alone.

## DES-002: Process-Scoped Test Home

**Date:** 2026-11-23

PuntHomeRoot is a DynamicVariable. PuntHome duringHome:do: scopes a test root
without mutating HOME, FileLocator or a process-global class variable. The
default remains FileLocator home. PuntHome instances snapshot the resolved root;
future session startup handlers must create fresh authorities.

## DES-003: Bootstrap and Future Packages

**Date:** 2026-11-23

The bootstrap clones full upstream histories at exact commits and loads locally,
avoiding github archive transport and shallow-history Iceberg failures. The
SQLite group is Core and OTel groups are traces/metrics, not instrumentation.
Postern is a development dependency, not a runtime Core dependency.
Pharo itself follows the official Pharo 12 stable distribution channel.
Telemetry and Smoke packages remain empty; Logging is the next implemented
layer over the private descriptor foundation.

## DES-004: Durable Logging Boundary

**Date:** 2026-11-23

One PuntLog subscribes only to PuntLogSignal. Explicit field renderers prevent
arbitrary object printing; errors retain class names only. The formatter renders
the whole record before the fixed-point redactor admits UTF-8 bytes to the sink.
No failure path falls back to raw output or emits another signal.

The sink keeps no native descriptor between appends. A Mutex and stable flock
protect size checks, rotation and one O_APPEND write; acquisition has one shared
two-second budget. Session handlers replace the sink and resolve home anew.
First start wins until stop; level changes have an explicit class-side selector.
Close drains the current critical section before returning so a snapshot cannot
inherit an in-flight append descriptor. The notice switch is image-wide and
applies before setup as well as after session startup.

The Pharo regex dialect lacks Go's non-capturing groups and colon syntax.
Equivalent capturing groups preserve the outer prefix used for replacements.
Five explicit optional prefix groups replace a bounded compound repetition:
Pharo's matcher shallow-copies quantified links containing loops, which can
cycle during matcher construction. Necessary-substring prefilters avoid
backtracking across large benign records; opaque-token masking is a linear scan.
Regex control characters use symbolic placeholders expanded at runtime so Tonel
line-ending normalization cannot change CR/LF matching. The logger restores
escaped credential whitespace before the unchanged Go masking passes, then
escapes the final record again; formatting fields cannot hide a bearer token
behind an escaped newline. Invalid Unicode scalar values are withheld.
An RxMatcher specialization supplies Go's ASCII word boundaries, including
underscore, rather than Pharo's Unicode-alphanumeric boundary definition.

The multi-image gate reads the current VM and image paths. Build that image
from persisted Tonel before the gate; do not save an active HTTP request's
socket/process state as the child-image fixture. Child standard streams are
discarded and a Python verifier inspects the durable files, not process output.
