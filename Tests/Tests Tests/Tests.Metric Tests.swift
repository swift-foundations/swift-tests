import Testing
import Tests_Test_Support

extension Test_Primitives.Test.Benchmark.Metric {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Test_Primitives.Test.Benchmark.Metric.Test.Unit {
    @Test
    func `each case extracts correct field from measurement`() {
        let measurement = Test.Benchmark.Measurement(durations: [
            .milliseconds(10), .milliseconds(20), .milliseconds(30),
            .milliseconds(40), .milliseconds(50), .milliseconds(60),
            .milliseconds(70), .milliseconds(80), .milliseconds(90),
            .milliseconds(100),
        ])

        #expect(Test.Benchmark.Metric.min.extract(from: measurement) == measurement.min)
        #expect(Test.Benchmark.Metric.max.extract(from: measurement) == measurement.max)
        #expect(Test.Benchmark.Metric.median.extract(from: measurement) == measurement.median)
        #expect(Test.Benchmark.Metric.mean.extract(from: measurement) == measurement.mean)
        #expect(Test.Benchmark.Metric.p95.extract(from: measurement) == measurement.p95)
        #expect(Test.Benchmark.Metric.p99.extract(from: measurement) == measurement.p99)
    }
}
