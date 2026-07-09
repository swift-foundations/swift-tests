//
//  Tests.Complexity.Calibration Tests.swift
//  swift-tests
//
//  Calibration suite: validates classification thresholds against
//  synthetic workloads with known complexity classes.
//

import Real_Primitives
import Testing
import Tests_Test_Support

private typealias SUT = Test_Primitives.Test

/// Calibration suite for complexity classification thresholds.
///
/// Each test constructs synthetic timing data for a known complexity
/// class and verifies that the default policy classifies it correctly.
/// These tests validate the provisional threshold values and catch
/// regressions if thresholds are tuned.
// NOTE: Tests.Complexity already carries a Test suite (see "Tests.Complexity
// Tests.swift"). Per [SWIFT-TEST-002] collision rule, "Calibration" is the
// leftover token from the original suite name "ComplexityCalibrationTests"
// and does not collide with any existing category under Tests.Complexity.Test,
// so it nests there.
extension Tests.Complexity.Test {
    @Suite struct Calibration {
        @Suite struct PowerLaw {}
        @Suite struct NonPowerLaw {}
        @Suite struct Ambiguity {}
    }
}

// MARK: - Sizes

extension Tests.Complexity.Test.Calibration {
    /// 10 points spanning 4.5 orders of magnitude.
    static let sizes = [
        100, 300, 1_000, 3_000, 10_000,
        30_000, 100_000, 300_000, 1_000_000, 3_000_000,
    ]

    fileprivate static let classes: [SUT.Benchmark.Complexity.Class] = [
        .constant, .logarithmic, .linear, .linearithmic, .quadratic, .cubic,
    ]

    fileprivate static func evidence(
        _ transform: (Double) -> Double
    ) -> SUT.Benchmark.Complexity.Evidence {
        let points: [(size: Int, metric: Duration)] = sizes.map { n in
            let seconds = transform(Double(n))
            return (size: n, metric: Duration.seconds(seconds))
        }
        return SUT.Benchmark.Complexity.evidence(from: points, classes: classes)
    }
}

// MARK: - Power Law Classes

extension Tests.Complexity.Test.Calibration.PowerLaw {

    @Test
    func `O(1) constant`() {
        let evidence = Tests.Complexity.Test.Calibration.evidence { _ in 0.005 }
        let result = Tests.Complexity.classify(evidence)

        // Constant data detected via CV-based pathway (metricCV ≈ 0).
        #expect(result.best?.complexity == .constant)
        #expect(result.confidence == .high)
    }

    @Test
    func `O(sqrt n) square root with default policy flags inconsistency`() {
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in 1e-6 * n.squareRoot() }
        let result = Tests.Complexity.classify(evidence)

        // Exponent ≈ 0.5 but best discrete candidate is logarithmic or linear.
        // The effective exponent of the winner diverges from the observed 0.5,
        // so cross-validation should flag inconsistentSignals.
        #expect(abs(evidence.exponent.value - 0.5) < 0.1)
        if let best = result.best {
            let hasInconsistency = result.reasons.contains(.inconsistentSignals)
            let isLowConfidence = result.confidence == .low || result.confidence == .medium
            #expect(hasInconsistency || isLowConfidence)
        }
    }

    @Test
    func `O(sqrt n) with squareRoot in candidates classifies correctly`() {
        // Evidence must be constructed with squareRoot in the candidate set.
        let classesWithSqrt = Tests.Complexity.Test.Calibration.classes + [.squareRoot]
        let points: [(size: Int, metric: Duration)] = Tests.Complexity.Test.Calibration.sizes.map { n in
            (size: n, metric: Duration.seconds(1e-6 * Double(n).squareRoot()))
        }
        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: classesWithSqrt
        )
        var policy = Tests.Complexity.Policy.default
        policy.candidateClasses.append(.squareRoot)

        let result = Tests.Complexity.classify(evidence, under: policy)

        // With squareRoot in the candidate set, it should be selected.
        #expect(result.best?.complexity == .squareRoot)
        #expect(result.confidence != .inconclusive)
        #expect(abs(evidence.exponent.value - 0.5) < 0.1)
    }

    @Test
    func `O(n) linear`() {
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in 1e-8 * n }
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .linear)
        #expect(result.confidence != .inconclusive)
        #expect(abs(evidence.exponent.value - 1.0) < 0.1)
    }

    @Test
    func `O(n squared) quadratic`() {
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in 1e-12 * n * n }
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .quadratic)
        #expect(result.confidence != .inconclusive)
        #expect(abs(evidence.exponent.value - 2.0) < 0.1)
    }

    @Test
    func `O(n cubed) cubic`() {
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in 1e-17 * n * n * n }
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .cubic)
        #expect(result.confidence != .inconclusive)
        #expect(abs(evidence.exponent.value - 3.0) < 0.1)
    }
}

