# punt-observe-pharo

`make smoke` exercises the installed path in a newly downloaded Pharo 12 image.
It checks success/failure outcomes, detached child correlation, concurrent
rotation, bounded lock drops and recovery, telemetry privacy, and all off
switches. Linux requires `python3`, `stat`, `flock` and `setsid`. Artifacts and
the fresh installed image remain under the printed `.tmp/smoke-*` directory.
See the [smoke guide](docs/smoke.md) for the entry point and artifact layout.

> Private, durable diagnostics for Punt Labs Pharo tools.

[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/punt-labs/punt-observe-pharo/test.yml?label=CI)](https://github.com/punt-labs/punt-observe-pharo/actions/workflows/test.yml)

An alpha shared library for Pharo tools that need private machine-scoped files,
redacted diagnostics, cross-image bounded rotation and typed private telemetry.
Loading packages does
not start loggers or install global telemetry providers.

**Platforms:** Linux x86_64; macOS ABI support is implemented but not yet tested.

## Quick Start

From a checkout, load the Core group in a Pharo image:

<!-- markdownlint-disable MD013 -->
```smalltalk
Metacello new baseline: 'PuntObserve'; repository: 'tonel:///absolute/path/to/punt-observe-pharo/src'; load: 'PuntObserve-Core'.
```
<!-- markdownlint-enable MD013 -->

## API

- `PuntHome`: validate names and prepare private machine-scoped directories.
- `PuntPrivateFile`: open, validate, tighten and append bytes to private files.
- `PuntLibC`: POSIX operations and descriptor metadata.
- `PuntEscaper`: escape control and Unicode format characters.
- `PuntLog`: start/stop the one durable Beacon logger and wrap background work.
- `PuntLogSignal`: typed metadata-only diagnostics, with error/security variants.
- `PuntLogZincBridge`: optional caller-owned DEBUG bridge for Zinc event types.
- `PuntTelemetry`: start the bounded, session-aware telemetry worker and record
  registered typed schemas without exposing OpenTelemetry to consuming tools.
- `PuntTelemetrySchema`, `PuntTelemetryField`: closed versioned observations;
  identifier strings are HMAC-SHA256 derived before queue admission.
- `PuntTelemetryConfig`: retention, off switches and explicit OTLP consent.

Paths resolve beneath `FileLocator home / '.punt-labs'`, never the working
directory. Core permission failures signal `PuntPermissionError`; callers must
not fall back to an insecure location. Logging write failures are counted and
noticed; telemetry admission returns false and exporter failures produce fixed,
rate-limited diagnostics. Neither mechanism guarantees delivery.

## Documentation

[Core API](docs/core.md) | [Logging API](docs/logging.md) |
[Telemetry API](docs/telemetry.md) |
[Contributing](CONTRIBUTING.md) |
[Design](DESIGN.md) | [Changelog](CHANGELOG.md)

## License

MIT
