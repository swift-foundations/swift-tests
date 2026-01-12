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
        .package(url: "https://github.com/swift-primitives/swift-test-primitives.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-primitives/swift-async-primitives.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-primitives/swift-binary-primitives.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-primitives/swift-time-primitives.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-primitives/swift-clock-primitives.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-primitives/swift-formatting-primitives.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-foundations/swift-memory.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-foundations/swift-console.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-foundations/swift-file-system.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-foundations/swift-paths.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-foundations/swift-json.git", from: "0.0.1"),
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
                .product(name: "Memory", package: "swift-memory"),
                .product(name: "Console", package: "swift-console"),
                .product(name: "File System", package: "swift-file-system"),
                .product(name: "Paths", package: "swift-paths"),
                .product(name: "JSON", package: "swift-json"),
            ],
            path: "Sources/Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let settings: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
    ]
    target.swiftSettings = (target.swiftSettings ?? []) + settings
}
