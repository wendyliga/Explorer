test:
	swift test --enable-code-coverage

test_xcodebuild:
	swift package generate-xcodeproj
	xcodebuild test -enableCodeCoverage YES -scheme Explorer-Package | xcpretty

make_linux_test:
	swift test --generate-linuxmain

.PHONY: test make_linux_test