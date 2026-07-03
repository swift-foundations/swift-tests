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
        ///
        /// Must be at least 5 for Mann-Kendall monotonicity testing to
        /// reach statistical significance (α = 0.05) with perfectly
        /// monotonic data. Recommend 8+ for noisy real-world benchmarks.
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

        /// Minimum exponent deviation before cross-validation fails.
        ///
        /// This is the **floor** of the tolerance. The actual tolerance
        /// applied is `max(this, 0.3 × |effectiveExponent|)`, so higher
        /// exponents tolerate proportionally more noise. For sublinear
        /// classes (logarithmic, √n) the floor dominates, keeping
        /// cross-validation tight enough to catch misclassifications.
        public var exponentConsistencyTolerance: Double

        /// Maximum coefficient of variation for constant-time detection.
        ///
        /// When durations show no monotonic trend and their CV across
        /// sizes is below this threshold, the data is classified as
        /// constant-time without relying on OLS. Set to 0 to disable.
        ///
        /// Confidence scales with CV relative to this threshold:
        /// - CV < threshold × 0.2 → high confidence
        /// - CV < threshold × 0.5 → medium confidence
        /// - CV < threshold → low confidence
        public var constantCVThreshold: Double

        public init(
            candidateClasses: [Test.Benchmark.Complexity.Class],
            minimumSizePoints: Int,
            minimumScaleRange: Double,
            logLogRSquaredFloor: Double,
            candidateRSquaredFloor: Double,
            highSeparationThreshold: Double,
            mediumSeparationThreshold: Double,
            exponentConsistencyTolerance: Double,
            constantCVThreshold: Double
        ) {
            self.candidateClasses = candidateClasses
            self.minimumSizePoints = minimumSizePoints
            self.minimumScaleRange = minimumScaleRange
            self.logLogRSquaredFloor = logLogRSquaredFloor
            self.candidateRSquaredFloor = candidateRSquaredFloor
            self.highSeparationThreshold = highSeparationThreshold
            self.mediumSeparationThreshold = mediumSeparationThreshold
            self.exponentConsistencyTolerance = exponentConsistencyTolerance
            self.constantCVThreshold = constantCVThreshold
        }

        /// Default policy with provisional thresholds.
        ///
        /// These values are implementation heuristics pending calibration.
        public static var `default`: Self {
            Self(
                candidateClasses: [
                    .constant,
                    .logarithmic,
                    .linear,
                    .linearithmic,
                    .quadratic,
                    .cubic,
                ],
                minimumSizePoints: 5,
                minimumScaleRange: 100.0,
                logLogRSquaredFloor: 0.80,
                candidateRSquaredFloor: 0.85,
                highSeparationThreshold: 0.03,
                mediumSeparationThreshold: 0.01,
                exponentConsistencyTolerance: 0.2,
                constantCVThreshold: 0.10
            )
        }
    }
}
