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

extension Test.Benchmark {
    /// Statistical performance measurement containing multiple duration samples.
    public struct Measurement: Sendable, Codable {
        /// All measured durations from individual test iterations.
        public let durations: [Duration]

        /// Creates a measurement from an array of durations.
        public init(durations: [Duration]) {
            self.durations = durations
        }
    }
}

// MARK: - Statistics

extension Test.Benchmark.Measurement {
    /// Minimum duration across all iterations.
    @inlinable
    public var min: Duration {
        durations.min() ?? .zero
    }

    /// Maximum duration across all iterations.
    @inlinable
    public var max: Duration {
        durations.max() ?? .zero
    }

    /// Median duration (50th percentile).
    @inlinable
    public var median: Duration {
        percentile(0.5)
    }

    /// Average (mean) duration across all iterations.
    @inlinable
    public var mean: Duration {
        guard !durations.isEmpty else { return .zero }
        let total = durations.reduce(Duration.zero, +)
        return total / durations.count
    }

    /// 50th percentile duration (same as ``median``).
    @inlinable
    public var p50: Duration {
        percentile(0.5)
    }

    /// 75th percentile duration.
    @inlinable
    public var p75: Duration {
        percentile(0.75)
    }

    /// 90th percentile duration.
    @inlinable
    public var p90: Duration {
        percentile(0.90)
    }

    /// 95th percentile duration.
    @inlinable
    public var p95: Duration {
        percentile(0.95)
    }

    /// 99th percentile duration.
    @inlinable
    public var p99: Duration {
        percentile(0.99)
    }

    /// Calculate a specific percentile.
    @inlinable
    public func percentile(_ p: Double) -> Duration {
        guard !durations.isEmpty else { return .zero }
        let sorted = durations.sorted()
        let index = Int(Double(sorted.count) * p)
        let clampedIndex = Swift.min(index, sorted.count - 1)
        return sorted[clampedIndex]
    }

    /// Standard deviation of duration measurements.
    @inlinable
    public var standardDeviation: Duration {
        guard durations.count > 1 else { return .zero }
        let meanNanoseconds = Double(mean.components.attoseconds) / 1_000_000_000
        let variance =
            durations.reduce(0.0) { acc, duration in
                let durationNanoseconds = Double(duration.components.attoseconds) / 1_000_000_000
                let diff = durationNanoseconds - meanNanoseconds
                return acc + (diff * diff)
            } / Double(durations.count - 1)
        return .nanoseconds(Int64(variance.squareRoot()))
    }
}
