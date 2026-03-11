//
//  Tests.Complexity.Diagnostic.swift
//  swift-tests
//
//  Structured complexity diagnostic for console and AI-agent output.
//

public import Test_Primitives

extension Tests.Complexity {
    /// Structured complexity diagnostic aggregating classification results.
    ///
    /// Built by ``analyze(sizes:warmup:iterations:metric:policy:operation:)``
    /// and returned directly. Contains the ``Result`` plus everything needed
    /// to diagnose a complexity regression or understand a classification.
    ///
    /// Access the interpreted result via ``result``:
    /// ```swift
    /// let diagnostic = try Tests.Complexity.analyze(sizes: [...]) { n in ... }
    /// #expect(diagnostic.result.isNoWorseThan(.linearithmic))
    /// ```
    public struct Diagnostic: Sendable {
        /// The classification result.
        public let result: Tests.Complexity.Result

        /// Per-size-point measurements as (size, duration) pairs.
        public let points: [(size: Int, metric: Duration)]

        /// The metric used for extraction.
        public let metric: Sample.Metric

        /// The policy applied.
        public let policy: Policy

        /// Baseline comparison, populated when a baseline key is provided.
        public var baselineComparison: Baseline.Comparison?

        public init(
            result: Tests.Complexity.Result,
            points: [(size: Int, metric: Duration)],
            metric: Sample.Metric,
            policy: Policy,
            baselineComparison: Baseline.Comparison? = nil
        ) {
            self.result = result
            self.points = points
            self.metric = metric
            self.policy = policy
            self.baselineComparison = baselineComparison
        }
    }
}
