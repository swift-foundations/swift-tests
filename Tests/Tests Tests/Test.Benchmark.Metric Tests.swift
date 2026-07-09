import Testing
import Tests_Test_Support

// NOTE: Test.Benchmark.Metric already carries a Test suite (see
// "Tests.Metric Tests.swift"). Per [SWIFT-TEST-002] collision rule (no
// leftover tokens from "BenchmarkMetricTests"), these members are merged
// directly into the existing Test.Unit category rather than declaring a
// second Test suite for the same type.

extension Test_Primitives.Test.Benchmark.Metric.Test.Unit {
    @Test
    func `each case extracts correct field`() {
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [
            .milliseconds(10), .milliseconds(20), .milliseconds(30),
            .milliseconds(40), .milliseconds(50), .milliseconds(60),
            .milliseconds(70), .milliseconds(80), .milliseconds(90),
            .milliseconds(100),
        ])

        #expect(
            Test_Primitives.Test.Benchmark.Metric.min.extract(from: measurement)
                == measurement.min
        )
        #expect(
            Test_Primitives.Test.Benchmark.Metric.max.extract(from: measurement)
                == measurement.max
        )
        #expect(
            Test_Primitives.Test.Benchmark.Metric.median.extract(from: measurement)
                == measurement.median
        )
        #expect(
            Test_Primitives.Test.Benchmark.Metric.mean.extract(from: measurement)
                == measurement.mean
        )
        #expect(
            Test_Primitives.Test.Benchmark.Metric.p95.extract(from: measurement)
                == measurement.p95
        )
        #expect(
            Test_Primitives.Test.Benchmark.Metric.p99.extract(from: measurement)
                == measurement.p99
        )
    }

    @Test
    func `rawValue matches case name`() {
        #expect(Test_Primitives.Test.Benchmark.Metric.min.rawValue == "min")
        #expect(Test_Primitives.Test.Benchmark.Metric.max.rawValue == "max")
        #expect(Test_Primitives.Test.Benchmark.Metric.median.rawValue == "median")
        #expect(Test_Primitives.Test.Benchmark.Metric.mean.rawValue == "mean")
        #expect(Test_Primitives.Test.Benchmark.Metric.p95.rawValue == "p95")
        #expect(Test_Primitives.Test.Benchmark.Metric.p99.rawValue == "p99")
    }

    @Test
    func `init from rawValue round trips`() {
        #expect(Test_Primitives.Test.Benchmark.Metric(rawValue: "min") == .min)
        #expect(Test_Primitives.Test.Benchmark.Metric(rawValue: "max") == .max)
        #expect(Test_Primitives.Test.Benchmark.Metric(rawValue: "median") == .median)
        #expect(Test_Primitives.Test.Benchmark.Metric(rawValue: "mean") == .mean)
        #expect(Test_Primitives.Test.Benchmark.Metric(rawValue: "p95") == .p95)
        #expect(Test_Primitives.Test.Benchmark.Metric(rawValue: "p99") == .p99)
        #expect(Test_Primitives.Test.Benchmark.Metric(rawValue: "invalid") == nil)
    }
}
