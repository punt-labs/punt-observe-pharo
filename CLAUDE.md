# punt-observe-pharo

Shared private filesystem and escaping foundation for Punt Labs Pharo tools.
The authoritative logging and telemetry requirements are the
[Pharo rules](https://github.com/punt-labs/punt-kit/blob/main/lang-rules/pharo/pharo-logging.md).

## Development Model

Run `make setup` then `make start-headless` (localhost:8430, PORT override).
Read `/help/pharo`, `/help/safety`, `/help/testing`, `/help/lint` first.
Compile via POST /repl using fluid class syntax, class comments with clause
citations and runnable examples, and named protocols. Do not hand-edit Tonel.
Persist package snapshots using TonelWriter into src/. Save the image explicitly
when needed; stop does not save. Do not commit image artifacts.

## Quality Gates

`make lint` runs shellcheck plus method and class-level Renraku critiques for
every PuntObserve class and its baseline. `make test` runs only project SUnit
tests. Both fail nonzero on evaluation errors, empty selection or findings.
`make check` runs both. Run Markdown lint as listed in CONTRIBUTING.md.

## Scope

Core, Logging and Telemetry are implemented. Smoke remains a scaffold for a
later stage; do not claim its behavior exists.
Do not install global providers. Resolve home again after image restoration.
Follow [DESIGN.md](DESIGN.md), [Core API](docs/core.md), and
[Logging API](docs/logging.md) and [Telemetry API](docs/telemetry.md) for ownership
and lifecycle. Consuming tools declare typed schemas; only this shared package
may use OpenTelemetry providers, exporters or arbitrary attribute dictionaries.
