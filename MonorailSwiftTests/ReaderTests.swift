
import Quick
import Nimble
@testable import MonorailSwift

class ReaderTests: QuickSpec {
    
    override func spec() {
        
        describe("Reader") {
            it("read interactions, start time, and user variables from file") {
                let reader = APIServiceReader.init(file: StubManager.load("MonorailTest/ReaderTests.json")!)
                
                expect(reader.interactions.count).to(equal(4), description: "should read correct interaction number")
                expect(reader.getConsumerVariables(key: "token") as? String).to(equal("JOxMrQ0A(a2SqBisygFCUA))"), description: "expect to read consumer variable correctly")
                expect(reader.startTime).to(equal("2018-11-25T08:58:37.354+11:00".date(timeStampFormat)), description: "expect to read start time correctly to use when set time travel to this time when log file recorded")
            }
            
            it("support file and id reference") {
                
                let testData = [
                    StubManager.load("MonorailTest/Monorail-reference-test.json"),
                    StubManager.load("MonorailTest/subfolder/Monorail-reference-subfolder-test.json")
                ]
                
                for monorailFile in testData {
                    let reader = APIServiceReader.init(files: [monorailFile].compactMap { $0 })
                    expect(reader.interactions.count) == 4
                    guard reader.interactions.count == 4 else { return }
                    
                    expect(reader.interactions.first?.id) == "Interaction_01"
                    expect(reader.interactions.first?.method) == "GET"
                    expect(reader.interactions.first?.responseObjects()?.0.statusCode) == 200
                    
                    expect(reader.interactions[1].id) == "Interaction_02"
                    expect(reader.interactions[1].method) == "GET"
                    expect(reader.interactions[1].responseObjects()?.0.statusCode) == 200
                    expect(reader.interactions[1].timeElapsed) == 1.0
                    expect(reader.interactions[1].timeElapsedEnabled) == true
                    
                    expect(reader.interactions[2].id) == "Interaction_03"
                    expect(reader.interactions[2].method) == "POST"
                    expect(reader.interactions[2].responseObjects()?.0.statusCode) == 403
                    
                    expect(reader.interactions[2].timeElapsed) == 2.0
                    expect(reader.interactions[2].timeElapsedEnabled) == false
                    
                    expect(reader.interactions[3].id) == "Interaction_04"
                    expect(reader.interactions[3].method == nil) == true
                    expect(reader.interactions[3].responseObjects()?.0.statusCode == nil) == true
                    
                    expect(reader.consumerVariables["value1"] as? String) == "value1"
                    expect(reader.consumerVariables["value2"] as? String) == "value2"
                    
                    expect(reader.interactions[3].timeElapsed) == 3.0
                    expect(reader.interactions[3].timeElapsedEnabled) == false
                }
            }
            
            it("support external file reference based on some other folder") {
                
            }
            
            it("delegate works correctly ...") {
                
            }
            
            
            
            
            
        }
        
    }
}
