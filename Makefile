# Makefile

.PHONY: doc test coverage

#----------------------------------------------------------------

help:
	@echo "Targets:"
	@echo "  format   - format Dart code"
	@echo "  test     - run tests"
	@echo "  coverage - run coverage on tests *"
	@echo "  doc      - generate API reference documentation *"
	@echo "  clean    - delete generated files"
	@echo
	@echo "* coverage-open and doc-open to run it and then open the HTML"


#----------------------------------------------------------------

format:
	dart format  lib test example

#----------------------------------------------------------------

test:
	dart run test

coverage:
	dart run coverage:test_with_coverage
	# on macOS, install lcov with "brew install lcov" for genhtml command
	genhtml coverage/lcov.info -o coverage/html

coverage-open: coverage
	open coverage/html/index.html

#----------------------------------------------------------------

doc:
	dart doc

doc-open: doc
	open doc/api/index.html

#----------------------------------------------------------------

clean:
	rm -rf doc coverage

#EOF
