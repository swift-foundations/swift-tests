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
        // Standalone testing library - no Apple Testing, no swift-syntax
        .library(name: "Tests", targets: ["Tests"]),
    ],
    dependencies: [
        .package(path: "../../swift-primitives/swift-test-primitives"),
        .package(path: "../../swift-primitives/swift-async-primitives"),
        .package(path: "../../swift-primitives/swift-binary-primitives"),
        .package(path: "../../swift-primitives/swift-time-primitives"),
        .package(path: "../../swift-primitives/swift-clock-primitives"),
        .package(path: "../../swift-primitives/swift-formatting-primitives"),
        .package(path: "../../swift-primitives/swift-dependency-primitives"),
        .package(path: "../../swift-primitives/swift-ownership-primitives"),
        .package(path: "../swift-kernel"),
        .package(path: "../swift-memory"),
        .package(path: "../swift-console"),
        .package(path: "../swift-file-system"),
        .package(path: "../swift-paths"),
        .package(path: "../swift-json"),
        .package(path: "../swift-loader"),
    ],
    targets: [
        // Core Tests target - standalone
        // Contains: Runner, Plan, Reporter, expect/require APIs
        .target(
            name: "Tests",
            dependencies: [
                .product(name: "Test Primitives", package: "swift-test-primitives"),
                .product(name: "Async Primitives", package: "swift-async-primitives"),
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Time Primitives", package: "swift-time-primitives"),
                .product(name: "Clock Primitives", package: "swift-clock-primitives"),
                .product(name: "Formatting Primitives", package: "swift-formatting-primitives"),
                .product(name: "Dependency Primitives", package: "swift-dependency-primitives"),
                .product(name: "Ownership Primitives", package: "swift-ownership-primitives"),
                .product(name: "Kernel", package: "swift-kernel"),
                .product(name: "Memory", package: "swift-memory"),
                .product(name: "Console", package: "swift-console"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "Paths", package: "swift-paths"),
                .product(name: "JSON", package: "swift-json"),
                .product(name: "Loader", package: "swift-loader"),
            ],
            path: "Sources/Tests"
        ),
        .testTarget(
            name: "Tests Tests",
            dependencies: [
                "Tests",
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
