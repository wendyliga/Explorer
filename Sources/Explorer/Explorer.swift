import Foundation
import SwiftKit

public class Explorer {
    /**
     Write Operation Callback
     
     Parameter target name: file name Write Operation is currently working on
     */
    public typealias WriteOperationCurrentProgress = ((String) -> Void)
    
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
    private static func target(path: String, suffix: String) -> String {
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
        let target = Explorer.target(path: operation.path, suffix: operation.file.name)
        
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
        let target = Explorer.target(path: operation.path, suffix: operation.folder.name)
        
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
    public func write(
        operation: SingleFileOperation,
        writingStrategy: WriteStrategy = .safe,
        currentProgressCallback progressCallback: WriteOperationCurrentProgress? = nil
    ) -> Result<SingleFileOperation, Error> {
        let callback: () -> Void = {
            progressCallback?(operation.file.name)
        }
        
        guard operation.path.isNotEmpty else {
            return .failure(FileError.pathDidNotExist(path: operation.path))
        }
        
        guard operation.file.name.isNotEmpty else {
            return .failure(FileError.fileNotValid(file: operation.file.name))
        }
        
        let target = Explorer.target(path: operation.path, suffix: operation.file.name)
        
        if writingStrategy == .safe && fileManager.fileExists(atPath: target) == true {
            return .failure(FileError.fileExist(file: target))
        }
        
        if writingStrategy == .skippable && fileManager.fileExists(atPath: target) == true {
            // execute callback
            callback()
            
            return .success(operation)
        }
        
        // default create file will overwrite the target
        guard fileManager.createFile(atPath: target, contents: operation.file.content?.data(using: .utf8), attributes: nil) else {
            return .failure(FileError.writeError(file: target))
        }
        
        // execute callback
        callback()
        
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
    public func write(
        operation: BatchFileOperation,
        writingStrategy: WriteStrategy = .safe,
        currentProgressCallback progressCallback: WriteOperationCurrentProgress? = nil
    ) -> Result<BatchFileOperation, Error> {
        guard operation.path.isNotEmpty else {
            return .failure(FileError.pathDidNotExist(path: operation.path))
        }
        
        let results = operation.files.map {
            write(operation: SingleFileOperation(file: $0, path: operation.path), writingStrategy: writingStrategy, currentProgressCallback: progressCallback)
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
    public func write(
        operation: SingleFolderOperation,
        writingStrategy: WriteStrategy,
        currentProgressCallback progressCallback: WriteOperationCurrentProgress? = nil
    ) -> Result<SingleFolderOperation, Error> {
        guard operation.path.isNotEmpty else {
            return .failure(FileError.pathDidNotExist(path: operation.path))
        }
        
        guard operation.folder.name.isNotEmpty else {
            return .failure(FileError.directoryNotValid(directory: operation.folder.name))
        }
        
        let target = Explorer.target(path: operation.path, suffix: operation.folder.name)
        
        do {
            try fileManager.createDirectory(atPath: target, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            return .failure(error)
        }
        
        let batchFileOperation = BatchFileOperation(files: operation.folder.files, path: target)
        
        if case .failure(let error) = write(operation: batchFileOperation, writingStrategy: writingStrategy, currentProgressCallback: progressCallback) {
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
    public func write(
        operation: BatchFolderOperation,
        writingStrategy: WriteStrategy,
        currentProgressCallback progressCallback: WriteOperationCurrentProgress? = nil
    ) -> Result<BatchFolderOperation, Error> {
        guard operation.path.isNotEmpty else {
            return .failure(FileError.pathDidNotExist(path: operation.path))
        }
        
        let results = operation.folders.map {
            write(operation: SingleFolderOperation(folder: $0, path: operation.path), writingStrategy: writingStrategy, currentProgressCallback: progressCallback)
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
    public var currentDirectoryPath: String {
        fileManager.currentDirectoryPath
    }
    
    public func isFileExist(path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }
}
