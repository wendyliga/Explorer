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
