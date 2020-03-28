import Foundation

public protocol FileProvider {
    func fileExists(atPath: String) -> Bool
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func removeItem(atPath: String) throws
    func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool
    func createDirectory(atPath: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey : Any]?) throws
    func contentsOfDirectory(atPath path: String) throws -> [String]
    
    var currentDirectoryPath: String { get }
}

public class DefaultFileProvider: FileProvider {
    private let fileManager = FileManager.default
    
    public init() {}
    
    public var currentDirectoryPath: String {
        fileManager.currentDirectoryPath
    }
    
    public func fileExists(atPath: String) -> Bool {
        fileManager.fileExists(atPath: atPath)
    }
    
    public func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        fileManager.fileExists(atPath: path, isDirectory: isDirectory)
    }
    
    public func removeItem(atPath: String) throws {
        try fileManager.removeItem(atPath: atPath)
    }
    
    public func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey : Any]? = nil) -> Bool {
        fileManager.createFile(atPath: atPath, contents: contents, attributes: attributes)
    }
    
    public func createDirectory(atPath: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        try fileManager.createDirectory(atPath: atPath, withIntermediateDirectories: withIntermediateDirectories, attributes: attributes)
    }
    
    public func contentsOfDirectory(atPath path: String) throws -> [String] {
        try fileManager.contentsOfDirectory(atPath: path)
    }
}
