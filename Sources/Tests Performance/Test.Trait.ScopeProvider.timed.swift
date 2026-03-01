//
//  Test.Trait.ScopeProvider.timed.swift
//  swift-tests
//
//  Scope provider for timed benchmark execution.
//

extension Test.Trait.ScopeProvider {
    /// Scope provider for timed benchmark measurement.
    public static var timed: Self {
        Self(
            id: "timed",
            priority: 50,
            shouldActivate: { $0[Test.Trait.Timed.self] != nil },
            provideScope: { entry, traits, operation in
                let config = traits[Test.Trait.Timed.self]!

                // Warmup iterations
                for _ in 0..<config.warmup {
                    try await operation()
                }

                // Measured iterations
                var durations: [Duration] = []
                durations.reserveCapacity(config.iterations)

                for _ in 0..<config.iterations {
                    let start = ContinuousClock.now
                    try await operation()
                    durations.append(ContinuousClock.now - start)
                }

                let measurement = Test.Benchmark.Measurement(durations: durations)

                // Print results if configured
                if config.printResults {
                    Test.Benchmark.printPerformance(entry.id.name, measurement)
                }

                // Check threshold if configured
                if let threshold = config.threshold {
                    let metricValue = config.metric.extract(from: measurement)
                    if metricValue > threshold {
                        throw PerformanceThresholdExceeded(
                            test: entry.id.name,
                            metric: config.metric,
                            expected: threshold,
                            actual: metricValue
                        )
                    }
                }
            }
        )
    }
}

// MARK: - Errors

extension Test.Trait.ScopeProvider {
    /// Error thrown when a performance threshold is exceeded.
    public struct PerformanceThresholdExceeded: Swift.Error, Sendable {
        /// The test that exceeded the threshold.
        public let test: Swift.String

        /// The metric that was checked.
        public let metric: Test.Benchmark.Metric

        /// The expected threshold.
        public let expected: Duration

        /// The actual measured value.
        public let actual: Duration
    }
}
