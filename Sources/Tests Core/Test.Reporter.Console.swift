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

//
// Console and JSON reporters are in the Tests Reporter target.
// Import "Tests Reporter" (or "Tests" umbrella) for .console and .json(to:).
//
// This file provides only the null reporter for minimal dependencies.
//

public import Test_Primitives

extension Test.Reporter {
    /// A reporter that discards all events.
    ///
    /// Useful for benchmarking or when output is not needed.
    /// For human-readable output, use `.console` from the
    /// Test Reporters package.
    public static var null: Test.Reporter {
        Test.Reporter {
            Sink(NullSink())
        }
    }
}

// MARK: - NullSink

extension Test.Reporter {
    // WHY: Category D — structural Sendable workaround.
    // WHY: Stateless discard sink. No stored properties, no caller invariant.
    // WHY: The @unchecked exists because the Sink.Implementation protocol
    // WHY: conformance blocks structural Sendable inference.
    // WHEN TO REMOVE: When compiler gains structural Sendable inference through
    // WHEN TO REMOVE: protocol conformance on stateless types.
    // TRACKING: unsafe-audit-findings.md Category D; SP-7.
    /// Null sink that discards all events.
    private final class NullSink: Sink.Implementation, @unchecked Sendable {
        func send(_ event: Test.Event) async {}
        func finish() async {}
    }
}
