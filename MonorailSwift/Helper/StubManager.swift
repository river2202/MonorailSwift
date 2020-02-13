import Foundation

open class StubManager {
    public static func load(_ filename: String, bundleName: String? = "Stubs", hostBundle: Bundle? = Bundle.main) -> URL? {
        guard let hostBundle = hostBundle  else {
            return nil
        }
        
        let bundle: Bundle
        if let bundleName = bundleName, let bundlePath = hostBundle.path(forResource: bundleName, ofType: "bundle"), let subBundle = Bundle(path: bundlePath) {
            bundle = subBundle
        } else {
            bundle = hostBundle
        }
        
        if let path = bundle.path(forResource: filename, ofType: "") {
            return URL(fileURLWithPath: path)
        } else {
            return nil
        }
    }
    
  public static func folder(_ name: String, bundleName: String? = "Stubs", hostBundle: Bundle? = Bundle.main) -> URL? {
        guard let bundleName = bundleName, let hostBundle = hostBundle  else {
            return nil
        }
    
        if let bundlePath = hostBundle.path(forResource: bundleName, ofType: "bundle") {
            return URL(fileURLWithPath: bundlePath).appendingPathComponent(name)
        } else {
            return nil
        }
    }
}
