//
//  Tests.Complexity.Smoke Tests.swift
//  swift-tests
//
//  End-to-end smoke test: real workloads through the full
//  analyze → evidence → classify pipeline.
//

import Testing
import Tests

@Suite(.serialized)
struct ComplexitySmokeTests {

    @Test
    func `array sort is no worse than quadratic`() throws {
        let result = try Tests.Complexity.analyze(
            sizes: [
                500, 1_000, 2_000, 5_000, 10_000,
                20_000, 50_000, 100_000, 200_000, 500_000,
            ],
            warmup: 1,
            iterations: 3
        ) { n in
            var array = (0..<n).map { _ in Int.random(in: 0..<n) }
            array.sort()
        }

        #expect(result.confidence != .inconclusive)
        #expect(result.isNoWorseThan(.quadratic))
        #expect(result.evidence.exponent.value > 0.8)
        #expect(result.evidence.exponent.value < 2.5)
    }

    @Test
    func `linear scan is no worse than quadratic`() throws {
        let result = try Tests.Complexity.analyze(
            sizes: [
                1_000, 3_000, 10_000, 30_000, 100_000,
                300_000, 1_000_000, 3_000_000, 10_000_000, 30_000_000,
            ],
            warmup: 1,
            iterations: 3
        ) { n in
            var sum = 0
            for i in 0..<n {
                sum &+= i
            }
            _ = sum
        }

        #expect(result.confidence != .inconclusive)
        #expect(result.isNoWorseThan(.quadratic))
        #expect(result.evidence.exponent.value > 0.5)
        #expect(result.evidence.exponent.value < 1.5)
    }
}
