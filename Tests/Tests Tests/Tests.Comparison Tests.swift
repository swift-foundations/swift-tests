import Testing
import Tests_Test_Support

extension Tests.Comparison {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit

extension Tests.Comparison.Test.Unit {
    @Test
    func `change is positive for regression`() {
        let baseline = Test.Benchmark.Measurement(durations: [.milliseconds(100)])
        let current = Test.Benchmark.Measurement(durations: [.milliseconds(200)])
        let comparison = Tests.Comparison(name: "test", current: current, baseline: baseline)
        #expect(comparison.change > 0)
    }

    @Test
    func `change is negative for improvement`() {
        let baseline = Test.Benchmark.Measurement(durations: [.milliseconds(200)])
        let current = Test.Benchmark.Measurement(durations: [.milliseconds(100)])
        let comparison = Tests.Comparison(name: "test", current: current, baseline: baseline)
        #expect(comparison.change < 0)
    }

    @Test
    func `isRegression true when current slower`() {
        let baseline = Test.Benchmark.Measurement(durations: [.milliseconds(100)])
        let current = Test.Benchmark.Measurement(durations: [.milliseconds(200)])
        let comparison = Tests.Comparison(name: "test", current: current, baseline: baseline)
        #expect(comparison.isRegression)
        #expect(!comparison.isImprovement)
    }

    @Test
    func `isImprovement true when current faster`() {
        let baseline = Test.Benchmark.Measurement(durations: [.milliseconds(200)])
        let current = Test.Benchmark.Measurement(durations: [.milliseconds(100)])
        let comparison = Tests.Comparison(name: "test", current: current, baseline: baseline)
        #expect(comparison.isImprovement)
        #expect(!comparison.isRegression)
    }

    @Test
    func `change computes correct percentage`() {
        let baseline = Test.Benchmark.Measurement(durations: [.milliseconds(100)])
        let current = Test.Benchmark.Measurement(durations: [.milliseconds(120)])
        let comparison = Tests.Comparison(name: "test", current: current, baseline: baseline)
        // (120 - 100) / 100 = 0.2
        #expect(abs(comparison.change - 0.2) < 0.001)
    }

    @Test
    func `formatted produces non-empty string`() {
        let baseline = Test.Benchmark.Measurement(durations: [.milliseconds(100)])
        let current = Test.Benchmark.Measurement(durations: [.milliseconds(120)])
        let comparison = Tests.Comparison(name: "myTest", current: current, baseline: baseline)
        let formatted = comparison.formatted()
        #expect(!formatted.isEmpty)
        #expect(formatted.contains("myTest"))
    }
}

// MARK: - EdgeCase

extension Tests.Comparison.Test.EdgeCase {
    @Test
    func `identical measurements produce zero change`() {
        let measurement = Test.Benchmark.Measurement(durations: [.milliseconds(100)])
        let comparison = Tests.Comparison(
            name: "test", current: measurement, baseline: measurement
        )
        #expect(comparison.change == 0.0)
        #expect(!comparison.isRegression)
        #expect(!comparison.isImprovement)
    }
}
