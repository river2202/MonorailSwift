// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MonorailSwift",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "MonorailSwift", targets: ["MonorailSwift"]),
        .library(name: "MonorailSwiftTools", targets: ["MonorailSwiftTools"]),
    ],
    targets: [
        .target(
            name: "MonorailSwiftObjC",
            path: "MonorailSwift/Classes",
            sources: ["NSDate+TimeMachine.m"],
            publicHeadersPath: "."
        ),
        .target(
            name: "MonorailSwift",
            dependencies: ["MonorailSwiftObjC"],
            path: "MonorailSwift/Classes",
            exclude: ["NSDate+TimeMachine.h", "NSDate+TimeMachine.m"]
        ),
        .target(
            name: "MonorailSwiftTools",
            dependencies: ["MonorailSwift"],
            path: "MonorailSwift/Helper",
            exclude: ["Monorail_OC.h", "Monorail_OC.m", "Monorail_OC.swift"]
        ),
    ]
)
