import Foundation

public enum FileError: Error, LocalizedError {
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
