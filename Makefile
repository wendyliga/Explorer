test:
	swift test --enable-code-coverage

make_linux_test:
	swift test --generate-linuxmain

.PHONY: test make_linux_test