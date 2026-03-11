//
//  Tests.Complexity.Baseline Tests.swift
//  swift-tests
//
//  Tests for complexity baseline construction, comparison, and
//  JSON round-trip serialization.
//

import Testing
import Tests_Test_Support
import JSON

fileprivate typealias SUT = Test_Primitives.Test

@Suite
struct ComplexityBaselineTests {

    @Suite struct Construction {}
    @Suite struct Comparison {}
    @Suite struct JSONRoundTrip {}
}

// MARK: - Helpers

extension ComplexityBaselineTests {
    static let defaultSizes = [
        100, 300, 1_000, 3_000, 10_000,
        30_000, 100_000, 300_000, 1_000_000, 3_000_000,
    ]

    fileprivate static func linearEvidence() -> SUT.Benchmark.Complexity.Evidence {
        let points: [(size: Int, metric: Duration)] = defaultSizes.map { n in
            (size: n, metric: Duration.seconds(1e-8 * Double(n)))
        }
        return SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .linearithmic, .quadratic, .cubic]
        )
    }

    fileprivate static func quadraticEvidence() -> SUT.Benchmark.Complexity.Evidence {
        let points: [(size: Int, metric: Duration)] = defaultSizes.map { n in
            let nD = Double(n)
            return (size: n, metric: Duration.seconds(1e-12 * nD * nD))
        }
        return SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .linearithmic, .quadratic, .cubic]
        )
    }
}

// MARK: - Construction

extension ComplexityBaselineTests.Construction {

    @Test
    func `from linear result captures class and exponent`() {
        let evidence = ComplexityBaselineTests.linearEvidence()
        let result = Tests.Complexity.classify(evidence)
        let baseline = Tests.Complexity.Baseline(result: result)

        #expect(baseline.bestClass == .linear)
        #expect(abs(baseline.exponent - 1.0) < 0.2)
        #expect(baseline.confidence != .inconclusive)
        #expect(baseline.bestRSquared != nil)
        #expect(baseline.bestRSquared! > 0.9)
    }

    @Test
    func `from inconclusive result has nil class`() {
        let evidence = ComplexityBaselineTests.linearEvidence()
        var policy = Tests.Complexity.Policy.default
        policy.minimumSizePoints = 100

        let result = Tests.Complexity.classify(evidence, under: policy)
        let baseline = Tests.Complexity.Baseline(result: result)

        #expect(baseline.bestClass == nil)
        #expect(baseline.confidence == .inconclusive)
        #expect(baseline.bestRSquared == nil)
    }

    @Test
    func `from quadratic result captures quadratic class`() {
        let evidence = ComplexityBaselineTests.quadraticEvidence()
        let result = Tests.Complexity.classify(evidence)
        let baseline = Tests.Complexity.Baseline(result: result)

        #expect(baseline.bestClass == .quadratic)
        #expect(abs(baseline.exponent - 2.0) < 0.2)
    }
}

// MARK: - Comparison

extension ComplexityBaselineTests.Comparison {

    @Test
    func `class regression detected when class worsens`() {
        let previous = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.0, confidence: .high, bestRSquared: 0.99
        )
        let current = Tests.Complexity.Baseline(
            bestClass: .quadratic, exponent: 2.0, confidence: .high, bestRSquared: 0.99
        )

        let comparison = Tests.Complexity.Baseline.Comparison(
            previous: previous, current: current
        )

