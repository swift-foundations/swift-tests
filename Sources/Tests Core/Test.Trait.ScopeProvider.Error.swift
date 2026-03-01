//
//  Test.Trait.ScopeProvider.Error.swift
//  swift-tests
//
//  Typed error for scope provider execution.
//

extension Test.Trait.ScopeProvider {
    /// Errors thrown during scope-provided test execution.
    public enum Error: Swift.Error, Sendable {
        /// The test body threw an error.
        case bodyFailed(Test.Body.Error)

        /// Test exceeded its configured time limit.
        case timeLimitExceeded(limit: Duration)

        /// Performance metric exceeded the configured threshold.
        case performanceThresholdExceeded(
            test: Swift.String,
            metric: Test.Benchmark.Metric,
            expected: Duration,
            actual: Duration
        )
    }
}
