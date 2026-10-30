// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DebugMenu",
    platforms: [
        .iOS(.v15),
        // Declared only so `swift test` runs the model tests on a Mac. The SwiftUI layer is iOS only.
        .macOS(.v12)
    ],
    products: [
        .library(name: "DebugMenu", targets: ["DebugMenu"])
    ],
    targets: [
        .target(name: "DebugMenu"),
        .testTarget(name: "DebugMenuTests", dependencies: ["DebugMenu"])
    ],
    swiftLanguageModes: [.v6]
)
