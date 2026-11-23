PORT ?= 8430
IMAGE_DIR ?= $(CURDIR)/pharo
export PORT IMAGE_DIR
.DEFAULT_GOAL := help
.PHONY: help setup start-headless stop test lint check shellcheck smoke

help:
	@printf '%s\n' 'setup start-headless stop test lint check shellcheck smoke' 'PORT=8430 (override supported); IMAGE_DIR=pharo'

setup:
	@sh scripts/setup

start-headless:
	@sh scripts/runtime start

stop:
	@sh scripts/runtime stop

test:
	@sh scripts/eval scripts/test.st

lint: shellcheck
	@sh scripts/eval scripts/lint.st

check: lint test

shellcheck:
	shellcheck scripts/setup scripts/runtime scripts/eval scripts/smoke

smoke:
	@sh scripts/smoke
