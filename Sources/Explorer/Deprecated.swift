@available(*, deprecated)
public struct SingleFileOperation {
    public let file: File
    public let path: String
    
    public init(file: File, path: String) {
        self.file = file
        self.path = path
    }
}

@available(*, deprecated)
public struct BatchFileOperation {
    public let files: [File]
    public let path: String
    
    public init(files: [File], path: String) {
        self.files = files
        self.path = path
    }
}

@available(*, deprecated)
public struct SingleFolderOperation {
    public let folder: Folder
    public let path: String
    
    public init(folder: Folder, path: String) {
        self.folder = folder
        self.path = path
    }
}

@available(*, deprecated)
public struct BatchFolderOperation {
    public let folders: [Folder]
    public let path: String
    
    public init(folders: [Folder], path: String) {
        self.folders = folders
        self.path = path
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
    @available(*, deprecated message: "use write with `Explorable`")
    @discardableResult
    public func write(operation: SingleFileOperation, writingStrategy: WriteStrategy = .safe) -> Result<SingleFileOperation, Error> {
        guard operation.path.isNotEmpty else {
            return .failure(ExplorerError.pathDidNotExist(path: operation.path))
        }
        
        guard operation.file.name.isNotEmpty else {
            return .failure(ExplorerError.fileNotValid(file: operation.file.name))
        }
        
        let `extension` = operation.file.extension == nil ? "" : "." + operation.file.extension!
        let target = self.target(path: operation.path, suffix: operation.file.name + `extension`)
        
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
    @available(*, deprecated message: "use write with `Explorable`")
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
    @available(*, deprecated message: "use write with `Explorable`")
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
    @available(*, deprecated message: "use write with `Explorable`")
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
    Scan directory at path, will return the content inside it
    
    - Parameters:
       - path: Path to scan
       - withFolder: Also Scan folder or not
       - isRecursive: will include content inside folder
    
    - Returns: Result of Explorables
    */
    @available(*, deprecated, renamed: "read")
    public func list(at path: String, withFolder isFolderIncluded: Bool, isRecursive: Bool) -> Result<[Explorable], Error> {
        read(at: path, withFolder: isFolderIncluded, isRecursive: isRecursive)
    }
}
