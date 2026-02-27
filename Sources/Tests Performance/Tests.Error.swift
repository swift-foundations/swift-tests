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

public import Binary_Primitives
public import Formatting_Primitives
public import Memory
public import Dependency_Primitives

// MARK: - Type Aliases for Allocation Tracking

extension Tests {
    /// Alias for allocation statistics from Memory.Allocation
    public typealias AllocationStats = Memory.Allocation.Statistics

    /// Alias for allocation tracker from Memory.Allocation
    public typealias AllocationTracker = Memory.Allocation.Tracker

    /// Alias for leak detector from Memory.Allocation
    public typealias LeakDetector = Memory.Allocation.Leak.Detector

    /// Alias for peak memory tracker from Memory.Allocation
    public typealias PeakTracker = Memory.Allocation.Peak.Tracker
}

// MARK: - Error Types

extension Tests {
    /// Errors thrown during performance testing operations.
    ///
    /// These errors provide detailed information about performance violations,
    /// including actual vs expected values and contextual information for debugging.
    public enum Error: Swift.Error, CustomStringConvertible {
        /// Performance threshold was exceeded in a trait-based test.
        case thresholdExceeded(test: Swift.String, metric: Metric, expected: Duration, actual: Duration)

        /// Memory allocation limit was exceeded during test execution.
        case allocationLimitExceeded(test: Swift.String, limit: Int, actual: Int)

        /// Memory leak was detected during test execution.
        case memoryLeakDetected(test: Swift.String, netAllocations: Int, netBytes: Int)

        /// Peak memory limit was exceeded during test execution.
        case peakMemoryExceeded(test: Swift.String, limit: Int, actual: Int)

        /// Performance expectation assertion failed.
        case performanceExpectationFailed(metric: Metric, threshold: Duration, actual: Duration)

        /// Performance regression was detected when comparing to a baseline.
        case regressionDetected(
            metric: Metric,
            baseline: Duration,
            current: Duration,
            regression: Double,
            tolerance: Double
        )

        public var description: Swift.String {
            switch self {
            case .thresholdExceeded(let test, let metric, let expected, let actual):
                return """
                    Performance threshold exceeded in '\(test)':
                    Expected \(metric): < \(expected.formatted())
                    Actual \(metric): \(actual.formatted())
                    """

            case .allocationLimitExceeded(let test, let limit, let actual):
                return """
                    Memory allocation limit exceeded in '\(test)':
                    Limit: \(limit.formatted(.bytes))
                    Actual: \(actual.formatted(.bytes))
                    Exceeded by: \((actual - limit).formatted(.bytes))
                    """

            case .memoryLeakDetected(let test, let netAllocations, let netBytes):
                return """
                    Memory leak detected in '\(test)':
                    Net allocations: \(netAllocations)
                    Net bytes: \(netBytes.formatted(.bytes))
                    """

            case .peakMemoryExceeded(let test, let limit, let actual):
                return """
                    Peak memory limit exceeded in '\(test)':
                    Limit: \(limit.formatted(.bytes))
                    Actual peak: \(actual.formatted(.bytes))
                    Exceeded by: \((actual - limit).formatted(.bytes))
                    """

            case .performanceExpectationFailed(let metric, let threshold, let actual):
                return """
                    Performance expectation failed:
                    Expected \(metric) < \(threshold.formatted())
                    Actual: \(actual.formatted())
                    Exceeded by: \((actual - threshold).formatted())
                    """

            case .regressionDetected(
                let metric,
                let baseline,
                let current,
                let regression,
                let tolerance
            ):
                return """
                    Performance regression detected:
                    Baseline \(metric): \(baseline.formatted())
                    Current \(metric): \(current.formatted())
                    Regression: \(regression.formatted(.percent.precision(1)))
                    Tolerance: \(tolerance.formatted(.percent.precision(1)))
                    """
            }
        }
    }
}
