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

// The DocC plugin is only used to build the documentation site (see .github/workflows/docs.yml).
// Gate it behind an env var so it never enters consumers' dependency graphs.
if Context.environment["RIFFLE_BUILD_DOCS"] != nil {
    package.dependencies += [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ]
}
