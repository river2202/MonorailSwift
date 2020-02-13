//
//  Monorail_OC.swift
//  MonorailSwift
//
//  Created by River Huang on 13/2/20.
//  Copyright © 2020 monitolab. All rights reserved.
//

import Foundation

public extension Monorail_OC {
    @objc public static func oc_enableLogger() {
        Monorail.enableLogger()
    }
    
    @objc public static func oc_writeLog() {
        Monorail.writeLog()
    }
}

