// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-tests",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: "Tests Core", targets: ["Tests Core"]),
        .library(name: "Tests Snapshot", targets: ["Tests Snapshot"]),
        .library(name: "Tests Inline Snapshot", targets: ["Tests Inline Snapshot"]),
        .library(name: "Tests Performance", targets: ["Tests Performance"]),
        .library(name: "Tests", targets: ["Tests"]),
        .library(name: "Tests Test Support", targets: ["Tests Test Support"]),
    ],
    dependencies: [
        .package(path: "../../swift-primitives/swift-ascii-primitives"),
        .package(path: "../../swift-primitives/swift-test-primitives"),
        .package(path: "../../swift-primitives/swift-binary-primitives"),
        .package(path: "../../swift-primitives/swift-time-primitives"),
        .package(path: "../../swift-primitives/swift-formatting-primitives"),
        .package(path: "../../swift-primitives/swift-dependency-primitives"),
        .package(path: "../../swift-primitives/swift-ownership-primitives"),
        .package(path: "../../swift-primitives/swift-set-primitives"),
        .package(path: "../../swift-primitives/swift-tree-primitives"),
        .package(path: "../swift-kernel"),
        .package(path: "../swift-memory"),
        .package(path: "../swift-console"),
        .package(path: "../swift-file-system"),
        .package(path: "../swift-json"),
        .package(path: "../swift-loader"),
        .package(path: "../../swift-primitives/swift-sample-primitives"),
        .package(path: "../swift-clocks"),
        .package(path: "../swift-environment"),
        .package(path: "../swift-witnesses"),
        .package(url: "https://github.com/swiftlang/swift-syntax", "602.0.0"..<"603.0.0"),
    ],
    targets: [

        // MARK: - Core

        .target(
            name: "Tests Core",
            dependencies: [
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
                .product(name: "Test Primitives", package: "swift-test-primitives"),
                .product(name: "Ownership Primitives", package: "swift-ownership-primitives"),
                .product(name: "Loader", package: "swift-loader"),
                .product(name: "Witnesses", package: "swift-witnesses"),
                .product(name: "Set Primitives", package: "swift-set-primitives"),
                .product(name: "Tree Keyed Primitives", package: "swift-tree-primitives"),
            ]
        ),

        // MARK: - Snapshot

        .target(
            name: "Tests Snapshot",
            dependencies: [
                "Tests Core",
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Dependency Primitives", package: "swift-dependency-primitives"),
                .product(name: "Kernel", package: "swift-kernel"),
            ]
        ),

        // MARK: - Inline Snapshot

        .target(
            name: "Tests Inline Snapshot",
            dependencies: [
                "Tests Snapshot",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
            ]
        ),

        // MARK: - Performance

        .target(
            name: "Tests Performance",
            dependencies: [
                "Tests Core",
                .product(name: "Sample Primitives", package: "swift-sample-primitives"),
                .product(name: "Time Primitives", package: "swift-time-primitives"),
                .product(name: "Console", package: "swift-console"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Memory", package: "swift-memory"),
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Formatting Primitives", package: "swift-formatting-primitives"),
                .product(name: "Dependency Primitives", package: "swift-dependency-primitives"),
                .product(name: "Clocks", package: "swift-clocks"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Environment", package: "swift-environment"),
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "Tests",
            dependencies: [
                "Tests Core",
                "Tests Snapshot",
                "Tests Inline Snapshot",
                "Tests Performance",
            ]
        ),

        // MARK: - Test Support

        .target(
            name: "Tests Test Support",
            dependencies: [
                "Tests",
                .product(
                    name: "Test Primitives Test Support",
                    package: "swift-test-primitives"
                ),
                .product(
                    name: "Kernel Test Support",
                    package: "swift-kernel"
                ),
                .product(
                    name: "File System Test Support",
                    package: "swift-file-system"
                ),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests

        .testTarget(
            name: "Tests Tests",
            dependencies: [
                "Tests",
                "Tests Test Support",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableExperimentalFeature("SuppressedAssociatedTypesWithDefaults"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
