//
//  Test.Trait.Scope.Provider.Error.swift
//  swift-tests
//
//  Typed error for scope provider execution.
//

extension Test.Trait.Scope.Provider {
    /// Errors thrown during scope-provided test execution.
    public enum Error: Swift.Error, Sendable {
        /// The test body threw an error.
        case bodyFailed(Test.Body.Error)

        /// Test exceeded its configured time limit.
        case timeLimitExceeded(limit: Duration)

        /// Performance metric exceeded the configured threshold.
        case thresholdExceeded(
            test: Swift.String,
            metric: Test.Benchmark.Metric,
            expected: Duration,
            actual: Duration
        )

        /// Performance regression exceeded the configured baseline tolerance.
        case regressionDetected(
            test: Swift.String,
            metric: Test.Benchmark.Metric,
            baseline: Duration,
            current: Duration,
            regression: Double,
            tolerance: Double
        )

        /// No stored baseline exists and recording mode is `.never`.
        case baselineMissing(
            test: Swift.String,
            path: Swift.String
        )
    }
}
