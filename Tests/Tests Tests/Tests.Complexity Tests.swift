//
//  Tests.Complexity Tests.swift
//  swift-tests
//
//  Unit tests for policy-based complexity classification.
//

import Testing
import Tests_Test_Support

private typealias SUT = Test_Primitives.Test

extension Tests.Complexity {
    @Suite
    struct Test {
        @Suite struct Classify {}
        @Suite struct Result {}
        @Suite struct Sizes {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Helpers

extension Tests.Complexity.Test {
    /// Default sizes spanning 5 orders of magnitude (10 points).
    /// Mann-Kendall needs ≥10 points for z-score significance.
    static let defaultSizes = [
        100, 300, 1_000, 3_000, 10_000,
        30_000, 100_000, 300_000, 1_000_000, 3_000_000,
    ]

    /// Builds linear evidence: T(n) = c · n.
    fileprivate static func linearEvidence(
        coefficient c: Double = 1e-8,
        sizes: [Int] = defaultSizes
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
        coefficient c: Double = 1e-12,
        sizes: [Int] = defaultSizes
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
        coefficient c: Double = 1e-17,
        sizes: [Int] = defaultSizes
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

extension Tests.Complexity.Test.Classify {

    @Test
    func `linear data classified as linear`() {
        let evidence = Tests.Complexity.Test.linearEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .linear)
        #expect(result.confidence != .inconclusive)
        #expect(result.isCompatible(with: .linear))
        // Linear and linearithmic are legitimately hard to separate,
        // so linearithmic may appear in the ambiguous set.
    }

    @Test
    func `quadratic data classified as quadratic`() {
        let evidence = Tests.Complexity.Test.quadraticEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .quadratic)
        #expect(result.isCompatible(with: .quadratic))
    }

    @Test
    func `cubic data classified as cubic`() {
        let evidence = Tests.Complexity.Test.cubicEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .cubic)
        #expect(result.isCompatible(with: .cubic))
    }

    @Test
    func `insufficient data points yields inconclusive`() {
        let evidence = Tests.Complexity.Test.linearEvidence(sizes: [100, 1_000])
        var policy = Tests.Complexity.Policy.default
        policy.minimumSizePoints = 4

        let result = Tests.Complexity.classify(evidence, under: policy)

        #expect(result.confidence == .inconclusive)
        #expect(result.reasons.contains(.insufficientData))
    }

    @Test
    func `insufficient scale range yields inconclusive`() {
        let evidence = Tests.Complexity.Test.linearEvidence(
            sizes: [100, 110, 120, 130, 140]
        )

        let result = Tests.Complexity.classify(evidence)

        #expect(result.confidence == .inconclusive)
        #expect(result.reasons.contains(.insufficientScaleRange))
    }

    @Test
    func `minimum size points succeeds with clean data`() {
        // Exactly 5 points (the default minimum) with clear quadratic data.
        let sizes = [100, 1_000, 10_000, 100_000, 1_000_000]
        let evidence = Tests.Complexity.Test.quadraticEvidence(sizes: sizes)
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .quadratic)
        #expect(result.confidence != .inconclusive)
    }
}

// MARK: - Result assertions

extension Tests.Complexity.Test.Result {

    @Test
    func `isNoWorseThan accepts lower complexity`() {
        let evidence = Tests.Complexity.Test.linearEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(result.isNoWorseThan(.quadratic))
        // Linear may have linearithmic in ambiguousWith, so
        // isNoWorseThan(.linear) can fail. Test the bound instead.
        #expect(result.isNoWorseThan(.linearithmic))
    }

    @Test
    func `isNoWorseThan rejects higher complexity`() {
        let evidence = Tests.Complexity.Test.quadraticEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(!result.isNoWorseThan(.linear))
    }

    @Test
    func `inconclusive result fails isNoWorseThan`() {
        let evidence = Tests.Complexity.Test.linearEvidence(sizes: [100, 1_000])
        var policy = Tests.Complexity.Policy.default
        policy.minimumSizePoints = 4

        let result = Tests.Complexity.classify(evidence, under: policy)

        #expect(!result.isNoWorseThan(.cubic))
    }

    @Test
    func `isCompatible returns false for wrong class`() {
        let evidence = Tests.Complexity.Test.quadraticEvidence()
        let result = Tests.Complexity.classify(evidence)

        #expect(!result.isCompatible(with: .logarithmic))
        #expect(!result.isCompatible(with: .constant))
    }
}

// MARK: - Sizes helper

extension Tests.Complexity.Test.Sizes {

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

extension Tests.Complexity.Test.EdgeCase {

    @Test
    func `constant data classified as constant`() {
        // T(n) = constant, regardless of n. Uses enough points for
        // Mann-Kendall and scale range requirements.
        let sizes = [
            100, 300, 1_000, 3_000, 10_000,
            30_000, 100_000, 300_000, 1_000_000, 3_000_000,
        ]
        let points: [(size: Int, metric: Duration)] = sizes.map { n in
            (size: n, metric: Duration.milliseconds(50))
        }

        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .quadratic]
        )
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .constant)
        #expect(result.confidence == .high)
    }

    @Test
    func `near-constant data with low noise classified as constant`() {
        // T(n) = 50ms ± small noise (CV ≈ 3%).
        let sizes = [
            100, 300, 1_000, 3_000, 10_000,
            30_000, 100_000, 300_000, 1_000_000, 3_000_000,
        ]
        // Deterministic slight variation per size.
        let durations: [Duration] = [49, 51, 48, 52, 50, 49, 51, 48, 52, 50]
            .map { Duration.milliseconds($0) }

        let points: [(size: Int, metric: Duration)] = zip(sizes, durations)
            .map { (size: $0, metric: $1) }

        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .quadratic]
        )
        let result = Tests.Complexity.classify(evidence)

        #expect(result.best?.complexity == .constant)
        #expect(result.confidence != .inconclusive)
    }

    @Test
    func `constant detection disabled when CV threshold is zero`() {
        let sizes = [
            100, 300, 1_000, 3_000, 10_000,
            30_000, 100_000, 300_000, 1_000_000, 3_000_000,
        ]
        let points: [(size: Int, metric: Duration)] = sizes.map { n in
            (size: n, metric: Duration.milliseconds(50))
        }

        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .quadratic]
        )
        var policy = Tests.Complexity.Policy.default
        policy.constantCVThreshold = 0

        let result = Tests.Complexity.classify(evidence, under: policy)

        // With constant detection disabled, the non-monotone gate fires.
        #expect(result.confidence == .inconclusive)
        #expect(result.reasons.contains(.nonMonotone))
    }
}
