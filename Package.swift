// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Riffle",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "Riffle", targets: ["Riffle"])
    ],
    targets: [
        .target(name: "Riffle"),
        .testTarget(name: "RiffleTests", dependencies: ["Riffle"])
    ],
    swiftLanguageModes: [.v6]
)
