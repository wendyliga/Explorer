import Foundation
@testable import Explorer

extension FileProvider {
    var currentDirectoryPath: String { "" }
    func fileExists(atPath: String) -> Bool { false }
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool { false }
    func removeItem(atPath: String) throws {}
    func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool { false }
    func createDirectory(atPath: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey : Any]?) throws {}
    func contentsOfDirectory(atPath path: String) throws -> [String] { [] }
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any] { [:] }
}

internal final class mockCurrentDirectory: FileProvider {
    var currentDirectoryPath: String = "/Users/wendyliga/Desktop"
}

internal final class successRemoveItem: FileProvider {
    func removeItem(atPath: String) throws {}
}

internal final class failRemoveItem: FileProvider {
    func removeItem(atPath: String) throws {
        throw ExplorerError.fileNotValid(file: "explorer.swift")
    }
}

internal final class successWrite: FileProvider {
    func fileExists(atPath: String) -> Bool {
        false
    }
    
    func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool {
        true
    }
}

internal final class writeOnFileExist: FileProvider {
    func fileExists(atPath: String) -> Bool {
        true
    }
    
    func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool {
        true
    }
}

internal final class failWriteOnFileManager: FileProvider {
    func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool {
        false
    }
}
