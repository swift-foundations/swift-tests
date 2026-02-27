import Testing
import Tests_Test_Support
import Time_Primitives

@Suite("Test.Benchmark.Measurement")
struct BenchmarkMeasurementTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit

extension BenchmarkMeasurementTests.Unit {
    @Test
    func `min max median mean compute correctly`() {
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [
            .milliseconds(10), .milliseconds(5), .milliseconds(20),
        ])
        #expect(measurement.min == .milliseconds(5))
        #expect(measurement.max == .milliseconds(20))
        // sorted: [5, 10, 20], median index = Int(3 * 0.5) = 1
        #expect(measurement.median == .milliseconds(10))
        // mean = (5 + 10 + 20) / 3 ≈ 11.67ms
        #expect(measurement.mean > .milliseconds(11))
        #expect(measurement.mean < .milliseconds(12))
    }

    @Test
    func `percentiles at known indices`() {
        let durations = (0..<100).map { Duration.milliseconds($0) }
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: durations)

        #expect(measurement.p75 == .milliseconds(75))
        #expect(measurement.p90 == .milliseconds(90))
        #expect(measurement.p95 == .milliseconds(95))
        #expect(measurement.p99 == .milliseconds(99))
    }

    @Test
    func `standardDeviation for known distribution`() {
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [
            .seconds(5), .seconds(5), .seconds(5),
        ])
        #expect(measurement.standardDeviation == .zero)
    }
}

// MARK: - EdgeCase

extension BenchmarkMeasurementTests.EdgeCase {
    @Test
    func `empty durations returns zero`() {
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [])
        #expect(measurement.min == .zero)
        #expect(measurement.max == .zero)
        #expect(measurement.median == .zero)
        #expect(measurement.mean == .zero)
        #expect(measurement.standardDeviation == .zero)
    }

    @Test
    func `single duration for all metrics`() {
        let measurement = Test_Primitives.Test.Benchmark.Measurement(
            durations: [.milliseconds(42)]
        )
        #expect(measurement.min == .milliseconds(42))
        #expect(measurement.max == .milliseconds(42))
        #expect(measurement.median == .milliseconds(42))
        #expect(measurement.mean == .milliseconds(42))
        #expect(measurement.standardDeviation == .zero)
    }
}
