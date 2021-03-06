import XCTest
@testable import MonorailSwift

class ReaderTests: XCTestCase {
    
    func testReader() {
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderTests.json", hostBundle: Bundle(for: ReaderTests.self))!)
        XCTAssertEqual(reader.interactions.count, 4, "should read correct interaction number")
        XCTAssertEqual(reader.getConsumerVariables(key: "token") as? String, "JOxMrQ0A(a2SqBisygFCUA))", "expect to read consumer variable correctly")
        XCTAssertEqual(reader.startTime, "2018-11-25T08:58:37.354+11:00".date(timeStampFormat), "expect to read start time correctly to use when set time travel to this time when log file recorded")
        
        XCTAssertEqual(reader.interactions.first?.responseHeader?["Date"] as? String, "Thu, 01 Nov 2018 23:02:32 GMT", "should read correct header")
        XCTAssertEqual(reader.interactions.first?.responseObjects().0?.allHeaderFields["Date"] as? String, "Thu, 01 Nov 2018 23:02:32 GMT", "should read correct header")
    }
    
    func   testReaderFileAndIDReference() {
        
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
            XCTAssertNil(reader.interactions[2].timeElapsedEnabled)
            
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
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderArrayResponseTests.json", hostBundle: hostBundle)!)
        
       let response = reader.interactions[0].responseObjects()
        XCTAssertEqual(response.0?.statusCode, 200)
        XCTAssertNotNil(response.1)
    }
    
    func testReadeStringValueBoday() {
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderStringBodyTests.json", hostBundle: hostBundle)!)
        
        let response = reader.interactions[0].responseObjects()
        XCTAssertEqual(response.0?.statusCode, 200)
        XCTAssertNotNil(response.1)
        if let data = response.1 {
            XCTAssertEqual(String(data: data, encoding: .utf8), "StringValue")
        }
    }
    
    func testReadeOnlyMockedMode() {
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderStringMockedOnlyModeTests.json", hostBundle: hostBundle)!)
        
        XCTAssertEqual(reader.interactions[0].responseObjects().4, true)
        XCTAssertEqual(reader.interactions[1].responseObjects().4, false)
        XCTAssertEqual(reader.interactions[2].responseObjects().4, false)
        
        [
            ("api_mocked", APIServiceReader.Mode.all, true),
            ("api_normal", APIServiceReader.Mode.all, true),
            ("api_not_mocked", APIServiceReader.Mode.all, true),
            ("api_mocked", APIServiceReader.Mode.onlyMocked, true),
            ("api_normal", APIServiceReader.Mode.onlyMocked, false),
            ("api_not_mocked", APIServiceReader.Mode.onlyMocked, false),
            ].forEach { (api_end, readerMode, shouldIntercept) in
                let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderStringMockedOnlyModeTests.json", hostBundle: hostBundle)!, mode: readerMode)
                let request = URLRequest(url: URL(string: "https://test.com/\(api_end)")!)
                XCTAssertEqual(reader.getResponseObject(for: request).0, shouldIntercept)
        }
        
    }
    
    
    func testReaderBySequence() {
        let mockLog = MockOutput()
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderBySequenceTests.json", hostBundle: hostBundle)!, output: mockLog)
        
        (0...5).forEach { _ in
                let request = URLRequest(url: URL(string: "https://api.stackexchange.com/2.2/search")!)
                XCTAssertNotNil (reader.getResponseObject(for: request).1)
        }
        
        let id4 = mockLog.logs.filter { (log) -> Bool in
            log.contains("Found best match id: 4")
        }
        
        XCTAssertEqual(id4.count, 3)
    }
    
    func testReaderMatchRoot() {
        let mockLog = MockOutput()
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderBySequenceTests.json", hostBundle: hostBundle)!, output: mockLog)
        
        (0...5).forEach { _ in
                let request = URLRequest(url: URL(string: "https://api.stackexchange.com/")!)
                XCTAssertNotNil (reader.getResponseObject(for: request).1)
        }
        
        let id4 = mockLog.logs.filter { (log) -> Bool in
            log.contains("Found best match id: 5")
        }
        
        XCTAssertEqual(id4.count, 6)
        
        (0...5).forEach { _ in
                let request = URLRequest(url: URL(string: "https://api.stackexchange.com")!)
                XCTAssertNotNil (reader.getResponseObject(for: request).1)
        }
        
        let id5 = mockLog.logs.filter { (log) -> Bool in
            log.contains("Found best match id: 5")
        }
        
        XCTAssertEqual(id5.count, 12)
    }
    
    func testReaderMatchScheme() {
        let mockLog = MockOutput()
        let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderBySequenceTests.json", hostBundle: hostBundle)!, output: mockLog)
        
        let request = URLRequest(url: URL(string: "wss://api.stackexchange.com")!)
        XCTAssertNil (reader.getResponseObject(for: request).1)
    }
}
