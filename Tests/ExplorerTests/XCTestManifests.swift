import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ExplorerTests.allTests),
        testCase(StringTests.allTests),
    ]
}
#endif
