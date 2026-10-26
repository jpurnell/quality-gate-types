// swift-tools-version: 6.2
// legibility:description: Shared Swift types for the quality-gate ecosystem.
import PackageDescription

let package = Package(
    name: "quality-gate-types",
    platforms: [.macOS(.v14), .iOS(.v18)],
    products: [
        .library(name: "QualityGateTypes", targets: ["QualityGateTypes"]),
        .library(name: "QualityGateLogging", targets: ["QualityGateLogging"]),
    ],
	dependencies: [
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.5.0")
	],
    targets: [
        .target(
            name: "QualityGateTypes",
            path: "Sources/QualityGateTypes"
        ),
        // Apple's `os.Logger` under its own name where it exists, and a working
        // equivalent where it does not. Lives in this package because it is the leaf
        // every other one already depends on — the alternative is three copies.
        .target(
            name: "QualityGateLogging",
            path: "Sources/QualityGateLogging"
        ),
        .testTarget(
            name: "QualityGateLoggingTests",
            dependencies: ["QualityGateLogging"],
            path: "Tests/QualityGateLoggingTests"
        ),
        .testTarget(
            name: "QualityGateTypesTests",
            dependencies: ["QualityGateTypes"],
            path: "Tests/QualityGateTypesTests"
        ),
    ]
)
