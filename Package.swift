// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SyntaxKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "SyntaxKit",
            targets: ["SyntaxKit"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax",
            from: "600.0.0-prerelease-2024-06-12"
        ),
        .package(
            url: "https://github.com/apple/swift-testing",
            .upToNextMinor(from: "0.10.0")
        ),
    ],
    targets: [
        .target(
            name: "SyntaxKit",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "SyntaxKitTests",
            dependencies: [
                "SyntaxKit",
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableExperimentalFeature("ExistentialAny"),
        .enableExperimentalFeature("AccessLevelOnImport"),
    ]
}
