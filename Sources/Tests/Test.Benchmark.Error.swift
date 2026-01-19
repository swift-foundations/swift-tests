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
    public enum Error: Swift.Error, CustomStringConvertible {
        /// Performance threshold was exceeded.
        case thresholdExceeded(test: Swift.String, metric: Metric, expected: Duration, actual: Duration)

        public var description: Swift.String {
            switch self {
            case .thresholdExceeded(let test, let metric, let expected, let actual):
                return """
                    Performance threshold exceeded in '\(test)':
                    Expected \(metric): < \(expected.formatted())
                    Actual \(metric): \(actual.formatted())
                    """
            }
        }
    }
}
