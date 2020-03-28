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
        guard fileManager.createFile(atPath: target, contents: operation.file.content?.data(using: .utf8), attributes: nil) else {
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
        
        let writeFailureResults = results.compactMap{ $0.nonSuccessResult }
        
        // revert if failed
        if writeFailureResults.isNotEmpty {
            
            // delete all success file
            results.compactMap{ $0.nonFailureResult }
                .forEach{ delete(operation: $0.value) }
            
            let errors = writeFailureResults.map { result -> Error in
                return result.error
            }
            
            return .failure(GeneralError.multipleError(errors))
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
            try fileManager.createDirectory(atPath: target, withIntermediateDirectories: true, attributes: nil)
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
        
        let writeFailureResults = results.compactMap{ $0.nonSuccessResult }
        
        // revert if failed
        if writeFailureResults.isNotEmpty {
            
            // delete all success one
            results.compactMap{ $0.nonFailureResult }
                .forEach{ delete(operation: $0.value) }
            
            let errors = writeFailureResults.map { result -> Error in
                return result.error
            }
            
            return .failure(GeneralError.multipleError(errors))
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
    public func list(at path: String, withFolder isFolderIncluded: Bool, isRecursive: Bool) -> Result<[Explorable], Error> {
        let target = self.target(path: path, suffix: "")
        
        guard let findings = try? fileManager.contentsOfDirectory(atPath: target) else {
            return .failure(ExplorerError.directoryNotValid(directory: target))
        }
        
        var explorables = [Explorable]()
        
        for finding in findings {
            let filePath = self.target(path: target, suffix: finding)

            let isCurrentFindingIsFile = isFile(path: filePath)

            if case let .failure(error) = isCurrentFindingIsFile {
                return .failure(error)
            } else if case let .success(isFile) = isCurrentFindingIsFile {
                if isFile {
                    guard let fileContent = try? String(contentsOfFile: filePath, encoding: .utf8) else {
                        return .failure(ExplorerError.fileNotValid(file: finding))
                    }

                    explorables.append(File(name: finding, content: fileContent))
                } else {
                    guard isFolderIncluded else { continue }

                    if isRecursive {
                        let folderContent = list(at: filePath, withFolder: isFolderIncluded, isRecursive: isRecursive)

                        if case let .failure(error) = folderContent {
                            return .failure(error)
                        } else if case let .success(folderExplorables) = folderContent {
                            explorables.append(contentsOf: folderExplorables)
                        }
                    } else {
                        explorables.append(Folder(name: finding, contents: []))
                    }
                }
            }
        }
        
        return .success(explorables)
    }
}
