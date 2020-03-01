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
