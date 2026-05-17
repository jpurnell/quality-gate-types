// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "quality-gate-types",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "QualityGateTypes", targets: ["QualityGateTypes"]),
    ],
	dependencies: [
		.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.5.0")
	],
    targets: [
        .target(name: "QualityGateTypes", path: "Sources/QualityGateTypes"),
        .testTarget(
            name: "QualityGateTypesTests",
            dependencies: ["QualityGateTypes"],
            path: "Tests/QualityGateTypesTests"
        ),
    ]
)
