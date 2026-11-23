# Contributing

Install git, curl, unzip, make and shellcheck. Node is needed for Markdown lint.
Work against the live image; persist packages with TonelWriter, not hand edits.
See [CLAUDE.md](CLAUDE.md) for the image workflow.

```sh
make setup
```

```sh
make start-headless
```

```sh
make check
```

```sh
npx -y markdownlint-cli2 '**/*.md'
```

```sh
make stop
```

Use `PORT=8431` to isolate another image. To verify a fresh download without
overwriting the workspace image, use `make IMAGE_DIR="$PWD/.tmp/fresh-pharo"
setup`, then use that same IMAGE_DIR with PORT=8431 for startup and shutdown.
Never run setup against a running image. Stop does not save.

Managed startup/shutdown requires Python 3 and Linux pidfd support. Runtime
records include kernel start time and boot identity; stop also verifies the
image/port command line. Legacy numeric PID files are refused: confirm ownership
and stop the old image manually before removing its stale record and restarting.
Unsupported systems fail closed before launching a managed image; bootstrap and
in-image APIs remain independent of this Linux runtime-management helper.

On macOS, run `make setup`, then start a foreground Postern image in one terminal:

```sh
./pharo/pharo "$PWD/pharo/Pharo.image" eval --no-quit 'PosternServer startOn: 8430'
```

Run `make check` in a second terminal, then stop the foreground image with
Ctrl-C. `make smoke` runs independently of Postern.
