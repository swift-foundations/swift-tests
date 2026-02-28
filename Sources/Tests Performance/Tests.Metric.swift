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

public import Sample_Primitives

extension Tests {
    /// Performance metrics that can be asserted against.
    public typealias Metric = Sample.Metric
}

extension Sample.Metric {
    /// Extracts this metric from a measurement.
    @inlinable
    public func extract(from measurement: Tests.Measurement) -> Duration {
        self.extract(from: measurement.batch, using: .duration) ?? .zero
    }
}
