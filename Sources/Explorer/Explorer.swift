import Foundation
import SwiftKit

public class Explorer {
    /**
     File manager instance that will used for `Explorer` Operation
     */
    private let fileManager: FileProvider
    
    /**
     Singleton of `Explorer` Class
     */
    public static let `default` = Explorer()
    
    public init(with fileManager: FileProvider = DefaultFileProvider()) {
        self.fileManager = fileManager
    }
}

/**
 Explorer Writing Strategy, when you called `create` function, you can provide writing strategy for it.
 */
public enum WriteStrategy {
    
    /**
     Will Skip existing file and only write file that doesn't exist
     */
    case skippable
    
    /**
     Report as what it is, if error is happended, will fail the operation
     */
    case safe
    
    /**
     Will Overwrite anything, if file exist, will overwrite it with the new one
     */
    case overwrite
}

/**
 An abstraction for any path related value used on Explorer
 
 For now used to abstract `Folder` and `File`
 */
public protocol Explorable {
    var attributes: [FileAttributeKey : Any]? { get }
}

public struct Folder: Explorable {
    public let name: String
    public let contents: [Explorable]
    public let attributes: [FileAttributeKey : Any]?
    
    public init(name: String, contents: [Explorable], attributes: [FileAttributeKey : Any]? = nil) {
        self.name = name
        self.contents = contents
        self.attributes = attributes
    }
}

public struct File: Explorable {
    public let name: String
    
    /**
     File content in String, for now, only support file that're not need any spesial encoding, so for example , png file will have empty content.
     */
    public let content: String?
    
    /**
     File extension
     */
    public let `extension`: String?
    public let attributes: [FileAttributeKey : Any]?
    
    public init(name: String, content: String?, extension: String?, attributes: [FileAttributeKey : Any]? = nil) {
        self.name = name
        self.content = content
        self.extension = `extension`
        self.attributes = attributes
    }
}

public struct SingleFileOperation {
    public let file: File
    public let path: String
    
    public init(file: File, path: String) {
        self.file = file
        self.path = path
    }
}

public struct BatchFileOperation {
    public let files: [File]
    public let path: String
    
    public init(files: [File], path: String) {
        self.files = files
        self.path = path
    }
}

public struct SingleFolderOperation {
    public let folder: Folder
    public let path: String
    
    public init(folder: Folder, path: String) {
        self.folder = folder
        self.path = path
    }
}

public struct BatchFolderOperation {
    public let folders: [Folder]
    public let path: String
    
    public init(folders: [Folder], path: String) {
        self.folders = folders
        self.path = path
    }
}

public enum ExplorerError: Error, LocalizedError {
    case pathDidNotExist(path: String)
    case fileExist(file: String)
    case fileNotValid(file: String)
    case directoryNotValid(directory: String)
    case writeError(file: String)
    
    public var errorDescription: String? {
        switch self {
        case .pathDidNotExist(let path):
            return "\(path) did not exist"
        case .fileExist(let file):
            return "\(file) is already exist"
        case .fileNotValid(let file):
            return "\(file) is not valid"
        case .writeError(let file):
            return "unable to write file at \(file)"
        case .directoryNotValid(let directory):
            return "\(directory) is not valid"
        }
    }
}

public protocol FileProvider {
    func fileExists(atPath: String) -> Bool
    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool
    func removeItem(atPath: String) throws
    func createFile(atPath: String, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool
    func createDirectory(atPath: String, withIntermediateDirectories: Bool, attributes: [FileAttributeKey : Any]?) throws
    func contentsOfDirectory(atPath path: String) throws -> [String]
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any]
    
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
    
    public func attributesOfItem(atPath path: String) throws -> [FileAttributeKey : Any] {
        try fileManager.attributesOfItem(atPath: path)
    }
}

extension String {
    /**
     Remove file extension from filename
     */
    func withoutExtension(replaceWith newString: String = "") -> String {
        var dotIndex: Int?
        var isDotFound = false
        
        for (index, character) in self.enumerated().reversed() {
            guard !isDotFound else { break }
            
            if character == "." && !isDotFound {
                dotIndex = index
                isDotFound = true
            }
        }
        
        guard let unwarpDotIndex = dotIndex else {
            return self
        }
        
        let startDotIndex = index(startIndex, offsetBy: unwarpDotIndex)
        return replacingCharacters(in: startDotIndex..<endIndex, with: newString)
    }
}

extension Explorer {
    private func target(path: String, suffix: String) -> String {
        return path
            .withoutPrefix("~", replaceWith: NSHomeDirectory())
            .withoutSuffix("/") + "/" + suffix.withoutPrefix("/")
            .withoutSuffix("/")
    }
}

