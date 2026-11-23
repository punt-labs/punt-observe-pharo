# punt-observe-pharo

> Private filesystem primitives for Punt Labs Pharo tools.

[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![CI](https://img.shields.io/github/actions/workflow/status/punt-labs/punt-observe-pharo/test.yml?label=CI)](https://github.com/punt-labs/punt-observe-pharo/actions/workflows/test.yml)

An alpha shared library for Pharo tools that need private machine-scoped files
and single-line escaping. The current implementation provides the filesystem
foundation; it does not start loggers or install global telemetry providers.

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

Paths resolve beneath `FileLocator home / '.punt-labs'`, never the working
directory. Permission failures signal `PuntPermissionError`; callers must not
fall back to an insecure location.

## Documentation

[Core API](docs/core.md) | [Contributing](CONTRIBUTING.md) |
[Design](DESIGN.md) | [Changelog](CHANGELOG.md)

## License

MIT
