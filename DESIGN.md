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
Logging, Telemetry and Smoke packages have no classes yet; empty packages keep
the final baseline group graph loadable without inventing implementations.
