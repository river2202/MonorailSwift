import XCTest
@testable import MonorailSwift

class MonorailSwiftTests: XCTestCase {
    
    func testLogGetRequest() {
        let mockLogger = MockOutput()
        Monorail.enableLogger(output: mockLogger)
        
        waitUntil(message: "Call httpbin.org/get", timeout: 3) { done in
            let url = URL(string: "https://httpbin.org/get")!
            let dataTask = URLSession.shared.dataTask(with: url) { (data, _, _) in
                XCTAssertNotNil(data, "No data was downloaded.")
                XCTAssertEqual(mockLogger.logs.count, 2)
                XCTAssertTrue(mockLogger.logs.first?.contains("GET https://httpbin.org/get") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
                done()
            }
            dataTask.resume()
        }
    }
    
    func testLogGetRequest204() {
        let mockLogger = MockOutput()
        Monorail.enableLogger(output: mockLogger)
        
        waitUntil(message: "Call httpbin.org/status/204", timeout: 3) { done in
            let url = URL(string: "https://httpbin.org//status/204")!
            let dataTask = URLSession.shared.dataTask(with: url) { (data, _, _) in
                XCTAssertEqual(data?.count, 0, "0 byte data for 204.")
                XCTAssertEqual(mockLogger.logs.count, 2)
                XCTAssertTrue(mockLogger.logs.first?.contains("GET https://httpbin.org//status/204") ?? false)
                
                XCTAssertTrue(mockLogger.logs.last?.contains("Status: 204 - No Content") ?? false)
                done()
            }
            dataTask.resume()
        }
    }
    


    func testLogGetRequest404() {
        let mockLogger = MockOutput()
        Monorail.enableLogger(output: mockLogger)
        
        waitUntil(message: "Call httpbin.com/get", timeout: 3) { done in
            let url = URL(string: "https://httpbinsdfasdfasfsf.com/get")!
            let dataTask = URLSession.shared.dataTask(with: url) { (data, _, _) in
                XCTAssertNil(data, "No data for 404.")
                XCTAssertEqual(mockLogger.logs.count, 2)
                XCTAssertTrue(mockLogger.logs.first?.contains("GET https://httpbinsdfasdfasfsf.com/get") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("Error: -1003") ?? false, "NSURLErrorCannotFindHost")
                done()
            }
            dataTask.resume()
        }
    }
    
    
    func testLogPostRequest() {        
        let mockLogger = MockOutput()
        Monorail.enableLogger(output: mockLogger)
        
        waitUntil(message: "Call httpbin.org/post", timeout: 3) { done in
            let url = URL(string: "https://httpbin.org/post")!
            let body = "10".data(using: .utf8)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = body
            
            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                XCTAssertNotNil(data, "No data was downloaded.")
                XCTAssertEqual(mockLogger.logs.count, 2)
                XCTAssertTrue(mockLogger.logs.first?.contains("POST https://httpbin.org/post") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
                done()
            }
            dataTask.resume()
        }
    }
    
    
    
}
