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

## DES-003: Bootstrap and Installed Packages

**Date:** 2026-11-23

The bootstrap clones full upstream histories at exact commits and loads locally,
avoiding github archive transport and shallow-history Iceberg failures. The
SQLite group is Core and OTel groups are traces/metrics, not instrumentation.
Postern is a development dependency, not a runtime Core dependency.
Pharo itself follows the official Pharo 12 stable distribution channel.
Logging and Telemetry build on the private descriptor foundation. Smoke is an
installed CLI package. `make smoke` downloads a new VM/image, installs the
checkout's baseline and inspects isolated runs without using the dev image.

## DES-004: Durable Logging Boundary

**Date:** 2026-11-23

One PuntLog subscribes only to PuntLogSignal. Explicit field renderers prevent
arbitrary object printing; errors retain class names only. The formatter renders
the whole record before the fixed-point redactor admits UTF-8 bytes to the sink.
No failure path falls back to raw output or emits another signal.

Only primitive numeric classes are printed as scalar field values; an arbitrary
Number subclass is still an object placeholder. Error payloads retain class
names, not messageText or stacks. An oversized pre-existing active file or
backup fails setup without deleting the file; recovery is an explicit owner
decision. Rotation is not a power-loss transaction and appends do not fsync.
The acquisition budget is not a deadline for uninterruptible filesystem calls
or blocked stderr. MCP owners must disable notices; CLI stderr must be consumed.

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

Discarded queued records increment `dropped`; forced interruption also emits a
fixed rate-limited diagnostic, since delivery of an in-flight export is unknown.
`dropped` counts admission failures and unprocessed queue discards, not confirmed
remote delivery failures. Export failures use diagnostics even when the SDK
returns false instead of raising. These diagnostics require a running PuntLog;
there is deliberately no raw stderr fallback when logging is absent.

Configuration owns its endpoint string and tool paths own their tool name.
Partial store/provider initialization and transactions use unwind cleanup, not
only Error handlers: process termination rolls back transactions and closes
connections acquired before initialization returned to the worker.

SQLite is pre-created at 0600, uses DELETE journals and transactions, validates
sidecars, and prunes with incremental vacuum at startup and on the worker timer.
Its private connection subclass unregisters the native handle from automatic
finalization before deterministic close and clears the pointer afterward. The
pinned SQLite dependency's forceClose alone leaves that registration intact.
Export failures produce only a fixed, rate-limited PuntLogSignal; they never
recursively enter telemetry or report rejected values or exceptions. Environment
vetoes are reread after restoration, and disabled startup creates no paths or
worker. OTEL environment variables never select the exporter.

## DES-006: Count Drops Without Depending on Transient Errno

**Date:** 2026-11-24

The Stage 2 image gate reproduced retained-window loss before telemetry was
loaded. Instrumentation correlated missing indices with failed private-file
opens, not lock timeouts, short writes or redactor withholding. On the VM's
same-thread FFI runner, errno changed from EEXIST (17) to EAGAIN (11) between
separate FFI calls. The opener rejected an existing lock or active file.

After an unsuccessful exclusive create, attempt a non-creating append open of
the same path instead of branching on transient errno. Both opens retain
O_NOFOLLOW and nonblocking flags; the descriptor must still pass regular-file,
ownership and 0600 validation before writing. If both fail, signal a permission
error. No alternate path or fragment retry is introduced.

The sink counts closed/invalid records, lock timeouts, short writes, I/O failures,
redactor withholding and unexpected record failures separately, with fixed
metadata-only notices limited to once a minute. The gate requires every writer's
drop counters to be zero, in addition to complete retained-window continuity.
Rotation decision, descriptor size inspection, shifts and write remain inside
one flock hold. The two-second acquisition budget is unchanged.

Headless gate children omit stock image preferences: concurrent GlobalIdentifier
preference initialization otherwise races while creating the shared HOME's
`.config`, before the logger or telemetry code executes.

Directory preparation now attempts mkdir then validates a non-creating
O_DIRECTORY/O_NOFOLLOW open, regardless of mkdir's result. Shared existence
checks live in `PuntLibC>>exists:` and preserve metadata failures for existing
files and dangling symlinks after validating their parent. Salt publication
always validates the final winner instead of branching on link errno, and
temporary unlink failure is surfaced. No production decision reads errno in a
separate FFI call. Existing sidecars use the same existence boundary.

## Clause Traceability

The table maps every Pharo clause to its owning classes and executable gates.
Selectors below are in the named SUnit class; Python gates inspect files from
independent images. The gates validate behavior, not merely source citations.
They are not proofs against hostile code executing within the same image or
arbitrary replacement of private directories by another process with this UID.

