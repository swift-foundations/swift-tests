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

extension Test {
    /// Namespace for benchmark operations.
    public enum Benchmark {}
}

extension Test.Benchmark {
    /// Typealias for backwards compatibility.
    public typealias Measurement = Tests.Measurement

    /// Typealias for backwards compatibility.
    public typealias Metric = Tests.Metric
}
