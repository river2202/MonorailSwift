
import Foundation

open class StubManager {
    public static func load(_ filename: String) -> URL? {
        
        if let bundlePath = Bundle(for: self).path(forResource: "Stubs", ofType: "bundle"),
            let bundle = Bundle(path: bundlePath),
            let path = bundle.path(forResource: filename, ofType: "") {
            return URL(fileURLWithPath: path)
        } else {
            return nil
        }
    }
    
    public static func folder(_ name: String) -> URL? {
        if let bundlePath = Bundle.main.path(forResource: "Stubs", ofType: "bundle") {
            return URL(fileURLWithPath: bundlePath).appendingPathComponent(name)
        } else {
            return nil
        }
    }
}
