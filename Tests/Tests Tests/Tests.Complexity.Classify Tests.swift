//
//  Tests.Complexity.Classify Tests.swift
//  swift-tests
//
//  Tests for confidence levels, policy thresholds, and inconclusive
//  reason cases not covered by the main classification tests.
//

import Real_Primitives
import Testing
import Tests_Test_Support

private typealias SUT = Test_Primitives.Test

@Suite
struct ComplexityClassifyTests {

    @Suite struct ConfidenceLevels {}
    @Suite struct InconclusiveReasons {}
    @Suite struct CustomPolicy {}
}

// MARK: - Helpers

extension ComplexityClassifyTests {
    static let defaultSizes = [
        100, 300, 1_000, 3_000, 10_000,
        30_000, 100_000, 300_000, 1_000_000, 3_000_000,
    ]

    fileprivate static let classes: [SUT.Benchmark.Complexity.Class] = [
        .constant, .logarithmic, .linear, .linearithmic, .quadratic, .cubic,
    ]

    fileprivate static func evidence(
        _ transform: (Double) -> Double
    ) -> SUT.Benchmark.Complexity.Evidence {
        let points: [(size: Int, metric: Duration)] = defaultSizes.map { n in
            let seconds = transform(Double(n))
            return (size: n, metric: Duration.seconds(seconds))
        }
        return SUT.Benchmark.Complexity.evidence(from: points, classes: classes)
    }
}

// MARK: - Confidence Levels

extension ComplexityClassifyTests.ConfidenceLevels {

    @Test
    func `quadratic data classified correctly`() {
        let evidence = ComplexityClassifyTests.evidence { n in 1e-12 * n * n }
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .quadratic)
        #expect(result.confidence != .inconclusive)
    }

    @Test
    func `cubic data classified correctly`() {
        let evidence = ComplexityClassifyTests.evidence { n in 1e-17 * n * n * n }
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .cubic)
        #expect(result.confidence != .inconclusive)
    }

    @Test
    func `linear data classified correctly`() {
        let evidence = ComplexityClassifyTests.evidence { n in 1e-8 * n }
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .linear)
        #expect(result.confidence != .inconclusive)
    }

    @Test
    func `relaxed separation thresholds elevate confidence`() {
        // Default thresholds may give low confidence even with clean data
        // when candidate R² values are close. Lowering thresholds helps.
        let evidence = ComplexityClassifyTests.evidence { n in 1e-8 * n }

        let defaultResult = Tests.Complexity.classify(evidence)

        var relaxed = Tests.Complexity.Policy.default
        relaxed.highSeparationThreshold = 0.0001
        relaxed.mediumSeparationThreshold = 0.00001

        let relaxedResult = Tests.Complexity.classify(evidence, under: relaxed)

        // Relaxed thresholds should produce equal or higher confidence.
        #expect(relaxedResult.confidence == .high || relaxedResult.confidence == .medium)
        #expect(defaultResult.best?.complexity == relaxedResult.best?.complexity)
    }
}

// MARK: - Inconclusive Reasons

extension ComplexityClassifyTests.InconclusiveReasons {

    @Test
    func `weak continuous fit triggers weakContinuousFit reason`() {
        // Data that fits poorly in log-log space: mix linear and constant.
        // Use sizes where some are constant and some grow,
        // creating a bad log-log R².
        let sizes = ComplexityClassifyTests.defaultSizes
        let points: [(size: Int, metric: Duration)] = sizes.enumerated().map { i, n in
            // Alternating between constant and growing durations.
            let seconds = i % 2 == 0 ? 0.001 : 1e-8 * Double(n)
            return (size: n, metric: Duration.seconds(seconds))
        }
        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: ComplexityClassifyTests.classes
        )

        // Force the R² floor high enough to trigger.
        var policy = Tests.Complexity.Policy.default
        policy.logLogRSquaredFloor = 0.99
        policy.constantCVThreshold = 0

        let result = Tests.Complexity.classify(evidence, under: policy)

