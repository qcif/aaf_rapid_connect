# Makefile for aaf_rapid_connect

.PHONY: help format test coverage doc clean

#----------------------------------------------------------------

help:
	@echo "Make targets:"
	@echo "  format    format Dart code"
	@echo "  test      run tests"
	@echo "  coverage  run coverage on tests *"
	@echo "  doc       generate documentation *"
	@echo "  pana      run pana"
	@echo "  clean     delete generated files"
	@echo
	@echo '* "coverage-open" and "doc-open" to run and then open the HTML'

#----------------------------------------------------------------
# Development

format:
	dart format  lib test example

#----------------------------------------------------------------
# Testing

test:
	dart run test

# Coverage tests require "lcov"

coverage:
	@if which genhtml >/dev/null; then \
	  dart run coverage:test_with_coverage && \
	  genhtml coverage/lcov.info -o coverage/html || \
	  exit 1 ; \
	else \
	  echo 'coverage: genhtml not found: please install "lcov"' ; \
	  echo '          on macOS install "lcov" with "brew install lcov"' ; \
	  exit 2 ; \
	fi

coverage-open: coverage
	open coverage/html/index.html

#----------------------------------------------------------------
# Documentation

doc:
	dart doc

doc-open: doc
	open doc/api/index.html

#----------------------------------------------------------------
# Publishing

pana:
	dart run pana

#----------------------------------------------------------------

clean:
	rm -rf coverage doc

#EOF