extension Explorer {
    /**
     Delete File
     
     - Parameter operation: Delete operation, will delete spesific file at spesific path with `SingleFileOperation`
     
     - Returns: Result `Result<SingleFileOperation, Error>` of the operation.
     */
    @discardableResult
    public func delete(operation: SingleFileOperation) -> Result<SingleFileOperation, Error> {
        let target = self.target(path: operation.path, suffix: operation.file.name)
        
        do {
            try fileManager.removeItem(atPath: target)
            
            return .success(operation)
        } catch let error {
            return .failure(error)
        }
    }
    
    /**
    Delete Folder
    
    - Parameter operation: Delete operation, will delete spesific folder at spesific path.
    
    - Returns: Result `Result<SingleFileOperation, Error>` of the operation.
    */
    @discardableResult
    public func delete(operation: SingleFolderOperation) -> Result<SingleFolderOperation, Error> {
        let target = self.target(path: operation.path, suffix: operation.folder.name)
        
        do {
            try fileManager.removeItem(atPath: target)
            
            return .success(operation)
        } catch let error {
            return .failure(error)
        }
    }
}
    
extension Explorer {
    /**
     Write file
     
     - Parameters:
        - operation: Write Operation, will write spesific to the operation
        - writingStrategy: how you want the operation to write based on spesific strategy
        - currentProgressCallback: add your custom action in the middle of the operation (for example, you want to print the current progress operation)
     
     - Returns: Result of the operation.
     */
    @discardableResult
    public func write(operation: SingleFileOperation, writingStrategy: WriteStrategy = .safe) -> Result<SingleFileOperation, Error> {
        guard operation.path.isNotEmpty else {
            return .failure(ExplorerError.pathDidNotExist(path: operation.path))
        }
        
        guard operation.file.name.isNotEmpty else {
            return .failure(ExplorerError.fileNotValid(file: operation.file.name))
        }
        
        let target = self.target(path: operation.path, suffix: operation.file.name)
        
        if writingStrategy == .safe && fileManager.fileExists(atPath: target) == true {
            return .failure(ExplorerError.fileExist(file: target))
        }
        
        if writingStrategy == .skippable && fileManager.fileExists(atPath: target) == true {
            return .success(operation)
        }
        
        // default create file will overwrite the target
        guard fileManager.createFile(atPath: target, contents: operation.file.content?.data(using: .utf8), attributes: operation.file.attributes) else {
            return .failure(ExplorerError.writeError(file: target))
        }
        
        return .success(operation)
    }
    
    /**
    Write files
    
    - Parameters:
       - operation: Write Operation, will write spesific to the operation
       - writingStrategy: how you want the operation to write based on spesific strategy
       - currentProgressCallback: add your custom action in the middle of the operation (for example, you want to print the current progress operation)
    
    - Returns: Result of the operation.
    */
    @discardableResult
    public func write(operation: BatchFileOperation, writingStrategy: WriteStrategy = .safe) -> Result<BatchFileOperation, Error> {
        guard operation.path.isNotEmpty else {
            return .failure(ExplorerError.pathDidNotExist(path: operation.path))
        }
        
        let results = operation.files.map {
            write(operation: SingleFileOperation(file: $0, path: operation.path), writingStrategy: writingStrategy)
        }
        
        let failureResults = results.compactMap { $0.failureValue }
        
        // revert if failed
        guard failureResults.isEmpty else {
            
            // delete all success file
            results.compactMap{ $0.successValue }
                .forEach { delete(operation: $0) }
            
            return .failure(GeneralError.multipleError(failureResults))
        }
        
        return .success(operation)
    }
    
    /**
     Write Folder, define your folder and files, and `Explorer` will create for you.
     
     - Parameters:
        - operation: Write Operation, will write spesific to the operation
        - writingStrategy: how you want the operation to write based on spesific strategy
        - currentProgressCallback: add your custom action in the middle of the operation (for example, you want to print the current progress operation)
     
     - Returns: Result of the operation.
     */
    @discardableResult
    public func write(operation: SingleFolderOperation, writingStrategy: WriteStrategy = .safe) -> Result<SingleFolderOperation, Error> {
        guard operation.path.isNotEmpty else {
            return .failure(ExplorerError.pathDidNotExist(path: operation.path))
        }
        
        guard operation.folder.name.isNotEmpty else {
            return .failure(ExplorerError.directoryNotValid(directory: operation.folder.name))
        }
        
        let target = self.target(path: operation.path, suffix: operation.folder.name)
        
        do {
            try fileManager.createDirectory(atPath: target, withIntermediateDirectories: true, attributes: operation.folder.attributes)
        } catch let error {
            return .failure(error)
        }
        
        let folders = operation.folder.contents
            .compactMap { $0 as? Folder }
        
        let file = operation.folder.contents
            .compactMap { $0 as? File }
        
        let writeFolderOperation = BatchFolderOperation(folders: folders, path: target)
        let writeFileOperation = BatchFileOperation(files: file, path: target)
        
        if case .failure(let error) = write(operation: writeFolderOperation, writingStrategy: writingStrategy) {
             return .failure(error)
        }
        
        if case .failure(let error) = write(operation: writeFileOperation, writingStrategy: writingStrategy) {
             return .failure(error)
        }
        
        return .success(operation)
    }
    
