# Agent Instructions

Read [CLAUDE.md](CLAUDE.md) before changing Smalltalk. Develop through the live
Postern REPL; persist Tonel to src/. Never edit sibling repositories.

Follow the Punt Labs Pharo logging and telemetry rules. Run `make lint` and
`make test` before committing. Never introduce blocking flock calls or fallback
private paths. Do not start loggers or telemetry as a package-load side effect.
