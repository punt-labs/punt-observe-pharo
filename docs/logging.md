# Durable diagnostics

Oversized pre-existing active files or backups fail setup without deletion;
recover them explicitly before retrying. One append write is not an fsync or a
power-loss guarantee. Scalar fields print only primitive numeric/Boolean/nil
values; other objects, including arbitrary Number subclasses, are placeholders.
Callers own the lifetimes of forked application work and optional Zinc bridges.
Stopping the logger drains its sink, not arbitrary application processes.

`PuntLog current dropCounts` returns a copy of the sink's per-image counters:
`#lockTimeout`, `#shortWrite`, `#ioFailure`, `#redactorWithhold`, `#recordFailure`,
`#invalidRecord` and `#closed`. Every dropped record is counted, even when the
fixed metadata-only stderr notice is rate-limited (once per minute) or disabled
for MCP operation. Counters do not contain messages, fields or exception text.
`PuntShortWriteError` is a `PuntPermissionError`; partial writes are not retried.

Start once at an image entry point; library code only emits typed signals:

```smalltalk
PuntLog startTool: 'example' role: 'cli'.
(PuntLogSignal new component: 'startup'; message: 'Service started') emit.
(PuntLogSecuritySignal new component: 'auth'; message: 'Request rejected') emit.
(PuntLogErrorSignal new
  component: 'worker'; message: 'Operation failed'; error: anError) emit.
PuntLog stop.
```

`startTool:role:level:` selects `PuntLogLevel debug`, `info`, `warning` or
`error`. The default is INFO. Repeated start returns the existing logger;
stop before changing tools. `PuntLog level:` changes the active threshold.
`PuntLog isRunning` reports the subscription state.

Define a `PuntLogSignal` subclass for approved fields. Declare its class-side
`level` if not INFO. Override `fieldsOn:` and call
`self field: 'fieldName' value: fieldValue on: stream` for each explicit field.
Only safe metadata belongs in fields. Do not emit arbitrary objects or use
exception text. `error:` captures only the exception class. The complete
formatted record is redacted before UTF-8 encoding reaches the sink; failures,
unsettled redaction and oversized records are withheld.
Escaped credential whitespace is restored before masking, then escaped again
on the final record, so an escaped field newline cannot conceal a token.

```smalltalk
PuntLog fork: [ self performWork ] named: 'indexer' correlation: requestId.
PuntLog fork: [ self performWork ] named: 'indexer'
  correlation: requestId at: Processor userBackgroundPriority.
```

The helper records started/completed/failed outcomes with the same correlation
ID and contains background errors. For child images use `spawnIntent:` at the
parent boundary and, after starting the logger in the child, `childStarted:`,
`childCompleted:` or `childFailed:correlation:`. Starting a process is not proof
of completion.

An optional `PuntLogZincBridge new start` records Zinc event types at DEBUG.
The caller owns the bridge and must send `stop` when closing it. It never
renders the Zinc event itself.

The stable lock file and active log are private (0600); directories are 0700.
The sink opens and closes the active descriptor for every append, while holding
an image-local Mutex and a nonblocking cross-image flock. Both acquisition
loops share a two-second budget. Rotation occurs before exceeding 5,242,880
bytes and retains five backups. Oversized inherited files are discarded rather
than retained outside that bound. Session startup reconstructs the sink from
the current home; no descriptor is kept between appends.

Lock timeouts produce only a fixed, rate-limited stderr notice, never another
Beacon signal. An MCP entry point should call `PuntLog noticesEnabled: false`
before starting the logger to suppress notices, including during setup. This
image-wide notice policy survives session startup.

## Consumer source gate

Use this in a consuming project's tests, passing production package names and
the class names of the explicitly permitted entry points:

```smalltalk
self assert: (PuntLogSourceGate
  violationsInPackages: #('Example-Core' 'Example-Server')
  allowing: #(ExampleEntryPoint)) isEmpty.
```

The gate scans compiled references, including nested blocks, for Transcript,
Stdio, SignalLogger subclasses and Zinc announcer access. It also rejects a
SignalLogger subclass declaration outside the allowlist. It does not attempt
to prove the safety of dynamically constructed selectors or global lookups.

## Acceptance harness

`make test` includes an SUnit harness that launches two independent images
using the running VM and image paths, with an isolated HOME and all standard
streams discarded. Each writes 420 uniquely tagged approximately 47 KB records.
The Python standard-library verifier checks all retained lines, per-writer
sequence continuity, payload integrity, correlated child outcomes, retention,
byte bounds and modes. Allow up to five minutes for the REPL test request.
Use an image built from Tonel before running the harness: child processes load
the image file on disk, not unsaved changes in the parent workspace.
