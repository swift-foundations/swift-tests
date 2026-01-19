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
    /// Metric to use for performance threshold comparison.
    public enum Metric: Swift.String, Sendable, Codable {
        case min
        case max
        case median
        case mean
        case p95
        case p99

        /// Extracts the metric value from a measurement.
        @inlinable
        public func extract(from measurement: Measurement) -> Duration {
            switch self {
            case .min: return measurement.min
            case .max: return measurement.max
            case .median: return measurement.median
            case .mean: return measurement.mean
            case .p95: return measurement.p95
            case .p99: return measurement.p99
            }
        }
    }
}
