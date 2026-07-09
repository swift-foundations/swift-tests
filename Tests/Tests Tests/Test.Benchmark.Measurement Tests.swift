import Testing
import Tests_Test_Support
import Time_Primitives

// NOTE: Test.Benchmark.Measurement already carries a Test suite (see
// "Tests.Measurement Tests.swift"). Per [SWIFT-TEST-002] collision rule
// (no leftover tokens from "BenchmarkMeasurementTests"), these members are
// merged directly into the existing Test.Unit / Test.EdgeCase categories
// rather than declaring a second Test suite for the same type.

extension Test_Primitives.Test.Benchmark.Measurement.Test.Unit {
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

extension Test_Primitives.Test.Benchmark.Measurement.Test.EdgeCase {
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
