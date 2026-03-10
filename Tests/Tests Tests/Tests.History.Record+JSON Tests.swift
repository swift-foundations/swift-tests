import Testing
import Tests_Test_Support

extension Tests.History.Record {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit

extension Tests.History.Record.Test.Unit {
    @Test
    func `serialize roundtrip preserves all fields`() throws {
        let id = Tests_Core.Test.ID.stub("benchTest", module: "MyModule", suite: "MySuite")
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [
            .milliseconds(10), .milliseconds(12), .milliseconds(11),
        ])
        let environment = Test_Primitives.Test.Environment.capture()

        let original = Tests.History.Record(
            timestamp: 1710100000.5,
            testID: id,
            metric: .median,
            metricValue: .milliseconds(11),
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: 3.2,
            outlierCount: 0
        )

        let json = Tests.History.Record.serialize(original)
        let roundtripped = try Tests.History.Record.deserialize(json)

        #expect(roundtripped.timestamp == 1710100000.5)
        #expect(roundtripped.testID.module == "MyModule")
        #expect(roundtripped.testID.suite == "MySuite")
        #expect(roundtripped.testID.name == "benchTest")
        #expect(roundtripped.measurement.durations.count == 3)
        #expect(roundtripped.coefficientOfVariation == 3.2)
        #expect(roundtripped.outlierCount == 0)
    }

    @Test
    func `serialize roundtrip preserves metric value`() throws {
        let id = Tests_Core.Test.ID.stub("t", module: "M")
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [
            .milliseconds(50),
        ])
        let environment = Test_Primitives.Test.Environment.capture()

        let original = Tests.History.Record(
            timestamp: 1710100000.0,
            testID: id,
            metric: .p95,
            metricValue: .milliseconds(50),
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: nil,
            outlierCount: nil
        )

        let json = Tests.History.Record.serialize(original)
        let roundtripped = try Tests.History.Record.deserialize(json)

        let diff = abs(roundtripped.metricValue.inSeconds - 0.050)
        #expect(diff < 0.000001)
    }

    @Test
    func `all metric cases roundtrip`() throws {
        let id = Tests_Core.Test.ID.stub("t", module: "M")
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [.seconds(1)])
        let environment = Test_Primitives.Test.Environment.capture()

        let metrics: [Test_Primitives.Test.Benchmark.Metric] = [
            .min, .max, .median, .mean, .p50, .p75, .p90, .p95, .p99, .p999,
        ]

        for metric in metrics {
            let record = Tests.History.Record(
                timestamp: 1.0,
                testID: id,
                metric: metric,
                metricValue: .seconds(1),
                measurement: measurement,
                environment: environment,
                coefficientOfVariation: nil,
                outlierCount: nil
            )

            let json = Tests.History.Record.serialize(record)
            let roundtripped = try Tests.History.Record.deserialize(json)

            #expect(
                "\(roundtripped.metric)" == "\(metric)",
                "Metric \(metric) did not roundtrip"
            )
        }
    }
}

// MARK: - EdgeCase

extension Tests.History.Record.Test.EdgeCase {
    @Test
    func `roundtrip with nil suite`() throws {
        let id = Tests_Core.Test.ID.stub("t", module: "M")
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [.seconds(1)])
        let environment = Test_Primitives.Test.Environment.capture()

        let record = Tests.History.Record(
            timestamp: 1.0,
            testID: id,
            metric: .median,
            metricValue: .seconds(1),
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: nil,
            outlierCount: nil
        )

        let json = Tests.History.Record.serialize(record)
        let roundtripped = try Tests.History.Record.deserialize(json)

        #expect(roundtripped.testID.suite == nil)
    }

    @Test
    func `roundtrip with nil optional fields`() throws {
        let id = Tests_Core.Test.ID.stub("t", module: "M")
        let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [.seconds(1)])
        let environment = Test_Primitives.Test.Environment.capture()

        let record = Tests.History.Record(
            timestamp: 1.0,
            testID: id,
            metric: .median,
            metricValue: .seconds(1),
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: nil,
            outlierCount: nil
        )

        let json = Tests.History.Record.serialize(record)
        let roundtripped = try Tests.History.Record.deserialize(json)

        #expect(roundtripped.coefficientOfVariation == nil)
        #expect(roundtripped.outlierCount == nil)
    }
}
