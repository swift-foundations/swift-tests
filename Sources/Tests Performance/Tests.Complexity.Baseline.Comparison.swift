//
//  Tests.Complexity.Baseline.Comparison.swift
//  swift-tests
//
//  Comparison between current complexity result and stored baseline.
//

import Test_Primitives

extension Tests.Complexity.Baseline {
    /// Comparison between a stored baseline and the current analysis result.
    ///
    /// Detects three kinds of changes:
    /// - **Class regression**: complexity class worsened (e.g., linear -> quadratic)
    /// - **Exponent drift**: continuous exponent shifted significantly
    /// - **Confidence degradation**: confidence level dropped
    public struct Comparison: Sendable {
        /// The stored baseline.
        public let previous: Tests.Complexity.Baseline

        /// The current result as a baseline snapshot.
        public let current: Tests.Complexity.Baseline

        public init(
            previous: Tests.Complexity.Baseline,
            current: Tests.Complexity.Baseline
        ) {
            self.previous = previous
            self.current = current
        }

        /// Whether the complexity class worsened.
        ///
        /// A regression means the current best class is strictly worse
        /// (higher growth rate) than the baseline. If either is `nil`
        /// (inconclusive), this returns `false` — inconclusiveness is
        /// reported separately.
        public var classRegressed: Bool {
            guard let prev = previous.bestClass,
                  let curr = current.bestClass
            else { return false }
            return curr > prev
        }

        /// Whether the complexity class improved.
        public var classImproved: Bool {
            guard let prev = previous.bestClass,
                  let curr = current.bestClass
            else { return false }
            return curr < prev
        }

        /// Whether the complexity class changed at all.
        public var classChanged: Bool {
            previous.bestClass != current.bestClass
        }

        /// Absolute change in the continuous exponent (current - previous).
        public var exponentDrift: Double {
            current.exponent - previous.exponent
        }

        /// Whether the exponent drifted by more than the given tolerance.
        public func exponentDriftExceeds(_ tolerance: Double) -> Bool {
            Swift.abs(exponentDrift) > tolerance
        }

        /// Whether the confidence level degraded.
        public var confidenceDegraded: Bool {
            current.confidence.order < previous.confidence.order
        }

        /// Whether any regression signal is present.
        ///
        /// Returns `true` if the class regressed OR the exponent drifted
        /// upward by more than 0.3 (default tolerance).
        public var isRegression: Bool {
            classRegressed || exponentDrift > 0.3
        }
    }
}
