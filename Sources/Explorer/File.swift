public struct File {
    public let name: String
    public let content: String?
    
    public init(name: String, content: String?) {
        self.name = name
        self.content = content
    }
}
