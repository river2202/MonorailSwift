import XCTest

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
}
