//
//  Tests.Complexity.Result.swift
//  swift-tests
//
//  Interpreted complexity analysis result.
//

public import Test_Primitives

extension Tests.Complexity {
    /// Interpreted complexity analysis result.
    ///
    /// Wraps raw ``Test/Benchmark/Complexity/Evidence`` with policy-derived
    /// interpretation: the best candidate class, confidence level, ambiguous
    /// alternatives, and reasons for uncertainty.
    ///
    /// Use ``isCompatible(with:)`` for exploratory assertions and
    /// ``isNoWorseThan(_:)`` for contractual bounds.
    public struct Result: Sendable {
        /// The raw analytical evidence from L1 fitting.
        public let evidence: Test.Benchmark.Complexity.Evidence

        /// The best discrete candidate, or `nil` if inconclusive.
        public let best: Test.Benchmark.Complexity.Candidate.Fit?

        /// How much to trust the classification.
        public let confidence: Confidence

        /// Classes that are plausibly compatible with the evidence
        /// but were not selected as the best candidate.
        public let ambiguousWith: [Test.Benchmark.Complexity.Class]

        /// Reasons for uncertainty or inconclusiveness.
        public let reasons: [InconclusiveReason]

        public init(
            evidence: Test.Benchmark.Complexity.Evidence,
            best: Test.Benchmark.Complexity.Candidate.Fit?,
            confidence: Confidence,
            ambiguousWith: [Test.Benchmark.Complexity.Class],
            reasons: [InconclusiveReason]
        ) {
            self.evidence = evidence
            self.best = best
            self.confidence = confidence
            self.ambiguousWith = ambiguousWith
            self.reasons = reasons
        }
    }
}

extension Tests.Complexity.Result {
    /// Whether the given class is compatible with the observed evidence.
    ///
    /// Returns `true` if the class is either the best candidate or
    /// within the ambiguity range. Both ``Test/Benchmark/Complexity/Class/linear``
    /// and ``Test/Benchmark/Complexity/Class/linearithmic`` can return
    /// `true` simultaneously — this is honest, not a bug.
    public func isCompatible(
        with candidate: Test.Benchmark.Complexity.Class
    ) -> Bool {
        if best?.complexity == candidate { return true }
        if ambiguousWith.contains(candidate) { return true }
        return false
    }

    /// Whether the observed complexity is no worse than the given bound.
    ///
    /// Returns `true` if the best candidate and all ambiguous alternatives
    /// are at or below the given class in the growth-rate ordering.
    /// Returns `false` if the result is inconclusive.
    ///
    /// Use this for contractual assertions: "my algorithm should remain
    /// no worse than quadratic."
    public func isNoWorseThan(
        _ bound: Test.Benchmark.Complexity.Class
    ) -> Bool {
        guard let best else { return false }
        if best.complexity > bound { return false }
        return ambiguousWith.allSatisfy { $0 <= bound }
    }
}
