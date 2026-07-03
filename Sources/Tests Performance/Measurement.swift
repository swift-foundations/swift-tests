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

import Clocks
public import Time_Primitives

// MARK: - Measurement API

extension Tests {
    /// Measure performance of an operation
    ///
    /// Runs the operation multiple times with optional warmup iterations,
    /// collecting timing data for statistical analysis.
    @discardableResult
    public static func measure<T>(
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () -> T
    ) -> (result: T, measurement: Test.Benchmark.Measurement) {
        // Warmup
        for _ in 0..<warmup {
            _ = operation()
        }

        // Measure
        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        var lastResult: T?

        for _ in 0..<iterations {
            let start = Clock_Primitives.Clock.Continuous.now
            lastResult = operation()
            durations.append(Clock_Primitives.Clock.Continuous.now - start)
        }

        return (lastResult!, Test.Benchmark.Measurement(durations: durations))
    }

    /// Measure performance of an async operation
    @discardableResult
    public static func measure<T, E: Swift.Error>(
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () async throws(E) -> T
    ) async throws(E) -> (result: T, measurement: Test.Benchmark.Measurement) {
        // Warmup
        for _ in 0..<warmup {
            _ = try await operation()
        }

        // Measure
        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        var lastResult: T?

        for _ in 0..<iterations {
            let start = Clock_Primitives.Clock.Continuous.now
            lastResult = try await operation()
            durations.append(Clock_Primitives.Clock.Continuous.now - start)
        }

        return (lastResult!, Test.Benchmark.Measurement(durations: durations))
    }

    /// Single-shot timing measurement
    @discardableResult
    public static func time<T>(operation: () -> T) -> (result: T, duration: Duration) {
        let start = Clock_Primitives.Clock.Continuous.now
        let result = operation()
        return (result, Clock_Primitives.Clock.Continuous.now - start)
    }

    /// Single-shot timing measurement for async operations
    @discardableResult
    public static func time<T, E: Swift.Error>(
        operation: () async throws(E) -> T
    ) async throws(E) -> (result: T, duration: Duration) {
        let start = Clock_Primitives.Clock.Continuous.now
        let result = try await operation()
        return (result, Clock_Primitives.Clock.Continuous.now - start)
    }
}
