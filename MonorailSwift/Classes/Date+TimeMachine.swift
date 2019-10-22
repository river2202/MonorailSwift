
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
