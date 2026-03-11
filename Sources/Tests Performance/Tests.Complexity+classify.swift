//
//  Tests.Complexity+classify.swift
//  swift-tests
//
//  Policy-based interpretation of complexity evidence.
//

public import Test_Primitives
import Sample_Primitives

extension Tests.Complexity {
    /// Interprets raw complexity evidence under a policy to produce a result.
    ///
    /// Applies constant-time detection, adequacy gates, monotonicity checks,
    /// fit quality thresholds, separation analysis, and cross-validation to
    /// derive a confidence level and best candidate classification.
    ///
    /// All thresholds come from the ``Policy`` and are provisional.
    ///
    /// - Parameters:
    ///   - evidence: Raw analytical evidence from L1 fitting.
    ///   - policy: Classification thresholds and candidate set.
    /// - Returns: An interpreted ``Result`` with confidence and classification.
    public static func classify(
        _ evidence: Test.Benchmark.Complexity.Evidence,
        under policy: Policy = .default
    ) -> Result {
        // Constant-time detection (before gates).
        // If data has no monotonic trend and very low variation across
        // sizes, classify as constant regardless of OLS results.
        if policy.constantCVThreshold > 0,
           evidence.monotonicity.interpretation == .none,
           evidence.metricCV < policy.constantCVThreshold,
           evidence.points.count >= policy.minimumSizePoints,
           Self.hasScaleRange(evidence, policy: policy)
        {
            let constantCandidate = evidence.candidates
                .first { $0.complexity == .constant }
                ?? Test.Benchmark.Complexity.CandidateFit(
                    complexity: .constant,
                    regression: Sample.Regression.Fit(
                        slope: 0, intercept: 0, rSquared: 0, meanSquaredError: 0
                    ),
                    effectiveExponent: 0
                )
            let confidence: Confidence
            if evidence.metricCV < policy.constantCVThreshold * 0.2 {
                confidence = .high
            } else if evidence.metricCV < policy.constantCVThreshold * 0.5 {
                confidence = .medium
            } else {
                confidence = .low
            }
            return Result(
                evidence: evidence,
                best: constantCandidate,
                confidence: confidence,
                ambiguousWith: [],
                reasons: []
            )
        }

        var reasons: [InconclusiveReason] = []

        // Gate 1: Minimum size points.
        if evidence.points.count < policy.minimumSizePoints {
            reasons.append(.insufficientData)
        }

        // Gate 2: Scale range.
        if !Self.hasScaleRange(evidence, policy: policy) {
            reasons.append(.insufficientScaleRange)
        }

        // Gate 3: Monotonicity.
        if evidence.monotonicity.interpretation == .none
            || evidence.monotonicity.interpretation == .decreasing
        {
            reasons.append(.nonMonotone)
        }

        // Gate 4: Continuous fit quality.
        if evidence.exponent.fit.rSquared < policy.logLogRSquaredFloor {
            reasons.append(.weakContinuousFit)
        }

        // If any gate failed → inconclusive.
        if !reasons.isEmpty {
            return Result(
                evidence: evidence,
                best: nil,
                confidence: .inconclusive,
                ambiguousWith: [],
                reasons: reasons
            )
        }

        // Filter viable candidates: positive slope and R² above floor.
        let viable = evidence.candidates.filter {
            $0.regression.slope > 0
                && $0.regression.rSquared >= policy.candidateRSquaredFloor
        }

        guard let best = viable.first else {
            return Result(
                evidence: evidence,
                best: nil,
                confidence: .inconclusive,
                ambiguousWith: [],
                reasons: [.noSeparatedWinner]
            )
        }

        // Separation analysis: best vs runner-up R² gap.
        let runnerUp = viable.dropFirst().first
        let separation = runnerUp.map {
            best.regression.rSquared - $0.regression.rSquared
        } ?? 1.0

        let ambiguous = viable.filter {
            $0.complexity != best.complexity
                && (best.regression.rSquared - $0.regression.rSquared)
                    < policy.mediumSeparationThreshold
        }.map(\.complexity)

        // Initial confidence from separation.
        var confidence: Confidence
        if separation >= policy.highSeparationThreshold {
            confidence = .high
        } else if separation >= policy.mediumSeparationThreshold {
            confidence = .medium
        } else {
            confidence = .low
        }

        // Cross-validation: observed exponent vs effective exponent of
        // the discrete winner. Uses proportional tolerance so that
        // sublinear classes (small effective exponent) have tight
        // cross-validation, while superlinear classes accommodate
        // proportionally more noise.
        let tolerance = Swift.max(
            policy.exponentConsistencyTolerance,
            0.3 * Swift.abs(best.effectiveExponent)
        )
        let deviation = Swift.abs(
            evidence.exponent.value - best.effectiveExponent
        )
        if deviation > tolerance {
            switch confidence {
            case .high: confidence = .medium
            case .medium: confidence = .low
            case .low, .inconclusive: break
            }
            reasons.append(.inconsistentSignals)
        }

        return Result(
            evidence: evidence,
            best: best,
            confidence: confidence,
            ambiguousWith: ambiguous,
            reasons: reasons
        )
    }

    // MARK: - Private

    private static func hasScaleRange(
        _ evidence: Test.Benchmark.Complexity.Evidence,
        policy: Policy
    ) -> Bool {
        guard let first = evidence.points.first,
              let last = evidence.points.last,
              first.size > 0
        else { return false }
        return Double(last.size) / Double(first.size) >= policy.minimumScaleRange
    }
}
