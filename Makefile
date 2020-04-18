test:
	swift test --enable-code-coverage
	xcrun llvm-cov export -format="lcov" .build/debugExplorerPackageTests.xctest -instr-profile .build/debug/codecov/default.profdata > info.lcov
	bash <(curl https://codecov.io/bash)

test_linx:
	swift test --enable-code-coverage
	llvm-cov export -format="lcov" .build/debugExplorerPackageTests.xctest -instr-profile .build/debug/codecov/default.profdata > info.lcov
	bash <(curl https://codecov.io/bash)

make_linux_test:
	swift test --generate-linuxmain

.PHONY: test test_linx make_linux_test