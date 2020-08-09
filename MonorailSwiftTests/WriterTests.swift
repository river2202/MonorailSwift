import XCTest
@testable import MonorailSwift

class WriterTests: XCTestCase {
    
    func testWriter() {
        enableReader()
        guard let writerTestFile = Monorail.writeLog(to: "writerTestFile") else {
            return XCTFail("Create file failed!")
        }
        
        waitUntil(message: "Download apple.com home page", timeout: 3) { done in
            let url = URL(string: "https://apple.com/index.html")!
            var request = URLRequest(url: url)
            request.addValue("1234567890", forHTTPHeaderField: "header1")
            request.addValue("1234567890", forHTTPHeaderField: "Authorization")
            request.addValue("1234567890", forHTTPHeaderField: "x-key")
            request.addValue("1234567890", forHTTPHeaderField: "token")
            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                
                
                let reader = APIServiceReader.init(file: writerTestFile)
                XCTAssertEqual(reader.interactions.count, 1, "should read correct interaction number")
                
                XCTAssertEqual(reader.interactions[0].requestHeader?["header1"] as! String, "1234567890", "Should save header1")
                XCTAssertEqual(reader.interactions[0].requestHeader?["Authorization"] as! String, "****", "Should mask Authorization by default")
                XCTAssertEqual(reader.interactions[0].requestHeader?["x-key"] as! String, "1234567890", "Should save keys")
                XCTAssertEqual(reader.interactions[0].requestHeader?["token"] as! String, "1234567890", "Should save tokens")
                
                XCTAssertNil(reader.interactions[0].requestHeader?["header12"], "Should not save header12")
                
                if let timeElapsed = reader.interactions[0].timeElapsed {
                    print("timeElapsed=\(timeElapsed)")
                    XCTAssertEqual(timeElapsed, 1, accuracy: 0.1, "timeElapsed about 1s")
                } else {
                    XCTFail("Should write")
                }
                done()
            }
            dataTask.resume()
        }
        
        try? FileManager.default.removeItem(at: writerTestFile)
    }
    
    func testWriterMaskSecretsUsingDefault() {
        enableReader()
        let oldKeys = Monorail.secretsKeys
        Monorail.secretsKeys.append("x-key")
        
        guard let writerTestFile = Monorail.writeLog(to: "writerTestFile") else {
            return XCTFail("Create file failed!")
        }
        
        waitUntil(message: "Download apple.com home page", timeout: 3) { done in
            let url = URL(string: "https://apple.com/index.html")!
            var request = URLRequest(url: url)
            request.addValue("1234567890", forHTTPHeaderField: "header1")
            request.addValue("1234567890", forHTTPHeaderField: "Authorization")
            request.addValue("1234567890", forHTTPHeaderField: "x-key")
            request.addValue("1234567890", forHTTPHeaderField: "token")
            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                
                
                let reader = APIServiceReader.init(file: writerTestFile)
                XCTAssertEqual(reader.interactions.count, 1, "should read correct interaction number")
                
                XCTAssertEqual(reader.interactions[0].requestHeader?["header1"] as! String, "1234567890", "Should save header1")
                XCTAssertEqual(reader.interactions[0].requestHeader?["Authorization"] as! String, "****", "Should mask Authorization by default")
                XCTAssertEqual(reader.interactions[0].requestHeader?["x-key"] as! String, "****", "Should mask x-key")
                XCTAssertEqual(reader.interactions[0].requestHeader?["token"] as! String, "1234567890", "Should save tokens")
                
                XCTAssertNil(reader.interactions[0].requestHeader?["header12"], "Should not save header12")
                
                done()
            }
            dataTask.resume()
        }
        
        try? FileManager.default.removeItem(at: writerTestFile)
        Monorail.secretsKeys = oldKeys
    }
    
    func testWriterMaskSecrets() {
        enableReader()
        class MaskSecrets: APIServiceWriterDelegate{
            let secretKeys = ["Authorization", "x-key", "token"]
            func beforeWriteToFile(_ interaction: Interaction, writer: APIServiceWriter) {
                interaction.maskSecrets(secretKeys: secretKeys, mask: {_, _ in "****" })
            }
        }
        let maskSecrets = MaskSecrets()
        
        guard let writerTestFile = Monorail.writeLog(to: "writerTestFile", delegate: maskSecrets) else {
            return XCTFail("Create file failed!")
        }
        
        waitUntil(message: "Download apple.com home page", timeout: 3) { done in
            let url = URL(string: "https://apple.com/index.html")!
            var request = URLRequest(url: url)
            request.addValue("1234567890", forHTTPHeaderField: "header1")
            request.addValue("1234567890", forHTTPHeaderField: "Authorization")
            request.addValue("1234567890", forHTTPHeaderField: "x-key")
            request.addValue("1234567890", forHTTPHeaderField: "token")
            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                
                
                let reader = APIServiceReader.init(file: writerTestFile)
                XCTAssertEqual(reader.interactions.count, 1, "should read correct interaction number")
                
                XCTAssertEqual(reader.interactions[0].requestHeader?["header1"] as! String, "1234567890", "Should save header1")
                XCTAssertEqual(reader.interactions[0].requestHeader?["Authorization"] as! String, "****", "Should mask Authorization")
                XCTAssertEqual(reader.interactions[0].requestHeader?["x-key"] as! String, "****", "Should mask keys")
                XCTAssertEqual(reader.interactions[0].requestHeader?["token"] as! String, "****", "Should mask tokens")
                
                done()
            }
            dataTask.resume()
        }
        
        try? FileManager.default.removeItem(at: writerTestFile)
    }
    
    func testWriterMaskSecretsSolution2() {
        enableReader()
        let secretKeys = ["Authorization", "x-key", "token"]
        let mask = "********"
        guard let writerTestFile = Monorail.writeLog(to: "writerTestFile", secretKeys: secretKeys, secretMask: {_, _ in mask}) else {
            return XCTFail("Create file failed!")
        }
        
        waitUntil(message: "Download apple.com home page", timeout: 3) { done in
            let url = URL(string: "https://apple.com/index.html")!
            var request = URLRequest(url: url)
            request.addValue("1234567890", forHTTPHeaderField: "header1")
            request.addValue("1234567890", forHTTPHeaderField: "Authorization")
            request.addValue("1234567890", forHTTPHeaderField: "x-key")
            request.addValue("1234567890", forHTTPHeaderField: "token")
            let dataTask = URLSession.shared.dataTask(with: request) { (data, _, _) in
                
                
                let reader = APIServiceReader.init(file: writerTestFile)
                XCTAssertEqual(reader.interactions.count, 1, "should read correct interaction number")
                
                XCTAssertEqual(reader.interactions[0].requestHeader?["header1"] as! String, "1234567890", "Should save header1")
                XCTAssertEqual(reader.interactions[0].requestHeader?["Authorization"] as! String, mask, "Should mask Authorization")
                XCTAssertEqual(reader.interactions[0].requestHeader?["x-key"] as! String, mask, "Should mask keys")
                XCTAssertEqual(reader.interactions[0].requestHeader?["token"] as! String, mask, "Should mask tokens")
                
                done()
            }
            dataTask.resume()
        }
        
        try? FileManager.default.removeItem(at: writerTestFile)
    }
    
    
    private func enableReader() {
        guard let testFileUrl = StubManager.load("MonorailTest/testLogGetRequest.json", hostBundle: Bundle(for: LoggerTests.self)) else {
            return XCTFail("Stub file missing")
        }
        Monorail.enableReader(from: testFileUrl)
    }
}
