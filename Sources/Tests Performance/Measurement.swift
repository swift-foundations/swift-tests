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
public import Sample_Primitives
import Clocks

extension Tests {
    /// Statistical performance measurement containing multiple duration samples.
    ///
    /// `Measurement` stores the results of running a performance test multiple times
    /// and provides statistical metrics like median, mean, percentiles, and standard deviation.
    ///
    /// ## Overview
    ///
    /// Create measurements using ``Tests/measure(warmup:iterations:operation:)-4kv1g``:
    ///
    /// ```swift
    /// let (result, measurement) = Tests.measure(iterations: 100) {
    ///     expensiveOperation()
    /// }
    ///
    /// print("Median: \(measurement.median)")
    /// print("p95: \(measurement.p95)")
    /// ```
    ///
    /// ## Statistical Metrics
    ///
    /// - **Median** (``median``): Middle value, resistant to outliers
    /// - **Mean** (``mean``): Average of all measurements
    /// - **Percentiles** (``p50``, ``p75``, ``p90``, ``p95``, ``p99``, ``p999``): Values at specific percentiles
    /// - **Min/Max** (``min``, ``max``): Fastest and slowest iterations
    /// - **Standard Deviation** (``standardDeviation``): Measure of variation
    public struct Measurement: Sendable {
        /// All measured durations from individual test iterations.
        public let durations: [Duration]

        /// Pre-computed batch statistics over the durations.
        public let batch: Sample.Batch<Duration>

        /// Creates a measurement from an array of durations.
        public init(durations: [Duration]) {
            self.durations = durations
            self.batch = Sample.Batch(durations)
        }
    }
}

// MARK: - Codable

extension Tests.Measurement: Codable {
    private enum CodingKeys: Swift.String, CodingKey {
        case durations
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(durations, forKey: .durations)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let durations = try container.decode([Duration].self, forKey: .durations)
        self.durations = durations
        self.batch = Sample.Batch(durations)
    }
}

// MARK: - Comparable

extension Tests.Measurement: Comparable {
    /// Compares measurements by median duration
    public static func < (
        lhs: Tests.Measurement,
        rhs: Tests.Measurement
    ) -> Bool {
        lhs.median < rhs.median
    }

    /// Compares measurements by median duration
    public static func == (
        lhs: Tests.Measurement,
        rhs: Tests.Measurement
    ) -> Bool {
        lhs.median == rhs.median
    }
}

extension Tests.Measurement {
    /// Minimum duration across all iterations.
    public var min: Duration {
        batch.min ?? .zero
    }

    /// Maximum duration across all iterations.
    public var max: Duration {
        batch.max ?? .zero
    }

    /// Median duration (50th percentile).
    public var median: Duration {
        batch.median ?? .zero
    }

    /// Average (mean) duration across all iterations.
    public var mean: Duration {
        batch.mean ?? .zero
    }

    /// 50th percentile duration (same as ``median``).
    public var p50: Duration {
        batch.p50 ?? .zero
    }

    /// 75th percentile duration.
    public var p75: Duration {
        batch.p75 ?? .zero
    }

    /// 90th percentile duration.
    public var p90: Duration {
        batch.p90 ?? .zero
    }

    /// 95th percentile duration.
    public var p95: Duration {
        batch.p95 ?? .zero
    }

    /// 99th percentile duration.
    public var p99: Duration {
        batch.p99 ?? .zero
    }

    /// 99.9th percentile duration.
    public var p999: Duration {
        batch.p999 ?? .zero
    }

    /// Calculate a specific percentile.
    ///
    /// - Parameter p: Percentile to calculate, from 0.0 (minimum) to 1.0 (maximum)
    /// - Returns: Duration at the specified percentile, or `.zero` if no durations
    public func percentile(_ p: Double) -> Duration {
        batch.percentile(p) ?? .zero
    }

    /// Standard deviation of duration measurements.
    public var standardDeviation: Duration {
        batch.standardDeviation ?? .zero
    }
}

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
    ) -> (result: T, measurement: Tests.Measurement) {
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

        return (lastResult!, Tests.Measurement(durations: durations))
    }

    /// Measure performance of an async operation
    @discardableResult
    public static func measure<T, E: Swift.Error>(
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () async throws(E) -> T
    ) async throws(E) -> (result: T, measurement: Tests.Measurement) {
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

        return (lastResult!, Tests.Measurement(durations: durations))
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
