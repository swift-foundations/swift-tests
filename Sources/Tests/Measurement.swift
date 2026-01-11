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
    public struct Measurement: Sendable, Codable {
        /// All measured durations from individual test iterations.
        public let durations: [Duration]

        /// Creates a measurement from an array of durations.
        public init(durations: [Duration]) {
            self.durations = durations
        }
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
        durations.min() ?? .zero
    }

    /// Maximum duration across all iterations.
    public var max: Duration {
        durations.max() ?? .zero
    }

    /// Median duration (50th percentile).
    public var median: Duration {
        percentile(0.5)
    }

    /// Average (mean) duration across all iterations.
    public var mean: Duration {
        guard !durations.isEmpty else { return .zero }
        let total = durations.reduce(Duration.zero, +)
        return total / durations.count
    }

    /// 50th percentile duration (same as ``median``).
    public var p50: Duration {
        percentile(0.5)
    }

    /// 75th percentile duration.
    public var p75: Duration {
        percentile(0.75)
    }

    /// 90th percentile duration.
    public var p90: Duration {
        percentile(0.90)
    }

    /// 95th percentile duration.
    public var p95: Duration {
        percentile(0.95)
    }

    /// 99th percentile duration.
    public var p99: Duration {
        percentile(0.99)
    }

    /// 99.9th percentile duration.
    public var p999: Duration {
        percentile(0.999)
    }

    /// Calculate a specific percentile.
    ///
    /// - Parameter p: Percentile to calculate, from 0.0 (minimum) to 1.0 (maximum)
    /// - Returns: Duration at the specified percentile, or `.zero` if no durations
    public func percentile(_ p: Double) -> Duration {
        guard !durations.isEmpty else { return .zero }
        let sorted = durations.sorted()
        let index = Int(Double(sorted.count) * p)
        let clampedIndex = Swift.min(index, sorted.count - 1)
        return sorted[clampedIndex]
    }

    /// Standard deviation of duration measurements.
    public var standardDeviation: Duration {
        guard durations.count > 1 else { return .zero }
        let meanSeconds = mean.inSeconds
        let variance =
            durations.reduce(0.0) { acc, duration in
                let diff = duration.inSeconds - meanSeconds
                return acc + (diff * diff)
            } / Double(durations.count - 1)
        return .seconds(variance.squareRoot())
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
            let start = ContinuousClock.now
            lastResult = operation()
            let end = ContinuousClock.now
            durations.append(end - start)
        }

        return (lastResult!, Tests.Measurement(durations: durations))
    }

    /// Measure performance of an async operation
    @discardableResult
    public static func measure<T>(
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () async throws -> T
    ) async rethrows -> (result: T, measurement: Tests.Measurement) {
        // Warmup
        for _ in 0..<warmup {
            _ = try await operation()
        }

        // Measure
        var durations: [Duration] = []
        durations.reserveCapacity(iterations)
        var lastResult: T?

        for _ in 0..<iterations {
            let start = ContinuousClock.now
            lastResult = try await operation()
            let end = ContinuousClock.now
            durations.append(end - start)
        }

        return (lastResult!, Tests.Measurement(durations: durations))
    }

    /// Single-shot timing measurement
    @discardableResult
    public static func time<T>(operation: () -> T) -> (result: T, duration: Duration) {
        let start = ContinuousClock.now
        let result = operation()
        let end = ContinuousClock.now
        return (result, end - start)
    }

    /// Single-shot timing measurement for async operations
    @discardableResult
    public static func time<T>(
        operation: () async throws -> T
    ) async rethrows -> (result: T, duration: Duration) {
        let start = ContinuousClock.now
        let result = try await operation()
        let end = ContinuousClock.now
        return (result, end - start)
    }
}

// MARK: - Duration Formatting

extension Tests {
    /// Format a duration for performance display.
    ///
    /// Automatically selects appropriate unit (ns, µs, ms, s).
    ///
    /// ## Example
    ///
    /// ```swift
    /// Tests.formatDuration(duration)                    // "1.5 ms"
    /// Tests.formatDuration(duration, .milliseconds)     // "1500 ms"
    /// ```
    public static func formatDuration(
        _ duration: Duration,
        _ format: Time.Format = .duration
    ) -> String {
        duration.formatted(format)
    }
}
