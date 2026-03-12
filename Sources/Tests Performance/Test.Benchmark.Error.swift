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
    /// Errors thrown during performance testing operations.
    public enum Error: Swift.Error, Sendable, CustomStringConvertible {
        /// Performance threshold was exceeded.
        case thresholdExceeded(test: Swift.String, metric: Metric, expected: Duration, actual: Duration)

        /// Performance regression exceeded the configured baseline tolerance.
        case regressionDetected(
            test: Swift.String,
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

            case .regressionDetected(let test, let metric, let baseline, let current, let regression, let tolerance):
                return """
                    Performance regression detected in '\(test)':
                    Baseline \(metric): \(baseline.formatted())
                    Current \(metric): \(current.formatted())
                    Regression: \(regression)x tolerance (\(tolerance))
                    """
            }
        }
    }
}
