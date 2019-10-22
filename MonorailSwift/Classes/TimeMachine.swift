
import Foundation

public final class TimeMachine {
    public static let shared = TimeMachine()
    
    public var now: Date {
        return NSDate() as Date
    }
    
    var realNow: Date {
        return NSDate.realNow() as Date
    }
    
    public func travel(to past: Date?) {
        NSDate.travel(to: past)
    }
}

