/**
 An abstraction for any path related value used on Explorer
 
 For now used to abstract `Folder` and `File`
 */
public protocol Explorable {}

public struct Folder: Explorable {
    public let name: String
    public let contents: [Explorable]
    
    public init(name: String, contents: [Explorable]) {
        self.name = name
        self.contents = contents
    }
}

public struct Directory: Explorable {
    public let name: String
}

public struct File: Explorable {
    public let name: String
    public let content: String?
    
    public init(name: String, content: String?) {
        self.name = name
        self.content = content
    }
}
