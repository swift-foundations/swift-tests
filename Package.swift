// swift-tools-version: 6.3.1

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
        .library(name: "Tests Reporter", targets: ["Tests Reporter"]),
        .library(name: "Tests", targets: ["Tests"]),
        .library(name: "Tests Apple Testing Bridge", targets: ["Tests Apple Testing Bridge"]),
        .library(name: "Tests Test Support", targets: ["Tests Test Support"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-ascii-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-test-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-binary-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-time-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-format-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-dependency-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ownership-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-set-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-set-ordered-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-hash-table-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-column-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-shared-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-buffer-linear-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tree-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tree-keyed-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-kernel.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-memory.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-console.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-file-system.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-io.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-json.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-loader.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-sample-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-clocks.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-environment.git", branch: "main"),
        .package(url: "https://github.com/swift-foundations/swift-witnesses.git", branch: "main"),
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
                .product(name: "Dependency Primitives", package: "swift-dependency-primitives"),
                .product(name: "Loader", package: "swift-loader"),
                .product(name: "Witnesses", package: "swift-witnesses"),
                .product(name: "Set Primitives", package: "swift-set-primitives"),
                .product(name: "Set Ordered Primitives", package: "swift-set-ordered-primitives"),
                .product(name: "Tree Keyed Primitives", package: "swift-tree-keyed-primitives"),
                .product(name: "Hash Indexed Primitive", package: "swift-hash-table-primitives"),
                .product(name: "Column Primitives", package: "swift-column-primitives"),
                .product(name: "Shared Primitive", package: "swift-shared-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
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
                "Tests Apple Testing Bridge",
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
                .product(name: "Format Primitives", package: "swift-format-primitives"),
                .product(name: "Dependency Primitives", package: "swift-dependency-primitives"),
                .product(name: "Clocks", package: "swift-clocks"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Environment", package: "swift-environment"),
                .product(name: "IO", package: "swift-io"),
            ]
        ),

        // MARK: - Reporter

        .target(
            name: "Tests Reporter",
            dependencies: [
                "Tests Core",
                .product(name: "Console", package: "swift-console"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Time Primitives", package: "swift-time-primitives"),
            ]
        ),

        // MARK: - Umbrella

        .target(
            name: "Tests",
            dependencies: [
                "Tests Core",
                "Tests Reporter",
                "Tests Snapshot",
                "Tests Performance",
            ]
        ),

        // MARK: - Apple Testing Bridge

        .target(
            name: "Tests Apple Testing Bridge",
            dependencies: [
                "Tests Snapshot",
                .product(name: "Dependency Primitives", package: "swift-dependency-primitives"),
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
                "Tests Inline Snapshot",
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
