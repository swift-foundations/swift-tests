//
//  Tests.Complexity.Baseline.swift
//  swift-tests
//
//  Stored complexity baseline for cross-run regression detection.
//

public import Test_Primitives

extension Tests.Complexity {
    /// Stored complexity baseline for regression detection.
    ///
    /// Captures the essential classification data from a complexity analysis
    /// run. Stored as JSON and compared against subsequent runs to detect
    /// complexity regressions (e.g., O(n) degrading to O(n^2)).
    public struct Baseline: Sendable {
        /// The best complexity class, or `nil` if inconclusive.
        public let bestClass: Test.Benchmark.Complexity.Class?

        /// The continuous exponent from log-log regression.
        public let exponent: Double

        /// The confidence level of the classification.
        public let confidence: Confidence

        /// R-squared of the best candidate fit.
        public let bestRSquared: Double?

        public init(
            bestClass: Test.Benchmark.Complexity.Class?,
            exponent: Double,
            confidence: Confidence,
            bestRSquared: Double?
        ) {
            self.bestClass = bestClass
            self.exponent = exponent
            self.confidence = confidence
            self.bestRSquared = bestRSquared
        }

        /// Constructs a baseline from a complexity analysis result.
        public init(result: Result) {
            self.bestClass = result.best?.complexity
            self.exponent = result.evidence.exponent.value
            self.confidence = result.confidence
            self.bestRSquared = result.best?.regression.rSquared
        }
    }
}
