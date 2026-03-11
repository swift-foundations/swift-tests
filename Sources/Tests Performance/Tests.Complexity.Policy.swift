//
//  Tests.Complexity.Policy.swift
//  swift-tests
//
//  Configurable thresholds for complexity classification.
//

public import Test_Primitives

extension Tests.Complexity {
    /// Configurable thresholds for complexity classification.
    ///
    /// All numeric values in this struct are **provisional** — they are
    /// implementation heuristics for the prototype, not normative API
    /// constants. They must be validated against a calibration suite of
    /// synthetic workloads before standardization.
    public struct Policy: Sendable {
        /// Candidate complexity classes to fit against.
        ///
        /// Default excludes ``Test/Benchmark/Complexity/Class/squareRoot``
        /// and ``Test/Benchmark/Complexity/Class/exponential`` for robustness.
        public var candidateClasses: [Test.Benchmark.Complexity.Class]

        /// Minimum number of size points required.
        public var minimumSizePoints: Int

        /// Minimum ratio between largest and smallest input size.
        ///
        /// For example, 100.0 means sizes must span at least 2 orders
        /// of magnitude (e.g., 100 to 10,000).
        public var minimumScaleRange: Double

        /// Minimum R² for the log-log regression to be considered valid.
        public var logLogRSquaredFloor: Double

        /// Minimum R² for a discrete candidate to be considered viable.
        public var candidateRSquaredFloor: Double

        /// R² gap above which the winner has high confidence.
        public var highSeparationThreshold: Double

        /// R² gap above which the winner has medium confidence.
        public var mediumSeparationThreshold: Double

        /// Maximum exponent deviation before cross-validation fails.
        public var exponentConsistencyTolerance: Double

        public init(
            candidateClasses: [Test.Benchmark.Complexity.Class],
            minimumSizePoints: Int,
            minimumScaleRange: Double,
            logLogRSquaredFloor: Double,
            candidateRSquaredFloor: Double,
            highSeparationThreshold: Double,
            mediumSeparationThreshold: Double,
            exponentConsistencyTolerance: Double
        ) {
            self.candidateClasses = candidateClasses
            self.minimumSizePoints = minimumSizePoints
            self.minimumScaleRange = minimumScaleRange
            self.logLogRSquaredFloor = logLogRSquaredFloor
            self.candidateRSquaredFloor = candidateRSquaredFloor
            self.highSeparationThreshold = highSeparationThreshold
            self.mediumSeparationThreshold = mediumSeparationThreshold
            self.exponentConsistencyTolerance = exponentConsistencyTolerance
        }

        /// Default policy with provisional thresholds.
        ///
        /// These values are implementation heuristics pending calibration.
        public static var `default`: Policy {
            Policy(
                candidateClasses: [
                    .constant,
                    .logarithmic,
                    .linear,
                    .linearithmic,
                    .quadratic,
                    .cubic,
                ],
                minimumSizePoints: 4,
                minimumScaleRange: 100.0,
                logLogRSquaredFloor: 0.80,
                candidateRSquaredFloor: 0.85,
                highSeparationThreshold: 0.03,
                mediumSeparationThreshold: 0.01,
                exponentConsistencyTolerance: 0.3
            )
        }
    }
}
