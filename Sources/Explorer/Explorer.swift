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
    // TODO: support custom `Data`
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

public struct WriteResult {
    public enum Result {
        case success
        case failure(WriteError)
    }
    
    public let explorable: Explorable
    public let result: Result
}

public enum WriteError {
    case unidentifiedError
    case fileExist
    case fileNotValid
    case createFolder(Error)
}

public enum ExplorerError: Error, LocalizedError, Equatable {
    case pathDidNotExist(path: String)
    case fileExist(File)
    case fileNotValid(File)
    case directoryNotValid(Folder)
    case writeError(File)
    
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
    
    public var currentDirectoryPath: String {
        fileManager.currentDirectoryPath
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
    
    public func write(
        _ explorables: [Explorable],
        at path: String,
        writingStrategy: WriteStrategy = .safe
    ) -> Result<[WriteResult], Error> {
        guard path.isNotEmpty else {
            return .failure(ExplorerError.pathDidNotExist(path: path))
        }
        
        // final result
        var results: [WriteResult] = []
        
        for explorable in explorables {
            // handle file
            if let file = explorable as? File {
                guard file.name.isNotEmpty else {
                    return .failure(ExplorerError.fileNotValid(file))
                }
                
                let `extension` =  file.extension == nil ? "" : "." + file.extension!
                let target = self.target(path: path, suffix: file.name + `extension`)
                
                if writingStrategy == .safe && fileManager.fileExists(atPath: target) == true {
                    return .failure(ExplorerError.fileExist(file))
                }
                
                if writingStrategy == .skippable && fileManager.fileExists(atPath: target) == true {
                    let result = WriteResult(
                        explorable: file,
                        result: .failure(.fileExist)
                    )
                    results.append(result)
                    continue
                }
                
                // write file
                guard fileManager.createFile(
                    atPath: target,
                    contents: file.content?.data(using: .utf8),
                    attributes: file.attributes)
                else {
                    if writingStrategy == .skippable {
                        results.append(.init(explorable: file, result: .failure(.unidentifiedError)))
                        continue
                    }
                    
                    return .failure(ExplorerError.writeError(file))
                }
                
                results.append(.init(explorable: file, result: .success))
                continue
            }
                
            // handle folder
            else if let folder = explorable as? Folder {
                var folderResult: [WriteResult] = []
                
                guard folder.name.isNotEmpty else {
                    return .failure(ExplorerError.directoryNotValid(folder))
                }
                
                let target = self.target(path: path, suffix: folder.name)
                
                // create folder
                do {
                    try fileManager.createDirectory(
                        atPath: target,
                        withIntermediateDirectories: true,
                        attributes: folder.attributes
                    )
                } catch let error {
                    if writingStrategy == .skippable {
                        results.append(.init(explorable: folder, result: .failure(.createFolder(error))))
                        continue
                    }
                    
                    return .failure(error)
                }
                
                // write file inside folder
                let file = folder.contents
                .compactMap { $0 as? File }
                
                let writeFileResult = self.write(file, at: path, writingStrategy: writingStrategy)
                
                if let successResult = writeFileResult.successValue, writingStrategy == .skippable {
                    
                }
                
                let folders = folder.contents
                    .compactMap { $0 as? Folder }
                
                let writeFolderResult = self.write(folders, at: path, writingStrategy: writingStrategy)
                
            }
        }
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
    
    public func read(at path: String, withFolder isFolderIncluded: Bool, isRecursive: Bool) -> Result<[Explorable], Error> {
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
            let recursiveScanFolder = self.read(at: filePath, withFolder: isFolderIncluded, isRecursive: isRecursive)
            
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
