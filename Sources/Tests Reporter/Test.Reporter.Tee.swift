//
//  Test.Reporter.Tee.swift
//  swift-tests
//
//  Reporter that forwards events to two reporters.
//

import Test_Primitives

extension Test.Reporter {
    /// Creates a reporter that forwards events to both reporters.
    ///
    /// Each call to ``sink()`` creates sinks from both reporters and
    /// combines them via ``Test/Reporter/Sink/tee(_:_:)``.
    ///
    /// - Parameters:
    ///   - first: The first reporter.
    ///   - second: The second reporter.
    /// - Returns: A reporter that tees to both.
    public static func tee(_ first: Test.Reporter, _ second: Test.Reporter) -> Test.Reporter {
        Test.Reporter { .tee(first.sink(), second.sink()) }
    }
}
