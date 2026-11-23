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
Logging and Telemetry build on the private descriptor foundation. Smoke remains
a later-stage scaffold.

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
socket/process state as the child-image fixture. Child stdout is discarded;
stderr is kept only in the test sandbox for startup-failure diagnostics. A
Python verifier inspects the durable files, not process output.

## DES-005: Privacy Before Telemetry Admission

**Date:** 2026-11-23

Only registered schema classes enter the facade. Declared slots, closed enum
members, required fields, kinds, units and integer bounds are checked before
admission. The queued record contains a copied primitive attribute dictionary,
not the caller's observation. Identifiers are HMAC-SHA256 hex, derived with the
image's SHA256 HMAC implementation. Salt is read afresh, never cached in class
or instance state. A private exclusive temporary file containing 32 bytes from
/dev/urandom is atomically linked into place; losing creators read the winner.

One userBackground worker owns private providers, an in-memory delta metric
reader and either SQLite or explicitly consented OTLP HTTP exporters. The simple
span processor runs inline on that worker, without an extra exporter timeout
process. HTTP is bounded to 500 ms with one attempt; SQLite busy timeout is
200 ms. The 1024-record queue drops on saturation or admission lock contention.
Shutdown drains within a 1.9-second budget, then discards and terminates a stalled
worker. Delivery is deliberately best effort, not a durable queue.

SQLite is pre-created at 0600, uses DELETE journals and transactions, validates
sidecars, and prunes with incremental vacuum at startup and on the worker timer.
Its private connection subclass unregisters the native handle from automatic
finalization before deterministic close and clears the pointer afterward. The
pinned SQLite dependency's forceClose alone leaves that registration intact.
Export failures produce only a fixed, rate-limited PuntLogSignal; they never
recursively enter telemetry or report rejected values or exceptions. Environment
vetoes are reread after restoration, and disabled startup creates no paths or
worker. OTEL environment variables never select the exporter.
