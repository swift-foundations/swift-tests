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

// MARK: - Error Types

extension Tests {
    /// Errors thrown during performance testing operations.
    ///
    /// Composes leaf errors from domain-specific error types.
    public enum Error: Swift.Error, CustomStringConvertible {
        /// A benchmark operation failed.
        case benchmarkFailed(Test.Benchmark.Error)

        /// Memory allocation limit was exceeded during test execution.
        case allocationLimitExceeded(test: Swift.String, limit: Int, actual: Int)

        /// Memory leak was detected during test execution.
        case memoryLeakDetected(test: Swift.String, netAllocations: Int, netBytes: Int)

        /// Peak memory limit was exceeded during test execution.
        case peakMemoryExceeded(test: Swift.String, limit: Int, actual: Int)

        public var description: Swift.String {
            switch self {
            case .benchmarkFailed(let error):
                return error.description

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
            }
        }
    }
}
