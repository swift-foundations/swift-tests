//
//  Tests.History.Record.swift
//  swift-tests
//
//  Single run record for JSONL history.
//

public import Time_Primitives
public import Sample_Primitives

extension Tests.History {
    /// A single benchmark run record.
    ///
    /// Each `.timed()` execution produces one record. Records are
    /// append-only to a JSONL file, building a temporal sequence
    /// for cross-run trend analysis.
    public struct Record: Sendable {
        /// Wall-clock instant when this measurement was taken.
        public let timestamp: Instant

        /// The test identifier.
        public let testID: Test.ID

        /// The metric that was evaluated.
        public let metric: Test.Benchmark.Metric

        /// The extracted metric value (convenience for trend analysis).
        public let metricValue: Duration

        /// Full measurement with all individual durations.
        public let measurement: Test.Benchmark.Measurement

        /// Runtime and compile-time environment.
        public let environment: Test.Environment

        /// Coefficient of variation for this measurement.
        public let coefficientOfVariation: Double?

        /// Number of outliers (> 3 MAD from median).
        public let outlierCount: Int?

        public init(
            timestamp: Instant,
            testID: Test.ID,
            metric: Test.Benchmark.Metric,
            metricValue: Duration,
            measurement: Test.Benchmark.Measurement,
            environment: Test.Environment,
            coefficientOfVariation: Double?,
            outlierCount: Int?
        ) {
            self.timestamp = timestamp
            self.testID = testID
            self.metric = metric
            self.metricValue = metricValue
            self.measurement = measurement
            self.environment = environment
            self.coefficientOfVariation = coefficientOfVariation
            self.outlierCount = outlierCount
        }
    }
}
