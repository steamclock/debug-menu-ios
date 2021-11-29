// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DebugMenu",
    platforms: [
        .iOS(.v13), .macOS(.v10_14)
    ],
    products: [
        .library(
            name: "DebugMenu",
            targets: ["DebugMenu"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "DebugMenu",
            path: "DebugMenu/DebugMenu")
    ]
)
