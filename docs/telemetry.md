# Telemetry API

Load `PuntObserve-Telemetry` (or the baseline's `default` group). Loading alone
does not start a worker, create files or install global OpenTelemetry providers.

## Declare a Schema

Create one `PuntTelemetrySchema` subclass per signal version. Each attribute is
an explicit instance slot with an ordinary setter. Class-side declarations:

| Selector | Contract |
| --- | --- |
| `signalName` | `tool.surface.action`, lowercase ASCII components |
| `schemaVersion` | Positive integer; defaults to 1 |
| `signalKind` | `#span`, `#event`, `#counter`, `#histogram`; default `#span` |
| `unit` | Nil for spans/events; `'1'`, `'By'` or `'ms'` for metrics |
| `fieldSpecs` | Dictionary from slot names to `PuntTelemetryField` values |

For example, a schema with `outcome` and `customer` slots declares:

```smalltalk
fieldSpecs
  ^ Dictionary new
    at: #outcome put: (PuntTelemetryField enum: #(ok failed) required: true);
    at: #customer put: (PuntTelemetryField kind: #identifier required: false);
    yourself
```

Field kinds are `#enum`, `#boolean`, `#integer`, `#duration`, `#count`, `#size`,
`#length` and `#identifier`. Enum values must be declared Symbols, not arbitrary
strings. Numeric fields are signed 64-bit integers; all except `#integer` must
be nonnegative. Identifiers are strings of at most 65536 UTF-8 bytes, replaced
with installation-specific HMAC-SHA256 hex before queueing. No raw identifier
or salt is put in a queue, database row or OTLP payload. Do not pre-hash values.
There are at most 24 fields, and declared fields must exactly match schema slots.
`punt.schema.version` is added automatically.

Inherited observation setters are `startedAt:` (`DateAndTime`), `duration:`
(milliseconds), and `amount:` (integer metric value). Defaults are now, zero
duration, and amount 1. The metric's `unit` describes `amount:`. Attribute units
are part of the application's versioned schema contract.

## Start, Record and Stop

```smalltalk
PuntTelemetry
  startTool: 'example'
  config: PuntTelemetryConfig new
  schemas: { ExampleOperationV1 }.

PuntTelemetry record: (ExampleOperationV1 new
  outcome: #ok;
  customer: 'caller-owned identifier';
  yourself).

PuntTelemetry shutdown.
```

First start wins until `shutdown`. Schema classes must belong to the selected
tool's signal namespace, with unique name/version pairs. Invalid configuration
or schema declarations fail startup before worker creation. `record:` returns
true for admission, not delivery; unknown classes/versions, invalid fields,
disabled telemetry, closed/full queues and operational errors return false
without raising into the operation. A worker exporter failure cannot change an
already returned admission result. The queue holds at most 1024 records and
never waits for room. Shutdown is bounded; remaining queued records are counted
as dropped when discarded. Forced interruption emits a fixed diagnostic because
in-flight delivery is unknown. `dropped` is not an exporter-delivery counter.
Exporter failures use rate-limited diagnostics through a running PuntLog, with
no raw-output fallback. Configuration snapshots copy the endpoint string.

Class-side lifecycle is `startTool:config:schemas:`, `record:`, `shutdown` and
`current`. An instance also answers `record:`, `shutdown`, `isEnabled`, `dropped`.
SessionManager invokes `startUp:`/`shutDown:`; consumers do not call those hooks.

## Configuration and Files

| Setter | Default / rules |
| --- | --- |
| `retentionDays:` | 90; integer 1..3650 |
| `maintenanceSeconds:` | 300; integer 1..3600 |
| `disabled:` | false; Boolean veto |
| `otlpConsent:` | false; explicit Boolean opt-in |
| `otlpEndpoint:` | Nil; endpoint plus consent selects OTLP instead of SQLite |

`PUNT_TELEMETRY=off`, `<TOOL>_TELEMETRY=off`, or config disabled veto telemetry.
The tool variable uppercases its name and converts hyphens to underscores.
Vetoes are reread at every start and image startup. Disabled startup creates no
directories, database, exporters or worker. `OTEL_*` variables do not select a
backend or override these settings.

Default storage is `~/.punt-labs/<tool>/telemetry.db`, pre-created at 0600 under
0700 directories. DELETE journals and existing sidecars are checked/tightened.
SQLite uses a 200 ms busy timeout; each export is transactional. Old rows are
pruned at worker startup and on its timer, followed by incremental vacuum.
`~/.punt-labs/telemetry.salt` is shared by tools in an installation, published
atomically at 0600 from /dev/urandom. It is never cached across snapshots.

OTLP requires consent and an HTTPS endpoint, or HTTP to a literal supported
loopback address. Credentials, query strings and fragments are rejected. The
base endpoint gets `/v1/traces` and `/v1/metrics` appended. No SQLite database
is opened for OTLP; identifiers still use the local private salt. Export uses
protobuf HTTP, one attempt and a 500 ms timeout, with no raw error diagnostics.
The loaded Zinc URL parser does not support bracketed IPv6 endpoints; use
`127.0.0.1` for a local collector with this image.

## Consuming-Code Gate

Use `PuntLogSourceGate violationsInPackages:allowing:` in a consuming project's
tests. Allow only explicit entry-point class names. The gate rejects compiled
OT-prefixed global references (including nested blocks), OT subclasses and
extension owners, plus the
logging boundaries documented in [Logging API](logging.md). It does not detect
dynamically constructed global lookups.

`make test` covers rejection, hashed-only records and payloads, salt races,
permissions and rollback journals, startup/timer retention, all vetoes,
saturation, exporter faults and bounded shutdown. The independent-image gate
uses two headless images writing the same SQLite database, with a held external
transaction to exercise busy timeouts, 200 retained rows, integrity and modes.
