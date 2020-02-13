import XCTest
import MonorailSwift

#if MOCK_TEST
private var mockTest = true
#else
private var mockTest = false
#endif

extension XCTestCase {
    public func waitUntil(message: String? = nil, timeout: TimeInterval = 1, file: StaticString = #file, line: UInt = #line, action: @escaping (@escaping () -> Void) -> Void) {

        let exception = expectation(description: "\(message ?? #function) at \(file):\(line)")

        action {
            print("action:\(file), \(line)")
            exception.fulfill()
        }

        waitForExpectations(timeout: timeout) { error in
            guard let error = error else {
                return
            }

            XCTFail("Timeout with error: \(error)", file: file, line: line)
        }
    }
    
    func wait(for duration: TimeInterval = 0.1) {
        let waitExpectation = expectation(description: "Waiting")
        
        let when = DispatchTime.now() + duration
        DispatchQueue.main.asyncAfter(deadline: when) {
            waitExpectation.fulfill()
        }
        
        // We use a buffer here to avoid flakiness with Timer on CI
        waitForExpectations(timeout: duration + 0.5)
    }
    
    var isMockTest: Bool {
        return mockTest
    }
    
    @discardableResult
    func enableMockTest() -> Self {
        mockTest = true
        setupMonorail()
        return self
    }
    
    @discardableResult
    func disableMockTest() -> Self {
        mockTest =  false
        setupMonorail()
        return self
    }
    
    func setupMonorail() {
        Monorail.enableLogger()
        Monorail.writeLog(to: name)
        
        if isMockTest {
            guard let stubFile = StubManager.load(name+".json", hostBundle: Bundle(for: Self.self)) else {
                print("No stub file for test \(name).")
                Monorail.disableReader()
                return
            }
            
            Monorail.enableReader(from: stubFile)
        } else {
            Monorail.disableReader()
        }
    }
    
    override open func setUp() {
        #if MOCK_TEST
        mockTest = true
        #else
        mockTest = false
        #endif
        
        setupMonorail()
    }
}
