test:
	swift test --enable-code-coverage

test_linux:
	swift test --generate-linuxmain
	swift test --enable-code-coverage

.PHONY: test test_linux