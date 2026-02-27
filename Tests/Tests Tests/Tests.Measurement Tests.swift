import Testing
import Tests

extension Tests.Measurement {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit

extension Tests.Measurement.Test.Unit {
    @Test
    func `init stores durations`() {
        let durations: [Duration] = [.milliseconds(10), .milliseconds(20), .milliseconds(30)]
        let measurement = Tests.Measurement(durations: durations)
        #expect(measurement.durations.count == 3)
    }

    @Test
    func `min returns smallest duration`() {
        let measurement = Tests.Measurement(durations: [
            .milliseconds(10), .milliseconds(5), .milliseconds(20),
        ])
        #expect(measurement.min == .milliseconds(5))
    }

    @Test
    func `max returns largest duration`() {
        let measurement = Tests.Measurement(durations: [
            .milliseconds(10), .milliseconds(5), .milliseconds(20),
        ])
        #expect(measurement.max == .milliseconds(20))
    }

    @Test
    func `median returns middle value for odd count`() {
        let measurement = Tests.Measurement(durations: [
            .seconds(3), .seconds(1), .seconds(2),
        ])
        #expect(measurement.median == .seconds(2))
    }

    @Test
    func `mean computes average`() {
        let measurement = Tests.Measurement(durations: [
            .seconds(1), .seconds(2), .seconds(3),
        ])
        #expect(measurement.mean == .seconds(2))
    }

    @Test
    func `p50 equals median`() {
        let measurement = Tests.Measurement(durations: [
            .seconds(3), .seconds(1), .seconds(2),
        ])
        #expect(measurement.p50 == measurement.median)
    }

    @Test
    func `percentile with 100 values`() {
        let durations = (0..<100).map { Duration.milliseconds($0) }
        let measurement = Tests.Measurement(durations: durations)

        // percentile(p) = sorted[Int(count * p)] clamped
        // p75: index = Int(100 * 0.75) = 75
        #expect(measurement.p75 == .milliseconds(75))
        // p90: index = Int(100 * 0.90) = 90
        #expect(measurement.p90 == .milliseconds(90))
        // p95: index = Int(100 * 0.95) = 95
        #expect(measurement.p95 == .milliseconds(95))
        // p99: index = Int(100 * 0.99) = 99 (clamped to 99)
        #expect(measurement.p99 == .milliseconds(99))
    }

    @Test
    func `standardDeviation is zero for identical durations`() {
        let measurement = Tests.Measurement(durations: [
            .seconds(5), .seconds(5), .seconds(5),
        ])
        #expect(measurement.standardDeviation == .zero)
    }

    @Test
    func `Comparable orders by median`() {
        let a = Tests.Measurement(durations: [.seconds(1), .seconds(2), .seconds(3)])
        let b = Tests.Measurement(durations: [.seconds(4), .seconds(5), .seconds(6)])
        #expect(a < b)
        #expect(!(b < a))
    }
}

// MARK: - EdgeCase

extension Tests.Measurement.Test.EdgeCase {
    @Test
    func `empty durations returns zero for all metrics`() {
        let measurement = Tests.Measurement(durations: [])
        #expect(measurement.min == .zero)
        #expect(measurement.max == .zero)
        #expect(measurement.median == .zero)
        #expect(measurement.mean == .zero)
        #expect(measurement.p50 == .zero)
        #expect(measurement.p75 == .zero)
        #expect(measurement.p90 == .zero)
        #expect(measurement.p95 == .zero)
        #expect(measurement.p99 == .zero)
        #expect(measurement.p999 == .zero)
        #expect(measurement.standardDeviation == .zero)
    }

    @Test
    func `single duration returns that value for all metrics`() {
        let measurement = Tests.Measurement(durations: [.milliseconds(42)])
        #expect(measurement.min == .milliseconds(42))
        #expect(measurement.max == .milliseconds(42))
        #expect(measurement.median == .milliseconds(42))
        #expect(measurement.mean == .milliseconds(42))
    }

    @Test
    func `standardDeviation returns zero for single element`() {
        let measurement = Tests.Measurement(durations: [.seconds(1)])
        #expect(measurement.standardDeviation == .zero)
    }

    @Test
    func `percentile zero returns minimum`() {
        let measurement = Tests.Measurement(durations: [
            .seconds(3), .seconds(1), .seconds(2),
        ])
        #expect(measurement.percentile(0.0) == .seconds(1))
    }

    @Test
    func `percentile one returns maximum`() {
        let measurement = Tests.Measurement(durations: [
            .seconds(3), .seconds(1), .seconds(2),
        ])
        // percentile(1.0): index = Int(3 * 1.0) = 3, clamped to 2
        #expect(measurement.percentile(1.0) == .seconds(3))
    }
}
