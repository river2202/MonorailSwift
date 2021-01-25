import XCTest
@testable import MonorailSwift

class MockOutput: MonorailDebugOutput {
    var logs = [String]()
    func log(_ message: String) {
        print(message)
        logs.append(message)
    }
    
    func reset() {
        logs.removeAll()
    }
}

class LoggerTests: XCTestCase {
    
    func testLogGetRequest() {
        let mockLogger = MockOutput()
        Monorail.enableLogger(output: mockLogger)
        enableReader()
        
        waitUntil(message: "Download apple.com home page", timeout: 3) { done in
            let url = URL(string: "https://apple.com/index.html")!
            var request = URLRequest(url: url)
                       request.addValue("12345678901", forHTTPHeaderField: "header1")
                       request.addValue("12345678902", forHTTPHeaderField: "Authorization")
                       request.addValue("12345678903", forHTTPHeaderField: "x-key")
                       request.addValue("12345678904", forHTTPHeaderField: "token")
            
            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                XCTAssertNotNil(data, "No data was downloaded.")
                XCTAssertEqual(mockLogger.logs.count, 2)
                XCTAssertTrue(mockLogger.logs.first?.contains("SequenceId: 1") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("GET https://apple.com/index.html") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("header1 : 12345678901") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("Authorization : ****") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("x-key : 12345678903") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("token : 12345678904") ?? false)
                
                print("\(mockLogger.logs.first!)")
                
                XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("SequenceId: 1") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("TimeElapsed: 1") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("\"name\" : \"Apple.come\"") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("Date : Tue, 23 Apr 2019 03:11:11 GMT") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("mocked : true") ?? false)

                print("\(mockLogger.logs.last!)")
                
                done()
            }
            dataTask.resume()
        }
    }
    
    func testLoggerMaskSecretsWithDefaultMaskSecretKeys() {
        let oldKeys = Monorail.secretsKeys
        Monorail.secretsKeys.append("x-key")
        Monorail.secretsKeys.append("token")

        let mockLogger = MockOutput()
        Monorail.enableLogger(output: mockLogger)
        enableReader()
        
        waitUntil(message: "Download apple.com home page", timeout: 3) { done in
            let url = URL(string: "https://login.apple.com.au/keys")!
            var request = URLRequest(url: url)
                       request.addValue("12345678901", forHTTPHeaderField: "header1")
                       request.addValue("12345678902", forHTTPHeaderField: "Authorization")
                       request.addValue("12345678903", forHTTPHeaderField: "x-key")
                       request.addValue("12345678904", forHTTPHeaderField: "token")
            
            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                XCTAssertNotNil(data, "No data was downloaded.")
                XCTAssertEqual(mockLogger.logs.count, 2)
                XCTAssertTrue(mockLogger.logs.first?.contains("SequenceId: 1") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("Request: GET https://login.apple.com.au/keys") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("header1 : 12345678901") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("Authorization : ****") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("x-key : ****") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("token : ****") ?? false)
                
                print("\(mockLogger.logs.first!)")
                XCTAssertTrue(mockLogger.logs.last?.contains("Response: GET /keys") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("\"name\" : \"Apple.come\"") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("\"token\" : \"****\"") ?? false)
                                
                print("\(mockLogger.logs.last!)")
                
                done()
            }
            dataTask.resume()
        }
        
        Monorail.secretsKeys = oldKeys
    }
    
    func testLoggerMaskSecretsWithCustomizedSecretKeys() {
        let oldKeys = Monorail.secretsKeys
        Monorail.secretsKeys.append("x-key")
        Monorail.secretsKeys.append("token")

        let mockLogger = MockOutput()
        let mask = "123*******mask"
        Monorail.enableLogger(output: mockLogger, secretKeys: ["x-key", "token"], secretMask: {_, _ in mask})
        enableReader()
        
        waitUntil(message: "Download apple.com home page", timeout: 3) { done in
            let url = URL(string: "https://login.apple.com.au/keys")!
            var request = URLRequest(url: url)
                       request.addValue("12345678901", forHTTPHeaderField: "header1")
                       request.addValue("12345678902", forHTTPHeaderField: "Authorization")
                       request.addValue("12345678903", forHTTPHeaderField: "x-key")
                       request.addValue("12345678904", forHTTPHeaderField: "token")
            
            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                XCTAssertNotNil(data, "No data was downloaded.")
                XCTAssertEqual(mockLogger.logs.count, 2)
                XCTAssertTrue(mockLogger.logs.first?.contains("SequenceId: 1") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("Request: GET https://login.apple.com.au/keys") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("header1 : 12345678901") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("Authorization : 12345678902") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("x-key : \(mask)") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("token : \(mask)") ?? false)
                
                print("\(mockLogger.logs.first!)")
                XCTAssertTrue(mockLogger.logs.last?.contains("Response: GET /keys") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("\"name\" : \"Apple.come\"") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("\"token\" : \"\(mask)\"") ?? false)
                                
                print("\(mockLogger.logs.last!)")
                
                done()
            }
            dataTask.resume()
        }
        
        Monorail.secretsKeys = oldKeys
    }

    func testLoggerFilter() {
        let mockLogger = MockOutput()
        enableReader()
        
        // no filter
        Monorail.enableLogger(output: mockLogger)
        
        getUrl(urlString: "https://apple.com/index.html", waitTime: 1)
        getUrl(urlString: "https://apple.com.au/index.html")
        
        XCTAssertEqual(mockLogger.logs.count, 4)
        print(mockLogger.logs)
        XCTAssertTrue(mockLogger.logs.first?.contains("GET https://apple.com/index.html") ?? false)
        XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
        
        // black list
        mockLogger.reset()
        Monorail.enableLogger(output: mockLogger, filter: .blacklist(["https://apple.com/"]))
        
        getUrl(urlString: "https://apple.com/index.html")
        getUrl(urlString: "https://apple.com.au/index.html")
        
        XCTAssertEqual(mockLogger.logs.count, 2)
        XCTAssertTrue(mockLogger.logs.first?.contains("GET https://apple.com.au/index.html") ?? false)
        XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
        
        // white list
        mockLogger.reset()
        Monorail.enableLogger(output: mockLogger, filter: .whitelist(["https://apple.com/"]))
        
        getUrl(urlString: "https://apple.com/index.html")
        getUrl(urlString: "https://apple.com.au/index.html")
        
        XCTAssertEqual(mockLogger.logs.count, 2)
        XCTAssertTrue(mockLogger.logs.first?.contains("GET https://apple.com/index.html") ?? false)
        XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
    }
    
    func testLoggerFilterRegex() {
        let mockLogger = MockOutput()
        enableReader()
        
        // black list
        mockLogger.reset()
        Monorail.enableLogger(output: mockLogger, filter: .blacklist(["https://apple.com/"]))
        
        getUrl(urlString: "https://apple.com/index.html")
        sleep(1)
        getUrl(urlString: "https://apple.com.au/index.html")
        sleep(1)
        
        XCTAssertEqual(mockLogger.logs.count, 2)
        XCTAssertTrue(mockLogger.logs.first?.contains("GET https://apple.com.au/index.html") ?? false)
        XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
        
        // white list
        mockLogger.reset()
        Monorail.enableLogger(output: mockLogger, filter: .whitelist(["https://apple.com/"]))
        
        getUrl(urlString: "https://apple.com/index.html")
        sleep(1)
        getUrl(urlString: "https://apple.com.au/index.html")
        sleep(1)
        
        XCTAssertEqual(mockLogger.logs.count, 2)
        XCTAssertTrue(mockLogger.logs.first?.contains("GET https://apple.com/index.html") ?? false)
        XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
    }
    
    func testMonorailInteractionFilter() {
        let blacklist = MonorailInteractionFilter.blacklist(["https://apple.com/"])
        XCTAssertTrue(blacklist.isFiltered("https://apple.com/index.html"))
        XCTAssertFalse(blacklist.isFiltered("https://apple.com.au/index.html"))
        
        let whitelist = MonorailInteractionFilter.whitelist(["https://apple.com/"])
        XCTAssertFalse(whitelist.isFiltered("https://apple.com/index.html"))
        XCTAssertTrue(whitelist.isFiltered("https://apple.com.au/index.html"))
    }
    
    func testStringContainsRegex() {
        
        let testData = [
            ("https://api.apple.com/index.html", "apple.com", true),
            ("https://api.apple.com/index.html", ".*apple.com", true),
            ("https://apple.com/index.html", ".*apple.com", true),
            ("https://apple.com.au/index.html", ".*apple.com", true),
            ("https://login.apple.com/index.html", ".*apple.com.au", false),
            ("https://login.apple.com.au/index.html", ".*apple.com.au", true),
            ("https://login.apple.com.au/index.html", "https?://.*apple.com.au", true),
            ("http://login.apple.com.au/index.html", "https?://.*apple.com.au", true),
        ]
        
        for (value, regex, expectResult) in testData {
            XCTAssertEqual(value.contains(regexString: regex), expectResult, "\(value) should\(expectResult ? "" : "n't") contains \(regex)")
        }
    }
    
    func testStringContainsWildcard() {
        
        let testData = [
            ("https://api.apple.com/index.html", "apple.com", true),
            ("https://api.apple.com/index.html", "*apple.com*", true),
            ("https://apple.com/index.html", "*apple.com*", true),
            ("https://apple.com.au/index.html", "*apple.com*", true),
            ("https://login.apple.com/index.html", "*apple.com.au*", false),
            ("https://login.apple.com.au/index.html", "*apple.com.au*", true),
            ("https://login.apple.com.au/index.html", "http*://*apple.com.au*", true),
            ("http://login.apple.com.au/index.html", "http*://*apple.com.au*", true),
        ]
        
        for (value, wildcardString, expectResult) in testData {
            XCTAssertEqual(value.contains(wildcardString: wildcardString), expectResult, "\(value) should\(expectResult ? "" : "n't") contains \(wildcardString)")
        }
        
        // More information:
        // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Predicates/Articles/pSyntax.html?#//apple_ref/doc/uid/TP40001795-215868
        // LIKE
        // The left hand expression equals the right-hand expression: ? and * are allowed as wildcard characters, where ? matches 1 character and * matches 0 or more characters.
    }
    
    func testMonorailInteractionFilterRegex() {
        let blacklist = MonorailInteractionFilter.blacklist(["api.apple.com.au"])
        XCTAssertFalse(blacklist.isFiltered("https://apple.com/index.html"))
        XCTAssertFalse(blacklist.isFiltered("https://apple.com.au/index.html"))
        XCTAssertTrue(blacklist.isFiltered("http://api.apple.com.au/A"))
        XCTAssertTrue(blacklist.isFiltered("https://api.apple.com.au/A"))
        XCTAssertTrue(blacklist.isFiltered("https://api.apple.com.au/B"))
        
        let whitelist = MonorailInteractionFilter.whitelist(["https://apple.com/"])
        XCTAssertFalse(whitelist.isFiltered("https://apple.com/index.html"))
        XCTAssertTrue(whitelist.isFiltered("https://apple.com.au/index.html"))
    }
    
    private func enableReader() {
        guard let testFileUrl = StubManager.load("MonorailTest/testLogGetRequest.json", hostBundle: Bundle(for: LoggerTests.self)) else {
            return XCTFail("Stub file missing")
        }
        Monorail.enableReader(from: testFileUrl)
    }
    
    private func getUrl(urlString: String, waitTime: TimeInterval = 0.1) {
        guard let url = URL(string: urlString) else {
            return XCTFail("Ilegal urlString: \(urlString)")
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, _, _) in
            XCTAssertNotNil(data, "No data was downloaded.")
        }
        
        dataTask.resume()
        wait(for: waitTime)
    }
    
    func testGetIDAndTimeElapsedLog() throws {
        let data: [(String?, TimeInterval?, String, String)] = [
            (nil, nil, "", "empty as both nil"),
            ("a", 10, "SequenceId: a\nTimeElapsed: 10.0s\n", "show both"),
            (nil, 10, "TimeElapsed: 10.0s\n", "show only time"),
            ("a", nil, "SequenceId: a\n", "show only id"),
        ]
        
        data.forEach { (id, timeElapsed, expected, message) in
            XCTAssertEqual(APIServiceLogger.getLog(id: id, timeElapsed: timeElapsed), expected, message)
        }
    }
    
    func testLeanLog() {
        let mockLogger = MockOutput()
        Monorail.enableLogger(output: mockLogger, logHeader: ["Authorization"])
        enableReader()
        
        waitUntil(message: "Download apple.com home page", timeout: 3) { done in
            let url = URL(string: "https://apple.com/index.html")!
            var request = URLRequest(url: url)
                       request.addValue("12345678901", forHTTPHeaderField: "header1")
                       request.addValue("12345678902", forHTTPHeaderField: "Authorization")
                       request.addValue("12345678903", forHTTPHeaderField: "x-key")
                       request.addValue("12345678904", forHTTPHeaderField: "token")
            
            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                XCTAssertNotNil(data, "No data was downloaded.")
                XCTAssertEqual(mockLogger.logs.count, 2)
                XCTAssertTrue(mockLogger.logs.first?.contains("SequenceId: 1") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("GET https://apple.com/index.html") ?? false)
                XCTAssertTrue(mockLogger.logs.first?.contains("Authorization : ****") ?? false)
                XCTAssertFalse(mockLogger.logs.first?.contains("x-key : 12345678903") ?? true)
                XCTAssertFalse(mockLogger.logs.first?.contains("token : 12345678904") ?? true)
                XCTAssertTrue(mockLogger.logs.first?.contains("Headers:") ?? false)
                
                print("\(mockLogger.logs.first!)")
                
                XCTAssertTrue(mockLogger.logs.last?.contains("Status: 200") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("SequenceId: 1") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("TimeElapsed: 1") ?? false)
                XCTAssertTrue(mockLogger.logs.last?.contains("\"name\" : \"Apple.come\"") ?? false)
                XCTAssertFalse(mockLogger.logs.last?.contains("Date : Tue, 23 Apr 2019 03:11:11 GMT") ?? true)
                XCTAssertFalse(mockLogger.logs.last?.contains("mocked : true") ?? true)
                XCTAssertFalse(mockLogger.logs.last?.contains("X-Content-Type-Options") ?? true)
                XCTAssertFalse(mockLogger.logs.last?.contains("Headers:") ?? true)
                

                print("\(mockLogger.logs.last!)")
                
                done()
            }
            dataTask.resume()
        }
    }
}
