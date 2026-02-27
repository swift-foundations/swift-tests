// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-tests open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-tests project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Time_Primitives
public import Test_Primitives

// MARK: - Trait Extension

extension Test.Trait {
    /// The trait name for timed execution.
    @usableFromInline
    static let timedTraitName = "__timed__"

    /// Creates a trait for measuring test execution time.
    ///
    /// When applied, the test runner will measure execution time across
    /// multiple iterations and optionally enforce a performance threshold.
    ///
    /// ## Important: Instance Recreation
    ///
    /// Swift Testing creates a new test struct instance for each iteration.
    /// This means your `init()` runs for every iteration, not just once.
    ///
    /// If your `init()` performs expensive setup, use ``Test/Benchmark/measure(iterations:warmup:name:threshold:metric:_:)`` instead.
    ///
    /// ## When to Use `.timed()`
    ///
    /// Use `.timed()` when:
    /// - Test setup is cheap (no file I/O, network, or allocations)
    /// - Each iteration is independent
    /// - You want the simplest possible benchmark syntax
    ///
    /// ```swift
    /// @Test(.timed())
    /// func operation() {
    ///     numbers.sum()
    /// }
    /// ```
    ///
    /// With threshold enforcement:
    /// ```swift
    /// @Test(.timed(threshold: .milliseconds(50)))
    /// func fastOperation() {
    ///     numbers.sum()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - iterations: Number of measurement runs (default: 10)
    ///   - warmup: Number of untimed warmup runs (default: 0)
    ///   - threshold: Optional performance budget - test fails if exceeded
    ///   - metric: Metric to check against threshold (default: .median)
    /// - Returns: A timed trait.
    @inlinable
    public static func timed(
        iterations: Int = 10,
        warmup: Int = 0,
        threshold: Duration? = nil,
        metric: Test.Benchmark.Metric = .median
    ) -> Self {
        let config = Test.Benchmark.Configuration(
            iterations: iterations,
            warmup: warmup,
            printResults: true,
            threshold: threshold,
            metric: metric
        )
        return .custom(timedTraitName, value: config.encode())
    }
}

// MARK: - Trait Inspection

extension Test.Trait {
    /// Extracts timed configuration from a trait, if present.
    ///
    /// - Returns: The timed configuration if this is a timed trait, nil otherwise.
    @inlinable
    public var timedConfiguration: Test.Benchmark.Configuration? {
        guard case .custom(let name, let value) = kind,
              name == Self.timedTraitName,
              let configString = value else {
            return nil
        }
        return Test.Benchmark.Configuration.decode(from: configString)
    }
}

extension Collection where Element == Test.Trait {
    /// Finds timed configuration from a collection of traits.
    ///
    /// - Returns: The timed configuration if present.
    @inlinable
    public var timedConfiguration: Test.Benchmark.Configuration? {
        for trait in self {
            if let config = trait.timedConfiguration {
                return config
            }
        }
        return nil
    }
}
