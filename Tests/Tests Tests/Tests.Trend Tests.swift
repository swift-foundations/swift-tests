import Testing
import Tests_Test_Support

// NOTE: filename says "Tests.Trend" but the tested type is Test.Benchmark.Trend
// (grep-resolved per [SWIFT-TEST-002] STEP-2 ladder step 2 — "Tests.Trend" does
// not exist as a type in this repo or its dependencies).
extension Test_Primitives.Test.Benchmark.Trend {
    @Suite
    struct Test {
        @Suite struct MannKendall {}
    }
}

// MARK: - Mann-Kendall

extension Test_Primitives.Test.Benchmark.Trend.Test.MannKendall {
    @Test
    func `empty Sequence`() {
        let trend = Test.Benchmark.Trend.mannKendall([])
        #expect(trend.z == 0.0)
        #expect(trend.interpretation == .none)
    }

    @Test
    func `two Elements`() {
        let trend = Test.Benchmark.Trend.mannKendall([.seconds(1), .seconds(2)])
        #expect(trend.interpretation == .none)
    }

    @Test
    func `strictly Increasing`() {
        let durations = (1...10).map { Duration.seconds($0) }
        let trend = Test.Benchmark.Trend.mannKendall(durations)
        #expect(trend.z > 1.96)
        #expect(trend.interpretation == .increasing)
    }

    @Test
    func `strictly Decreasing`() {
        let durations = (1...10).reversed().map { Duration.seconds($0) }
        let trend = Test.Benchmark.Trend.mannKendall(durations)
        #expect(trend.z < -1.96)
        #expect(trend.interpretation == .decreasing)
    }

    @Test
    func `flat Sequence`() {
        let durations = Array(repeating: Duration.seconds(5), count: 10)
        let trend = Test.Benchmark.Trend.mannKendall(durations)
        #expect(trend.z == 0.0)
        #expect(trend.interpretation == .none)
    }

    @Test
    func `random No Trend`() {
        let durations: [Duration] = [
            .seconds(5), .seconds(3), .seconds(7), .seconds(2),
            .seconds(6), .seconds(4), .seconds(8), .seconds(1),
        ]
        let trend = Test.Benchmark.Trend.mannKendall(durations)
        #expect(trend.interpretation == .none)
    }
}
