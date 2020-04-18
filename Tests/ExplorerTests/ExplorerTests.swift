import XCTest
@testable import Explorer

final class ExplorerTests: XCTestCase {
    func test_currentDirectoryPath() {
        let explorer = Explorer(with: mockCurrentDirectory())
        
        XCTAssertEqual(explorer.currentDirectoryPath, "/Users/wendyliga/Desktop")
    }
    
    func test_delete_success() {
        let explorer = Explorer(with: successRemoveItem())
        
        let operation = SingleFileOperation(file: File(name: "explorer", content: nil, extension: "swift"), path: "/Users/wendyliga/Desktop")
        let target = explorer.delete(operation: operation)
        
        XCTAssertNoThrow(try target.getAndForget())
    }
    
    func test_delete_failure() {
        let explorer = Explorer(with: failRemoveItem())
        
        let operation = SingleFileOperation(file: File(name: "explorer", content: nil, extension: "swift"), path: "/Users/wendyliga/Desktop")
        let target = explorer.delete(operation: operation)
        
        XCTAssertEqual(target.failureValue as? ExplorerError, ExplorerError.fileNotValid(file: "explorer.swift"))
    }
    
    func test_writeWithSafeStrategy_success() {
        let explorer = Explorer(with: successWrite())
        
        let operation = SingleFileOperation(file: File(name: "explorer", content: nil, extension: "swift"), path: "/Users/wendyliga/Desktop")
        let target = explorer.write(operation: operation, writingStrategy: .safe)
        
        XCTAssertNoThrow(try target.getAndForget())
    }
    
    func test_writeWithSafeStrategy_failedBecauseFileExist() {
        let explorer = Explorer(with: writeOnFileExist())
        
        let operation = SingleFileOperation(file: File(name: "explorer", content: nil, extension: "swift"), path: "/Users/wendyliga/Desktop")
        let target = explorer.write(operation: operation, writingStrategy: .safe)
        
        XCTAssertEqual(target.failureValue as? ExplorerError, ExplorerError.fileExist(file: "/Users/wendyliga/Desktop/explorer.swift"))
    }
    
    func test_writeWithSafeStrategy_failedOnFileManager() {
        let explorer = Explorer(with: failWriteOnFileManager())
        
        let operation = SingleFileOperation(file: File(name: "explorer", content: nil, extension: "swift"), path: "/Users/wendyliga/Desktop")
        let target = explorer.write(operation: operation, writingStrategy: .safe)
        
        XCTAssertEqual(target.failureValue as? ExplorerError, ExplorerError.writeError(file: "/Users/wendyliga/Desktop/explorer.swift"))
    }
    
    func test_writeWithOverwriteStrategy_successOnExistingFileExist() {
        let explorer = Explorer(with: writeOnFileExist())
        
        let operation = SingleFileOperation(file: File(name: "explorer", content: nil, extension: "swift"), path: "/Users/wendyliga/Desktop")
        let target = explorer.write(operation: operation, writingStrategy: .overwrite)
        
        XCTAssertNoThrow(try target.getAndForget())
    }
    
    func test_writeWithSkipStrategy_successOnExistingFileExist() {
        let explorer = Explorer(with: writeOnFileExist())
        
        let operation = SingleFileOperation(file: File(name: "explorer", content: nil, extension: "swift"), path: "/Users/wendyliga/Desktop")
        let target = explorer.write(operation: operation, writingStrategy: .skippable)
        
        XCTAssertNoThrow(try target.getAndForget())
    }
    
    static var allTests = [
        ("test_currentDirectoryPath", test_currentDirectoryPath),
        ("test_delete_success", test_delete_success),
        ("test_delete_failure", test_delete_failure),
        ("test_writeWithSafeStrategy_success", test_writeWithSafeStrategy_success),
        ("test_writeWithSafeStrategy_failedBecauseFileExist", test_writeWithSafeStrategy_failedBecauseFileExist),
        ("test_writeWithSafeStrategy_failedOnFileManager", test_writeWithSafeStrategy_failedOnFileManager),
        ("test_writeWithOverwriteStrategy_successOnExistingFileExist", test_writeWithOverwriteStrategy_successOnExistingFileExist),
        ("test_writeWithSkipStrategy_successOnExistingFileExist", test_writeWithSkipStrategy_successOnExistingFileExist),
    ]
}
