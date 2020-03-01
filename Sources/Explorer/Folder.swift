public struct Folder {
    public let name: String
    public let files: [File]
    
    public init(name: String, files: [File]) {
        self.name = name
        self.files = files
    }
}
