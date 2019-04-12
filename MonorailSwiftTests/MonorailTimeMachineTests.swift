
import XCTest
@testable import MonorailSwift

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

class MonorailTimeMachineTests: XCTestCase {
    
    func testTimeTravelTests() {
        let date = NSDate(timeIntervalSince1970: 946684800) // 2000-01-01
        let date2 = NSDate(timeIntervalSince1970: 946684800 + 10) // 2000-01-01
        let date3 = NSDate(timeIntervalSince1970: 946684800 + 10) as Date
        TimeMachine.shared.travel(to: date as Date)
        
        XCTAssertTrue(abs(date2.timeIntervalSinceNow - 10) < 0.01)
        XCTAssertTrue(abs(date3.timeIntervalSinceNow - 10) < 0.01)
        
        expect(Date().utc, beginWith: "2000-01-01T00:00:00")
        expect(Date(timeIntervalSinceNow: TimeInterval(10)).utc, beginWith: "2000-01-01T00:00:10")
        
        expect((NSDate() as Date).utc, beginWith: "2000-01-01T00:00:00")
        expect((NSDate(timeIntervalSinceNow: TimeInterval(10)) as Date).utc, beginWith: "2000-01-01T00:00:10")
        expect((NSDate.realNow() as Date).utc, notBeginWith: "2000-01-01")
        
        sleep(1)
        expect(Date().utc, beginWith: "2000-01-01T00:00:01")
        expect((NSDate() as Date).utc, beginWith: "2000-01-01T00:00:01")
        expect(TimeMachine.shared.realNow.utc, notBeginWith: "2000-01-01")
        expect((NSDate.realNow() as Date).utc, notBeginWith: "2000-01-01")
        
        TimeMachine.shared.travel(to: nil)
        
        expect(TimeMachine.shared.realNow.utc, notBeginWith: "2000-01-01")
        expect(Date().utc, notBeginWith: "2000-01-01")
        expect((NSDate() as Date).utc, notBeginWith: "2000-01-01")
        
        print(NSDate() as Date)
    }
}

extension Date {
    var utc: String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return dateFormatter.string(from: self)
    }
}

extension XCTestCase {
    func expect(_ string: String, beginWith prefix: String, file: StaticString = #file, line: UInt = #line) {
        if !string.hasPrefix(prefix) {
            XCTFail("\"\(string)\" not begin with \"\(prefix)\"", file: file, line: line)
        }
    }
    
    func expect(_ string: String, notBeginWith prefix: String, file: StaticString = #file, line: UInt = #line) {
        if string.hasPrefix(prefix) {
            XCTFail("\"\(string)\" begin with \"\(prefix)\"", file: file, line: line)
        }
    }
}


