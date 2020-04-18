import XCTest
@testable import Explorer

final class StringTests: XCTestCase {
    func test_withoutExtension_normal() {
        let target = "explorer.swift"
        let expected = "explorer"
        
        XCTAssertEqual(target.withoutExtension(), expected)
    }
    
    func test_withoutExtension_withoutExtensionItSelf() {
        let target = "explorer"
        let expected = "explorer"
        
        XCTAssertEqual(target.withoutExtension(), expected)
    }
    
    func test_withoutExtension_doubleExtension() {
        let target = "explorer.com.swift"
        let expected = "explorer.com"
        
        XCTAssertEqual(target.withoutExtension(), expected)
    }
    
    static var allTests = [
        ("test_withoutExtension_normal", test_withoutExtension_normal),
        ("test_withoutExtension_withoutExtensionItSelf", test_withoutExtension_withoutExtensionItSelf),
        ("test_withoutExtension_doubleExtension", test_withoutExtension_doubleExtension),
    ]
}
