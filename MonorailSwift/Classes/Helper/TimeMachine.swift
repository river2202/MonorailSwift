
import Foundation

open class TimeMachine {
    open static let shared = TimeMachine()
    
    open var now: Date {
        #if DEBUG || TEST
        return nowRelativeToBase
        #else
        return Date()
        #endif
    }
    
    private var absoluteStartTime: Date?
    private var baseTime: Date?
    
    private var nowRelativeToBase: Date {
        guard let baseTime = baseTime, let startTime = absoluteStartTime else {
            return Date()
        }
        
        return baseTime - startTime.timeIntervalSinceNow
    }
    
    open func travelTo(_ past: Date?) {
        guard let past = past else {
            absoluteStartTime = nil
            baseTime = nil
            return
        }
        
        absoluteStartTime = Date()
        baseTime = past
    }
}
