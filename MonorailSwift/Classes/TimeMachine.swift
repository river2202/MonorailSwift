
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

/*
// Add following extension to your app's main module
// to enble swift Time Machine
 
public extension Date {
    init() {
        self = NSDate() as Date
    }
    
    init(timeIntervalSinceNow: TimeInterval) {
        self = Date().addingTimeInterval(timeIntervalSinceNow)
    }
    
    var timeIntervalSinceNow: TimeInterval {
        return timeIntervalSince(Date())
    }
}
*/

