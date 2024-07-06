// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SyntaxKit",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
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
        )
    ],
    targets: [
        .target(
            name: "SyntaxKit"
        ),
        .testTarget(
            name: "SyntaxKitTests",
            dependencies: ["SyntaxKit"]
        ),
    ]
)
