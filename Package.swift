// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "EnumeratorMacro",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "EnumeratorMacro",
            targets: ["EnumeratorMacro"]
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
        .package(
            url: "https://github.com/mahdibm/swift-mustache",
            branch: "mmbm-swift-6"
        ),
    ],
    targets: [
        .macro(
            name: "EnumeratorMacro",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "Mustache", package: "swift-mustache"),
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "EnumeratorMacroTests",
            dependencies: [
                "EnumeratorMacro",
                .product(name: "Testing", package: "swift-testing"),
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "Mustache", package: "swift-mustache"),
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
