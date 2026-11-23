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