<!-- markdownlint-disable MD013 -->
| Clause | Implementation | SUnit / installed-image gate |
| --- | --- | --- |
| PHARO-LOG-1 | `PuntLogSignal`, `PuntLog`, `PuntLogSourceGate` | `PuntLogTest>>testOnlyTypedSignalsAndSafeErrorFields`, `testReusableSourceGate`; `PuntTelemetryTest>>testSourceGateIncludesExtensions` |
| PHARO-LOG-2 | `PuntLog` singleton and SessionManager hooks; caller-owned `PuntLogZincBridge` | `PuntLogTest>>testRepeatedStartAndStop`, `testSessionResolvesChangedHome`, `testZincBridgeOwnedAndIdempotent`; `PuntLogSinkTest>>testCloseDrainsActiveCriticalSection` |
| PHARO-LOG-3 | `PuntHome`, `PuntLibC`, `PuntPrivateFile`, `PuntLogSink` | `PuntHomeTest>>testNewAndExistingDirectoriesArePrivate`, `testDirectorySymlinkRejected`, `testForeignDirectoryOwnerRejected`, `testDeniedDirectoryTightening`, `testExactPathsFromDifferentWorkingDirectories`; `PuntPrivateFileTest>>testFileSymlinkRejected`, `testDeniedFileTightening`; `PuntLogSinkTest>>testExactPathsModesAndExistingBackups` |
| PHARO-LOG-4 | `PuntLogSink` shared-budget Mutex/flock, one append, rotation | `PuntLogSinkTest>>testHeldFlockTimeoutThenRecovery`, `testLocalMutexHasSameBoundedBudget`, `testMissingBackupIgnoresStaleErrno`, `testFailedMetadataNeverHidesExistingFilesOrSymlinks`, `testOversizedExistingFilesAreNeverDeleted`; `PuntLogTest>>testNegativeWriteResultIsNotPartialWrite`; `PuntLogImagesTest>>testConcurrentImagesAcrossRetentionWindow` / `scripts/logging-images.py`; `scripts/smoke.py` concurrency and CLI-held-lock cases |
| PHARO-LOG-5 | `PuntLogSignal`, `PuntLogErrorSignal`, `PuntLogRedactor`, `PuntLogRegexMatcher`, `PuntEscaper` | `PuntLogRedactorTest>>testGoPatterns`, `testControlsAndUtf8ByteCap`, `testFailureAndUnsettledWithheld`, `testControlPatternsSurviveTonel`; `PuntLogTest>>testFailuresAreWithheldAndNonRecursive`, `testNumericObjectsAreNeverPrinted`, `testDropAccountingIsCategorizedAndNonRecursive`; smoke secret/control inspection |
| PHARO-LOG-6 | `PuntLogLevel`, `PuntLogFormatter`, `PuntLogWorkSignal`, `PuntLog` fork/child helpers | `PuntLogTest>>testFormatLevelsAndForgedLines`, `testForkOutcomesAreCorrelated`, `testSinkCapsAndUnicodeControls`; smoke success/fail exit and detached child intent/start/complete checks |
| PHARO-TEL-1 | `PuntTelemetry`, private `PuntTelemetryPipeline`, `PuntLogSourceGate` | `PuntTelemetryTest>>testSourceGateIncludesNestedProviders`, `testSourceGateIncludesNonClassOtelGlobals`, `testSourceGateIncludesOtelExtensionOwners`, `testSourceGateIncludesExtensions`; `testTypedSignalsAndPrivateRows` |
| PHARO-TEL-2 | `PuntTelemetrySchema`, `PuntTelemetryField`, `PuntTelemetryRecord`, `PuntTelemetrySalt` | `PuntTelemetryTest>>testRejectionsNeverRaise`, `testIdentifierBounds`, `testQueueCapacityAndHashSnapshot`, `testSaltRaceAndSeparation`, `testSaltRejectsFifoAndEmptyFileWithoutBlocking`, `testTypedSignalsAndPrivateRows`; independent salt race in `scripts/telemetry-images.py`; smoke independently calculates HMAC |
| PHARO-TEL-3 | `PuntTelemetryStore`, `PuntTelemetryConnection`, `PuntSQLiteSpanExporter`, `PuntSQLiteMetricExporter` | `PuntTelemetryTest>>testPrivateDatabaseAndJournal`, `testStartupAndIdleRetention`, `testConnectionFinalizationIsExactlyOnce`, `testTerminationDuringStoreSetupClosesConnection`, `testTerminatedTransactionRollsBackWithoutClosingStore`; `PuntTelemetryImagesTest>>testIndependentImagesAndBusyTimeout` / `scripts/telemetry-images.py` |
| PHARO-TEL-4 | `PuntTelemetryConfig`, `PuntTelemetry` session hooks, `PuntTelemetryPipeline` exporter selection | `PuntTelemetryTest>>testConfigurationBoundsAndConsent`, `testConfigurationOwnsEndpointSnapshot`, `testEveryVetoAndSessionReread`, `testOtlpOnlyExplicitConfigWithHashedPayload`; smoke global/tool/config vetoes with empty and seeded HOME |
| PHARO-TEL-5 | `PuntTelemetryQueue`, `PuntTelemetryWorker`, guarded exporters, `PuntTelemetryDiagnostics` | `PuntTelemetryTest>>testFacadeSaturationDoesNotWaitForExporter`, `testExporterFailureAndBoundedShutdown`, `testUnwritableStoreDoesNotRaiseIntoOperation`, `testDiagnosticsAreFixedAndRateLimited`, `testDiscardCountsEveryQueuedRecord`, `testForcedShutdownCountsQueueAndNoticesInterruption`, `testPartialPipelineSetupClosesStore`; smoke shutdown checks |
<!-- markdownlint-enable MD013 -->

The static source gate cannot see dynamically constructed global lookups.
Runtime coverage is Linux x86_64; macOS ABI declarations remain unverified.
Python image gates refuse optimized execution rather than silently removing
assertions. Their subprocess cleanup is bounded; SQLite inspector connections
are explicitly closed instead of relying on transaction contexts or GC.
