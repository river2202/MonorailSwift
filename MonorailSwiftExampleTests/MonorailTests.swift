import Quick
import Nimble
@testable import MonorailSwiftExample
@testable import MonorailSwift

class Monorail_Tests: QuickSpec {
    
    override func spec() {
        describe("Reader") {
            it("should support file and id reference") {
                
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
                    
                    expect(reader.interactions[2].id) == "Interaction_03"
                    expect(reader.interactions[2].method) == "POST"
                    expect(reader.interactions[2].responseObjects()?.0.statusCode) == 403
                    
                    expect(reader.interactions[3].id) == "Interaction_04"
                    expect(reader.interactions[3].method == nil) == true
                    expect(reader.interactions[3].responseObjects()?.0.statusCode == nil) == true
                    
                    expect(reader.consumerVariables["value1"] as? String) == "value1"
                    expect(reader.consumerVariables["value2"] as? String) == "value2"
                }
            }
        }

    }
}
