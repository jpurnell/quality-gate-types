// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "quality-gate-types",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "QualityGateTypes", targets: ["QualityGateTypes"]),
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
