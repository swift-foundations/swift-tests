//
//  Tests.History.Analysis.swift
//  swift-tests
//
//  Cross-run trend analysis from historical records.
//

public import Time_Primitives

extension Tests.History {
    /// Cross-run trend analysis computed from historical records.
    ///
    /// Uses Mann-Kendall on the temporal sequence of metric values
    /// to detect performance regressions that develop gradually
    /// over multiple runs — the kind that within-run analysis misses.
    public struct Analysis: Sendable {
        /// Temporal trend across all historical runs.
        ///
        /// An `.increasing` trend on timing data means degradation.
        public let trend: Test.Benchmark.Trend

        /// Number of historical records analyzed.
        public let recordCount: Int

        /// The metric value from the most recent record.
        public let latestValue: Duration

        /// The metric value from the earliest record.
        public let earliestValue: Duration

        /// Overall change from earliest to latest as a fraction.
        ///
        /// Positive means degradation (duration increased).
        /// Example: `0.15` means 15% slower than the earliest record.
        public let overallChange: Double

        public init(
            trend: Test.Benchmark.Trend,
            recordCount: Int,
            latestValue: Duration,
            earliestValue: Duration,
            overallChange: Double
        ) {
            self.trend = trend
            self.recordCount = recordCount
            self.latestValue = latestValue
            self.earliestValue = earliestValue
            self.overallChange = overallChange
        }
    }
}

// MARK: - Factory

extension Tests.History.Analysis {
    /// Analyzes a sequence of historical records for temporal trend.
    ///
    /// Requires at least 3 records for meaningful trend detection.
    /// Records are sorted by timestamp before analysis.
    ///
    /// - Parameter records: Historical run records.
    /// - Returns: Analysis result, or `nil` if fewer than 3 records.
    public static func analyze(_ records: [Tests.History.Record]) -> Self? {
        guard records.count >= 3 else { return nil }

        let sorted = records.sorted { $0.timestamp < $1.timestamp }
        let values = sorted.map { $0.metricValue }
        let trend = Test.Benchmark.Trend.mannKendall(values)

        let earliest = sorted.first!.metricValue
        let latest = sorted.last!.metricValue

        let overallChange: Double
        if earliest > .zero {
            overallChange = (latest.inSeconds - earliest.inSeconds) / earliest.inSeconds
        } else {
            overallChange = 0.0
        }

        return Self(
            trend: trend,
            recordCount: records.count,
            latestValue: latest,
            earliestValue: earliest,
            overallChange: overallChange
        )
    }
}
