import Foundation

open class StubManager {
    open static func load(_ filename: String) -> URL? {
        let filenameWithoutExtension = filename.components(separatedBy: ".").first!
        let fileExtension = filename.components(separatedBy: ".").last!
        
        if let bundlePath = Bundle.main.path(forResource: "Stubs", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath),
            let path = bundle.path(forResource: filenameWithoutExtension, ofType: fileExtension) {
            return URL(fileURLWithPath: path)
        } else {
            return nil
        }
    }
    
    open static func folder(_ name: String) -> URL? {
        if let bundlePath = Bundle.main.path(forResource: "Stubs", ofType: "bundle") {
            return URL(fileURLWithPath: bundlePath).appendingPathComponent(name)
        } else {
            return nil
        }
    }
}