    /**
    Write Folder, define your folder and files, and `Explorer` will create for you.
    
    - Parameters:
       - operation: Write Operation, will write spesific to the operation
       - writingStrategy: how you want the operation to write based on spesific strategy
        - currentProgressCallback: add your custom action in the middle of the operation (for example, you want to print the current progress operation)
    
    - Returns: Result of the operation.
    */
    @discardableResult
    public func write(operation: BatchFolderOperation, writingStrategy: WriteStrategy = .safe) -> Result<BatchFolderOperation, Error> {
        guard operation.path.isNotEmpty else {
            return .failure(ExplorerError.pathDidNotExist(path: operation.path))
        }
        
        let results = operation.folders.map {
            write(operation: SingleFolderOperation(folder: $0, path: operation.path), writingStrategy: writingStrategy)
        }
        
        let failureResults = results.compactMap { $0.failureValue }
        
        // revert if failed
        guard failureResults.isEmpty else {
            
            // delete all success file
            results.compactMap{ $0.successValue }
                .forEach { delete(operation: $0) }
            
            return .failure(GeneralError.multipleError(failureResults))
        }
        
        return .success(operation)
    }
}

extension Explorer {
    /**
     Check if current path is exist or not
     */
    public func isFileExist(path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    /**
     Check if current path is file or directory
     */
    public func isFile(path: String) -> Result<Bool, Error> {
        var isDirectory: ObjCBool = false
        
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) == true else {
            return .failure(ExplorerError.pathDidNotExist(path: path))
        }
        
        return .success(!isDirectory.boolValue)
    }
}

extension Explorer {
    /**
     Scan directory at path, will return the content inside it
     
     - Parameters:
        - path: Path to scan
        - withFolder: Also Scan folder or not
        - isRecursive: will include content inside folder
     
     - Returns: Result of Explorables
     */
    public func list(at path: String, withFolder isFolderIncluded: Bool, isRecursive: Bool) -> Result<[Explorable], Error> {
        let target = self.target(path: path, suffix: "")
        
        guard let findings = try? fileManager.contentsOfDirectory(atPath: target) else {
            return .failure(ExplorerError.directoryNotValid(directory: target))
        }
        
        let defineExplorable: (String) -> Result<[Explorable], Error> = { [unowned self] filename in
            let filePath = self.target(path: target, suffix: filename)
            let isCurrentFindingIsFile = self.isFile(path: filePath)
            
            guard let isFile = isCurrentFindingIsFile.successValue else {
                return .failure(isCurrentFindingIsFile.failureValue!)
            }
            
            guard !isFile else {
                let filenameWithoutExtension = filename.withoutExtension()
                let fileExtension = filename.withoutPrefix(filenameWithoutExtension + ".")
                let attributes = try? self.fileManager.attributesOfItem(atPath: filePath)
                
                let file = File(name: filenameWithoutExtension, content: try? String(contentsOfFile: filePath, encoding: .utf8), extension: fileExtension, attributes: attributes)
                return .success([file])
            }
            
            guard isFolderIncluded else {
                return .success([])
            }
            
            let attributes = try? self.fileManager.attributesOfItem(atPath: filePath)
            
            guard isRecursive else {
                let folder = Folder(name: filename, contents: [], attributes: attributes)
                
                return .success([folder])
            }
            
            // recursivly scan throught folder, until no folder found
            let recursiveScanFolder = self.list(at: filePath, withFolder: isFolderIncluded, isRecursive: isRecursive)
            
            guard let recursiveExplorables = recursiveScanFolder.successValue else {
                return .failure(recursiveScanFolder.failureValue!)
            }
            
            let folder = Folder(name: filename, contents: recursiveExplorables, attributes: attributes)
        
            return .success([folder])
        }
        
        return findings.map { defineExplorable($0) }.reduce(.success([])) { (previousResult, currentResult) -> Result<[Explorable], Error> in
            if previousResult.failureValue != nil || currentResult.failureValue != nil {
                return previousResult
            }
            return .success(previousResult.successValue! + currentResult.successValue!)
        }
    }
}
