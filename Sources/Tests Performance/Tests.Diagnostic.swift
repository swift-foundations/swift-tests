public import Time_Primitives
public import Sample_Primitives
public import Memory

extension Tests {
    /// Structured performance diagnostic aggregating all enrichment data.
    ///
    /// Built by the `.timed` scope provider after measurement. Contains
    /// everything an AI agent or developer needs to diagnose a performance
    /// regression without further computation.
    public struct Diagnostic: Sendable {
        /// Test name for identification.
        public let testName: Swift.String

        /// The metric that was checked (median, p95, etc.).
        public let metric: Tests.Metric

        /// Full measurement with all individual durations and batch statistics.
        public let measurement: Tests.Measurement

        /// Runtime and compile-time environment.
        public let environment: Test.Environment

        /// Coefficient of variation (percentage). nil if < 2 iterations.
        public let coefficientOfVariation: Double?

        /// Median Absolute Deviation. nil if empty.
        public let medianAbsoluteDeviation: Duration?

        /// Number of outliers (> 3 MAD from median). nil if empty.
        public let outlierCount: Int?

        /// Temporal trend analysis result.
        public let trend: Tests.Trend

        /// Configured threshold, or nil if no threshold was set.
        public let threshold: Duration?

        /// How much the actual value exceeds the threshold (actual / threshold).
        /// nil if no threshold was configured or threshold was not exceeded.
        public let exceedanceFactor: Double?

        /// Allocation statistics per iteration. nil if allocation tracking was not enabled.
        public let allocations: [Memory.Allocation.Statistics]?

        public init(
            testName: Swift.String,
            metric: Tests.Metric,
            measurement: Tests.Measurement,
            environment: Test.Environment,
            coefficientOfVariation: Double?,
            medianAbsoluteDeviation: Duration?,
            outlierCount: Int?,
            trend: Tests.Trend,
            threshold: Duration?,
            exceedanceFactor: Double?,
            allocations: [Memory.Allocation.Statistics]?
        ) {
            self.testName = testName
            self.metric = metric
            self.measurement = measurement
            self.environment = environment
            self.coefficientOfVariation = coefficientOfVariation
            self.medianAbsoluteDeviation = medianAbsoluteDeviation
            self.outlierCount = outlierCount
            self.trend = trend
            self.threshold = threshold
            self.exceedanceFactor = exceedanceFactor
            self.allocations = allocations
        }
    }
}
