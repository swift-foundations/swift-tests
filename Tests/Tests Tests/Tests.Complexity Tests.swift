//
//  Tests.Complexity Tests.swift
//  swift-tests
//
//  Unit tests for policy-based complexity classification.
//

import Testing
import Tests_Test_Support

fileprivate typealias SUT = Test_Primitives.Test

@Suite
struct TestsComplexityTests {

    @Suite struct Classify {}
    @Suite struct Result {}
    @Suite struct Sizes {}
    @Suite struct EdgeCase {}
}

// MARK: - Helpers

extension TestsComplexityTests {
    /// Builds linear evidence: T(n) = c · n.
    fileprivate static func linearEvidence(
        coefficient c: Double = 1e-6,
        sizes: [Int] = [100, 1_000, 10_000, 100_000]
    ) -> SUT.Benchmark.Complexity.Evidence {
        let points: [(size: Int, metric: Duration)] = sizes.map { n in
            (size: n, metric: Duration.seconds(c * Double(n)))
        }
        return SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .linearithmic, .quadratic, .cubic]
        )
    }

    /// Builds quadratic evidence: T(n) = c · n².
    fileprivate static func quadraticEvidence(
        coefficient c: Double = 1e-9,
        sizes: [Int] = [100, 1_000, 10_000, 100_000]
    ) -> SUT.Benchmark.Complexity.Evidence {
        let points: [(size: Int, metric: Duration)] = sizes.map { n in
            let nD = Double(n)
            return (size: n, metric: Duration.seconds(c * nD * nD))
        }
        return SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .linearithmic, .quadratic, .cubic]
        )
    }

    /// Builds cubic evidence: T(n) = c · n³.
    fileprivate static func cubicEvidence(
        coefficient c: Double = 1e-12,
        sizes: [Int] = [100, 1_000, 10_000]
    ) -> SUT.Benchmark.Complexity.Evidence {
        let points: [(size: Int, metric: Duration)] = sizes.map { n in
            let nD = Double(n)
            return (size: n, metric: Duration.seconds(c * nD * nD * nD))
        }
        return SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .linearithmic, .quadratic, .cubic]
        )
    }
}

// MARK: - Classify

extension TestsComplexityTests.Classify {

    @Test
    func `linear data classified as linear with high confidence`() {
        let evidence = TestsComplexityTests.linearEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .linear)
        #expect(result.confidence == .high)
        #expect(result.isCompatible(with: .linear))
    }

    @Test
    func `quadratic data classified as quadratic`() {
        let evidence = TestsComplexityTests.quadraticEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .quadratic)
        #expect(result.isCompatible(with: .quadratic))
    }

    @Test
    func `cubic data classified as cubic`() {
        let evidence = TestsComplexityTests.cubicEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .cubic)
        #expect(result.isCompatible(with: .cubic))
    }

    @Test
    func `insufficient data points yields inconclusive`() {
        let evidence = TestsComplexityTests.linearEvidence(sizes: [100, 1_000])
        var policy = Tests.Complexity.Policy.default
        policy.minimumSizePoints = 4

        let result = Tests.Complexity.classify(evidence, under: policy)

        #expect(result.confidence == .inconclusive)
        #expect(result.reasons.contains(.insufficientData))
    }

    @Test
    func `insufficient scale range yields inconclusive`() {
        let evidence = TestsComplexityTests.linearEvidence(
            sizes: [100, 110, 120, 130]
        )

        let result = Tests.Complexity.classify(evidence)

        #expect(result.confidence == .inconclusive)
        #expect(result.reasons.contains(.insufficientScaleRange))
    }
}

// MARK: - Result assertions

extension TestsComplexityTests.Result {

    @Test
    func `isNoWorseThan accepts lower complexity`() {
        let evidence = TestsComplexityTests.linearEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(result.isNoWorseThan(.quadratic))
        #expect(result.isNoWorseThan(.linear))
    }

    @Test
    func `isNoWorseThan rejects higher complexity`() {
        let evidence = TestsComplexityTests.quadraticEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(!result.isNoWorseThan(.linear))
    }

    @Test
    func `inconclusive result fails isNoWorseThan`() {
        let evidence = TestsComplexityTests.linearEvidence(sizes: [100, 1_000])
        var policy = Tests.Complexity.Policy.default
        policy.minimumSizePoints = 4

        let result = Tests.Complexity.classify(evidence, under: policy)

        #expect(!result.isNoWorseThan(.cubic))
    }

    @Test
    func `isCompatible returns false for wrong class`() {
        let evidence = TestsComplexityTests.quadraticEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(!result.isCompatible(with: .logarithmic))
        #expect(!result.isCompatible(with: .constant))
    }
}

// MARK: - Sizes helper

extension TestsComplexityTests.Sizes {

    @Test
    func `default factor of 10`() {
        let sizes = Tests.Complexity.sizes(from: 100, through: 1_000_000)
        #expect(sizes == [100, 1_000, 10_000, 100_000, 1_000_000])
    }

    @Test
    func `custom factor`() {
        let sizes = Tests.Complexity.sizes(from: 1, through: 16, factor: 2)
        #expect(sizes == [1, 2, 4, 8, 16])
    }

    @Test
    func `single element when from equals through`() {
        let sizes = Tests.Complexity.sizes(from: 100, through: 100)
        #expect(sizes == [100])
    }

    @Test
    func `endpoint included when reachable`() {
        let sizes = Tests.Complexity.sizes(from: 1_024, through: 1_048_576, factor: 4)
        #expect(sizes.last == 1_048_576)
    }
}

// MARK: - Edge Case

extension TestsComplexityTests.EdgeCase {

    @Test
    func `constant data is not misclassified`() {
        // T(n) = constant, regardless of n.
        let sizes = [100, 1_000, 10_000, 100_000]
        let points: [(size: Int, metric: Duration)] = sizes.map { n in
            (size: n, metric: Duration.milliseconds(50))
        }

        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .quadratic]
        )
        let result = Tests.Complexity.classify(evidence)

        // Constant data should either classify as constant or be inconclusive
        // (non-monotone gate may trigger since durations are identical).
        if let best = result.best {
            #expect(best.complexity == .constant)
        } else {
            #expect(result.confidence == .inconclusive)
        }
    }
}
