import Testing
import Tests_Test_Support

@Suite
struct TestsTrendTests {

    @Suite struct MannKendall {}
}

// MARK: - Mann-Kendall

extension TestsTrendTests.MannKendall {
    @Test
    func emptySequence() {
        let trend = Test.Benchmark.Trend.mannKendall([])
        #expect(trend.z == 0.0)
        #expect(trend.interpretation == .none)
    }

    @Test
    func twoElements() {
        let trend = Test.Benchmark.Trend.mannKendall([.seconds(1), .seconds(2)])
        #expect(trend.interpretation == .none)
    }

    @Test
    func strictlyIncreasing() {
        let durations = (1...10).map { Duration.seconds($0) }
        let trend = Test.Benchmark.Trend.mannKendall(durations)
        #expect(trend.z > 1.96)
        #expect(trend.interpretation == .increasing)
    }

    @Test
    func strictlyDecreasing() {
        let durations = (1...10).reversed().map { Duration.seconds($0) }
        let trend = Test.Benchmark.Trend.mannKendall(durations)
        #expect(trend.z < -1.96)
        #expect(trend.interpretation == .decreasing)
    }

    @Test
    func flatSequence() {
        let durations = Array(repeating: Duration.seconds(5), count: 10)
        let trend = Test.Benchmark.Trend.mannKendall(durations)
        #expect(trend.z == 0.0)
        #expect(trend.interpretation == .none)
    }

    @Test
    func randomNoTrend() {
        let durations: [Duration] = [
            .seconds(5), .seconds(3), .seconds(7), .seconds(2),
            .seconds(6), .seconds(4), .seconds(8), .seconds(1),
        ]
        let trend = Test.Benchmark.Trend.mannKendall(durations)
        #expect(trend.interpretation == .none)
    }
}