        #expect(comparison.classRegressed)
        #expect(!comparison.classImproved)
        #expect(comparison.classChanged)
        #expect(comparison.isRegression)
    }

    @Test
    func `class improvement detected when class improves`() {
        let previous = Tests.Complexity.Baseline(
            bestClass: .quadratic, exponent: 2.0, confidence: .high, bestRSquared: 0.99
        )
        let current = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.0, confidence: .high, bestRSquared: 0.99
        )

        let comparison = Tests.Complexity.Baseline.Comparison(
            previous: previous, current: current
        )

        #expect(!comparison.classRegressed)
        #expect(comparison.classImproved)
        #expect(comparison.classChanged)
        #expect(!comparison.isRegression)
    }

    @Test
    func `no change when class and exponent are stable`() {
        let previous = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.05, confidence: .high, bestRSquared: 0.99
        )
        let current = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.08, confidence: .high, bestRSquared: 0.99
        )

        let comparison = Tests.Complexity.Baseline.Comparison(
            previous: previous, current: current
        )

        #expect(!comparison.classRegressed)
        #expect(!comparison.classImproved)
        #expect(!comparison.classChanged)
        #expect(!comparison.isRegression)
        #expect(!comparison.exponentDriftExceeds(0.3))
    }

    @Test
    func `exponent drift detected without class change`() {
        let previous = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.0, confidence: .high, bestRSquared: 0.99
        )
        let current = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.5, confidence: .high, bestRSquared: 0.99
        )

        let comparison = Tests.Complexity.Baseline.Comparison(
            previous: previous, current: current
        )

        #expect(!comparison.classChanged)
        #expect(comparison.exponentDrift == 0.5)
        #expect(comparison.exponentDriftExceeds(0.3))
        #expect(comparison.isRegression)
    }

    @Test
    func `confidence degradation detected`() {
        let previous = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.0, confidence: .high, bestRSquared: 0.99
        )
        let current = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.0, confidence: .low, bestRSquared: 0.90
        )

        let comparison = Tests.Complexity.Baseline.Comparison(
            previous: previous, current: current
        )

        #expect(comparison.confidenceDegraded)
    }

    @Test
    func `nil class does not trigger regression`() {
        let previous = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.0, confidence: .high, bestRSquared: 0.99
        )
        let current = Tests.Complexity.Baseline(
            bestClass: nil, exponent: 0.5, confidence: .inconclusive, bestRSquared: nil
        )

        let comparison = Tests.Complexity.Baseline.Comparison(
            previous: previous, current: current
        )

        // nil class -> classRegressed is false (nil-safety)
        #expect(!comparison.classRegressed)
        #expect(!comparison.classImproved)
        #expect(comparison.classChanged)
    }
}

// MARK: - JSON Round Trip

extension ComplexityBaselineTests.JSONRoundTrip {

    @Test
    func `linear baseline survives round trip`() throws {
        let original = Tests.Complexity.Baseline(
            bestClass: .linear, exponent: 1.05, confidence: .high, bestRSquared: 0.9987
        )

        let bytes = original.jsonBytes(pretty: true)
        let restored = try Tests.Complexity.Baseline(jsonBytes: bytes)

        #expect(restored.bestClass == .linear)
        #expect(abs(restored.exponent - 1.05) < 0.0001)
        #expect(restored.confidence == .high)
        #expect(restored.bestRSquared != nil)
        #expect(abs(restored.bestRSquared! - 0.9987) < 0.0001)
    }

    @Test
    func `inconclusive baseline survives round trip`() throws {
        let original = Tests.Complexity.Baseline(
            bestClass: nil, exponent: 0.3, confidence: .inconclusive, bestRSquared: nil
        )

        let bytes = original.jsonBytes(pretty: true)
        let restored = try Tests.Complexity.Baseline(jsonBytes: bytes)

        #expect(restored.bestClass == nil)
        #expect(abs(restored.exponent - 0.3) < 0.0001)
        #expect(restored.confidence == .inconclusive)
        #expect(restored.bestRSquared == nil)
    }

    @Test
    func `all confidence levels survive round trip`() throws {
        for confidence in [
            Tests.Complexity.Confidence.high,
            .medium,
            .low,
            .inconclusive,
        ] {
            let original = Tests.Complexity.Baseline(
                bestClass: .quadratic, exponent: 2.0, confidence: confidence, bestRSquared: 0.99
            )

            let bytes = original.jsonBytes(pretty: true)
            let restored = try Tests.Complexity.Baseline(jsonBytes: bytes)

            #expect(restored.confidence == confidence)
        }
    }

    @Test
    func `all complexity classes survive round trip`() throws {
        for cls in SUT.Benchmark.Complexity.Class.allCases {
            let original = Tests.Complexity.Baseline(
                bestClass: cls, exponent: 1.0, confidence: .high, bestRSquared: 0.99
            )

            let bytes = original.jsonBytes(pretty: true)
            let restored = try Tests.Complexity.Baseline(jsonBytes: bytes)

            #expect(restored.bestClass == cls)
        }
    }
}
