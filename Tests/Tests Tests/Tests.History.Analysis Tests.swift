import Testing
import Tests_Test_Support

extension Tests.History.Analysis {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Helpers

private func _makeRecord(
    timestamp: Double,
    metricValue: Duration,
    name: Swift.String = "t",
    module: Swift.String = "M"
) -> Tests.History.Record {
    let id = Tests_Core.Test.ID.stub(name, module: module)
    let measurement = Test_Primitives.Test.Benchmark.Measurement(durations: [metricValue])
    let environment = Test_Primitives.Test.Environment.capture()

    return Tests.History.Record(
        timestamp: timestamp,
        testID: id,
        metric: .median,
        metricValue: metricValue,
        measurement: measurement,
        environment: environment,
        coefficientOfVariation: nil,
        outlierCount: nil
    )
}

/// The `none` interpretation for stable trends.
///
/// Avoids ambiguity with `Optional.none`.
private let _noTrend = Test_Primitives.Test.Benchmark.Trend.Interpretation.none

// MARK: - Unit

extension Tests.History.Analysis.Test.Unit {
    @Test
    func `detects increasing trend from degrading records`() {
        // Mann-Kendall needs ~8 monotonic points for Z > 1.96
        let records = (0..<10).map { i in
            _makeRecord(
                timestamp: Double(i),
                metricValue: .milliseconds(10 + i * 5)
            )
        }

        let analysis = Tests.History.Analysis.analyze(records)
        #expect(analysis != nil)
        #expect(analysis?.trend.interpretation == .increasing)
        #expect(analysis?.recordCount == 10)
    }

    @Test
    func `detects decreasing trend from improving records`() {
        let records = (0..<10).map { i in
            _makeRecord(
                timestamp: Double(i),
                metricValue: .milliseconds(100 - i * 5)
            )
        }

        let analysis = Tests.History.Analysis.analyze(records)
        #expect(analysis != nil)
        #expect(analysis?.trend.interpretation == .decreasing)
    }

    @Test
    func `computes overall change correctly`() {
        let records = [
            _makeRecord(timestamp: 1.0, metricValue: .milliseconds(100)),
            _makeRecord(timestamp: 2.0, metricValue: .milliseconds(110)),
            _makeRecord(timestamp: 3.0, metricValue: .milliseconds(120)),
        ]

        let analysis = Tests.History.Analysis.analyze(records)
        #expect(analysis != nil)

        // (120 - 100) / 100 = 0.2
        if let analysis {
            #expect(abs(analysis.overallChange - 0.2) < 0.001)
        }
    }

    @Test
    func `earliest and latest values match temporal order`() {
        let records = [
            _makeRecord(timestamp: 3.0, metricValue: .milliseconds(30)),
            _makeRecord(timestamp: 1.0, metricValue: .milliseconds(10)),
            _makeRecord(timestamp: 2.0, metricValue: .milliseconds(20)),
        ]

        let analysis = Tests.History.Analysis.analyze(records)
        #expect(analysis != nil)

        if let analysis {
            let earliestDiff = abs(analysis.earliestValue.inSeconds - 0.010)
            let latestDiff = abs(analysis.latestValue.inSeconds - 0.030)
            #expect(earliestDiff < 0.001)
            #expect(latestDiff < 0.001)
        }
    }
}

// MARK: - EdgeCase

extension Tests.History.Analysis.Test.EdgeCase {
    @Test
    func `returns nil with fewer than 3 records`() {
        let records = [
            _makeRecord(timestamp: 1.0, metricValue: .milliseconds(10)),
            _makeRecord(timestamp: 2.0, metricValue: .milliseconds(20)),
        ]

        #expect(Tests.History.Analysis.analyze(records) == nil)
    }

    @Test
    func `returns nil with empty records`() {
        #expect(Tests.History.Analysis.analyze([]) == nil)
    }

    @Test
    func `stable values produce no significant trend`() {
        let records = [
            _makeRecord(timestamp: 1.0, metricValue: .milliseconds(10)),
            _makeRecord(timestamp: 2.0, metricValue: .milliseconds(10)),
            _makeRecord(timestamp: 3.0, metricValue: .milliseconds(10)),
        ]

        let analysis = Tests.History.Analysis.analyze(records)
        #expect(analysis != nil)
        #expect(analysis?.trend.interpretation == _noTrend)
        #expect(analysis?.overallChange == 0.0)
    }
}
