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
// Console reporter has moved to swift-test-reporters (Components layer).
// Import "Test Reporters" for the full console reporter.
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
    /// Null sink that discards all events.
    private final class NullSink: SinkImplementation, @unchecked Sendable {
        func send(_ event: Test.Event) async {}
        func finish() async {}
    }
}