// MARK: - Non-Power-Law Classes

extension Tests.Complexity.Test.Calibration.NonPowerLaw {

    @Test
    func `O(log n) logarithmic`() {
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in
            1e-4 * Double.math.log2(n)
        }
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .logarithmic)
        #expect(result.confidence != .inconclusive)
    }

    @Test
    func `O(n log n) linearithmic`() {
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in
            1e-9 * n * Double.math.log2(n)
        }
        let result = Tests.Complexity.classify(evidence)

        // Linearithmic may classify as linear or linearithmic —
        // both are acceptable due to the inherent ambiguity.
        #expect(result.best != nil)
        #expect(result.confidence != .inconclusive)
        #expect(
            result.isCompatible(with: .linearithmic)
                || result.isCompatible(with: .linear)
        )
    }
}

// MARK: - Ambiguity Cases

extension Tests.Complexity.Test.Calibration.Ambiguity {

    @Test
    func `linear vs linearithmic ambiguity is reported`() {
        // Pure linear data — linearithmic should appear as ambiguous
        // since log factor grows slowly.
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in 1e-8 * n }
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .linear)
        // The framework honestly reports that linearithmic is also plausible.
        #expect(result.ambiguousWith.contains(.linearithmic))
    }

    @Test
    func `noisy data with 5 percent jitter still classifies`() {
        // Quadratic with deterministic pseudo-noise.
        var seed: UInt64 = 42
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in
            // Simple LCG for deterministic "noise".
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let noise = 1.0 + 0.05 * (Double(seed >> 33) / Double(UInt32.max) - 0.5)
            return 1e-12 * n * n * noise
        }
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .quadratic)
        #expect(result.confidence != .inconclusive)
    }

    @Test
    func `exponent cross-validation detects mismatch`() {
        // Data that follows n^1.5 — between linear and quadratic.
        // The discrete best candidate will be one of them, but the
        // continuous exponent (1.5) won't match either's effective
        // exponent, triggering inconsistentSignals.
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in
            1e-10 * n * n.squareRoot()
        }
        let result = Tests.Complexity.classify(evidence)

        #expect(abs(evidence.exponent.value - 1.5) < 0.1)
        // Expect either a downgraded confidence or inconsistentSignals reason.
        if result.best != nil {
            let hasInconsistency = result.reasons.contains(.inconsistentSignals)
            let isLowConfidence = result.confidence == .low || result.confidence == .medium
            #expect(hasInconsistency || isLowConfidence)
        }
    }

    @Test(arguments: [0.05, 0.10, 0.15, 0.20, 0.25])
    func `quadratic classification robust to noise`(noiseLevel: Double) {
        // Quadratic data with increasing noise levels.
        // Uses deterministic LCG noise for reproducibility.
        var seed: UInt64 = 42
        let evidence = Tests.Complexity.Test.Calibration.evidence { n in
            seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            let jitter = 1.0 + noiseLevel * (Double(seed >> 33) / Double(UInt32.max) - 0.5)
            return 1e-12 * n * n * jitter
        }
        let result = Tests.Complexity.classify(evidence)

        // Up to ~15% noise should still classify as quadratic.
        // Above that, classification may degrade but should not crash.
        if noiseLevel <= 0.15 {
            #expect(result.best?.complexity == .quadratic)
            #expect(result.confidence != .inconclusive)
        }
        // At all noise levels, the exponent should be near 2.0.
        #expect(abs(evidence.exponent.value - 2.0) < 0.5 + noiseLevel)
    }
}
