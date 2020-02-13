import Foundation
import MonorailSwift

public extension Monorail_OC {
    @objc static func oc_enableLogger() {
        Monorail.enableLogger()
    }
    
    @objc static func oc_writeLog() {
        Monorail.writeLog()
    }
}

