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

/// Namespace for performance testing utilities integrated with Swift Testing.
///
/// Tests provides comprehensive tools for measuring, analyzing, and
/// enforcing performance requirements in your Swift tests.
///
/// ## Overview
///
/// Use Tests to:
/// - Measure execution time with statistical analysis
/// - Track memory allocations during test execution
/// - Compare performance across runs to detect regressions
/// - Enforce performance budgets with declarative traits
/// - Generate formatted performance reports
///
/// ## Basic Usage
///
/// The simplest way to measure performance is with the `.timed()` trait:
///
/// ```swift
/// import Testing
/// import Tests
///
/// @Test(.timed())
/// func arraySum() {
///     let numbers = Array(1...10_000)
///     _ = numbers.reduce(0, +)
/// }
/// ```
///
/// For manual measurement without traits:
///
/// ```swift
/// @Test
/// func manualMeasurement() {
///     let (result, measurement) = Tests.measure {
///         expensiveOperation()
///     }
///
///     Tests.printPerformance("operation", measurement)
///     #expect(measurement.median < .milliseconds(10))
/// }
/// ```
///
/// ## Performance Budgets
///
/// Enforce maximum execution time to prevent performance regressions:
///
/// ```swift
/// @Test(.timed(threshold: .milliseconds(5)))
/// func mustBeFast() {
///     criticalOperation()
/// }
/// ```
public enum Tests {}

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
        case thresholdExceeded(test: String, metric: Metric, expected: Duration, actual: Duration)

        /// Memory allocation limit was exceeded during test execution.
        case allocationLimitExceeded(test: String, limit: Int, actual: Int)

        /// Memory leak was detected during test execution.
        case memoryLeakDetected(test: String, netAllocations: Int, netBytes: Int)

        /// Peak memory limit was exceeded during test execution.
        case peakMemoryExceeded(test: String, limit: Int, actual: Int)

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

        public var description: String {
            switch self {
            case .thresholdExceeded(let test, let metric, let expected, let actual):
                return """
                    Performance threshold exceeded in '\(test)':
                    Expected \(metric): < \(Tests.formatDuration(expected))
                    Actual \(metric): \(Tests.formatDuration(actual))
                    """

            case .allocationLimitExceeded(let test, let limit, let actual):
                return """
                    Memory allocation limit exceeded in '\(test)':
                    Limit: \(formatBytes(limit))
                    Actual: \(formatBytes(actual))
                    Exceeded by: \(formatBytes(actual - limit))
                    """

            case .memoryLeakDetected(let test, let netAllocations, let netBytes):
                return """
                    Memory leak detected in '\(test)':
                    Net allocations: \(netAllocations)
                    Net bytes: \(formatBytes(netBytes))
                    """

            case .peakMemoryExceeded(let test, let limit, let actual):
                return """
                    Peak memory limit exceeded in '\(test)':
                    Limit: \(formatBytes(limit))
                    Actual peak: \(formatBytes(actual))
                    Exceeded by: \(formatBytes(actual - limit))
                    """

            case .performanceExpectationFailed(let metric, let threshold, let actual):
                return """
                    Performance expectation failed:
                    Expected \(metric) < \(Tests.formatDuration(threshold))
                    Actual: \(Tests.formatDuration(actual))
                    Exceeded by: \(Tests.formatDuration(actual - threshold))
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
                    Baseline \(metric): \(Tests.formatDuration(baseline))
                    Current \(metric): \(Tests.formatDuration(current))
                    Regression: \(regression.formatted(.percent.precision(1)))
                    Tolerance: \(tolerance.formatted(.percent.precision(1)))
                    """
            }
        }

        private func formatBytes(_ bytes: Int) -> String {
            bytes.formatted(.bytes)
        }
    }
}
