import Testing
import Tests

extension Tests.Metric {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Tests.Metric.Test.Unit {
    @Test
    func `each case extracts correct field from measurement`() {
        let measurement = Tests.Measurement(durations: [
            .milliseconds(10), .milliseconds(20), .milliseconds(30),
            .milliseconds(40), .milliseconds(50), .milliseconds(60),
            .milliseconds(70), .milliseconds(80), .milliseconds(90),
            .milliseconds(100),
        ])

        #expect(Tests.Metric.min.extract(from: measurement) == measurement.min)
        #expect(Tests.Metric.max.extract(from: measurement) == measurement.max)
        #expect(Tests.Metric.median.extract(from: measurement) == measurement.median)
        #expect(Tests.Metric.mean.extract(from: measurement) == measurement.mean)
        #expect(Tests.Metric.p95.extract(from: measurement) == measurement.p95)
        #expect(Tests.Metric.p99.extract(from: measurement) == measurement.p99)
    }
}
