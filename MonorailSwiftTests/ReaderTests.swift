import XCTest
@testable import MonorailSwift

class ReaderTests: XCTestCase {
    
    func testReader() {
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderTests.json", hostBundle: Bundle(for: ReaderTests.self))!)
        XCTAssertEqual(reader.interactions.count, 4, "should read correct interaction number")
        XCTAssertEqual(reader.getConsumerVariables(key: "token") as? String, "JOxMrQ0A(a2SqBisygFCUA))", "expect to read consumer variable correctly")
        XCTAssertEqual(reader.startTime, "2018-11-25T08:58:37.354+11:00".date(timeStampFormat), "expect to read start time correctly to use when set time travel to this time when log file recorded")
        
    }
    
    func   testReaderFileAndIDReference() {
        
        let hostBundle = Bundle(for: Self.self)
        
        let testData = [
            StubManager.load("MonorailTest/Monorail-reference-test.json", hostBundle: hostBundle),
            StubManager.load("MonorailTest/subfolder/Monorail-reference-subfolder-test.json", hostBundle: hostBundle)
        ]
        
        for monorailFile in testData {
            let reader = APIServiceReader.init(files: [monorailFile].compactMap { $0 })
            XCTAssertEqual(reader.interactions.count, 4)
            guard reader.interactions.count == 4 else { return }
            
            XCTAssertEqual(reader.interactions.first?.id, "Interaction_01")
            XCTAssertEqual(reader.interactions.first?.method, "GET")
            XCTAssertEqual(reader.interactions.first?.responseObjects().0?.statusCode, 200)
            
            XCTAssertEqual(reader.interactions[1].id, "Interaction_02")
            XCTAssertEqual(reader.interactions[1].method, "GET")
            XCTAssertEqual(reader.interactions[1].responseObjects().0?.statusCode, 200)
            XCTAssertEqual(reader.interactions[1].timeElapsed, 1.0)
            XCTAssertEqual(reader.interactions[1].timeElapsedEnabled, true)
            
            XCTAssertEqual(reader.interactions[2].id, "Interaction_03")
            XCTAssertEqual(reader.interactions[2].method, "POST")
            XCTAssertEqual(reader.interactions[2].responseObjects().0?.statusCode, 403)
            
            XCTAssertEqual(reader.interactions[2].timeElapsed, 2.0)
            XCTAssertEqual(reader.interactions[2].timeElapsedEnabled, false)
            
            XCTAssertEqual(reader.interactions[3].id, "Interaction_04")
            XCTAssertEqual(reader.interactions[3].method == nil, true)
            XCTAssertEqual(reader.interactions[3].responseObjects().0?.statusCode == nil, true)
            
            XCTAssertEqual(reader.consumerVariables["value1"] as? String, "value1")
            XCTAssertEqual(reader.consumerVariables["value2"] as? String, "value2")
            
            XCTAssertEqual(reader.interactions[3].timeElapsed, 3.0)
            XCTAssertEqual(reader.interactions[3].timeElapsedEnabled, false)
        }
    }
    
    func testReadeArrayResponse() {
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderArrayResponseTests.json", hostBundle: Bundle(for: Self.self))!)
        
       let response = reader.interactions[0].responseObjects()
        XCTAssertEqual(response.0?.statusCode, 200)
        XCTAssertNotNil(response.1)
    }
    
    func testReadeStringValueBoday() {
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderStringBodyTests.json", hostBundle: Bundle(for: Self.self))!)
        
        let response = reader.interactions[0].responseObjects()
        XCTAssertEqual(response.0?.statusCode, 200)
        XCTAssertNotNil(response.1)
        if let data = response.1 {
            XCTAssertEqual(String(data: data, encoding: .utf8), "StringValue")
        }
    }
}