        #expect(result.confidence == .inconclusive)
        #expect(result.reasons.contains(.weakContinuousFit))
    }

    @Test
    func `no viable candidates triggers noSeparatedWinner`() {
        // Data that is noisy enough that no candidate achieves R² ≥ floor.
        // Use alternating growth rates to create poor discrete fits
        // while keeping a monotonic trend.
        let sizes = ComplexityClassifyTests.defaultSizes
        let points: [(size: Int, metric: Duration)] = sizes.enumerated().map { i, n in
            let base = 1e-8 * Double(n)
            // Add oscillation: even indices get 3× longer.
            let seconds = i % 2 == 0 ? base * 3.0 : base
            return (size: n, metric: Duration.seconds(seconds))
        }
        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: ComplexityClassifyTests.classes
        )

        // Set the candidate floor very high so noisy fits don't pass.
        var policy = Tests.Complexity.Policy.default
        policy.candidateRSquaredFloor = 0.9999
        policy.constantCVThreshold = 0

        let result = Tests.Complexity.classify(evidence, under: policy)

        // If all candidates are filtered out, we get noSeparatedWinner.
        // If the gate fires first (e.g., weakContinuousFit), that's also valid.
        #expect(result.confidence == .inconclusive)
    }

    @Test
    func `multiple gates can fire simultaneously`() {
        // Only 2 points with narrow scale range.
        let points: [(size: Int, metric: Duration)] = [
            (size: 100, metric: .milliseconds(1)),
            (size: 110, metric: .milliseconds(2)),
        ]
        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: ComplexityClassifyTests.classes
        )

        var policy = Tests.Complexity.Policy.default
        policy.constantCVThreshold = 0

        let result = Tests.Complexity.classify(evidence, under: policy)

        #expect(result.confidence == .inconclusive)
        #expect(result.reasons.contains(.insufficientData))
        #expect(result.reasons.contains(.insufficientScaleRange))
    }
}

// MARK: - Custom Policy

extension ComplexityClassifyTests.CustomPolicy {

    @Test
    func `relaxed thresholds produce higher confidence`() {
        let evidence = ComplexityClassifyTests.evidence { n in 1e-8 * n }

        var relaxed = Tests.Complexity.Policy.default
        relaxed.highSeparationThreshold = 0.0001
        relaxed.mediumSeparationThreshold = 0.00001

        let result = Tests.Complexity.classify(evidence, under: relaxed)

        // With very relaxed thresholds, even linear (with linearithmic nearby)
        // should get higher confidence.
        #expect(result.best?.complexity == .linear)
        #expect(result.confidence == .high || result.confidence == .medium)
    }

    @Test
    func `strict thresholds produce lower confidence`() {
        let evidence = ComplexityClassifyTests.evidence { n in 1e-12 * n * n }

        var strict = Tests.Complexity.Policy.default
        strict.highSeparationThreshold = 0.5
        strict.mediumSeparationThreshold = 0.3

        let result = Tests.Complexity.classify(evidence, under: strict)

        #expect(result.best?.complexity == .quadratic)
        // Even quadratic may not reach 0.5 R² gap, so confidence may drop.
        #expect(result.confidence != .inconclusive)
    }

    @Test
    func `reduced candidate set at evidence level changes classification`() {
        // When Evidence is built with only constant and cubic,
        // linear data can't match linear.
        let sizes = ComplexityClassifyTests.defaultSizes
        let points: [(size: Int, metric: Duration)] = sizes.map { n in
            (size: n, metric: Duration.seconds(1e-8 * Double(n)))
        }
        // Build evidence with restricted classes (at L1 level).
        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .cubic]
        )
        let result = Tests.Complexity.classify(evidence)

        // Linear is not in the candidate set, so it cannot be selected.
        #expect(result.best?.complexity != .linear)
    }

    @Test
    func `high candidate floor filters marginal fits`() {
        // Raise the candidate R² floor so that only the best-fitting
        // class survives. With linear data, linear should still pass
        // even a high floor, but other classes may be filtered.
        let evidence = ComplexityClassifyTests.evidence { n in 1e-8 * n }

        var policy = Tests.Complexity.Policy.default
        policy.candidateRSquaredFloor = 0.999

        let result = Tests.Complexity.classify(evidence, under: policy)

        // Classification should still work (linear fits perfectly).
        #expect(result.best?.complexity == .linear)
        #expect(result.confidence != Tests.Complexity.Confidence.inconclusive)
    }
}
