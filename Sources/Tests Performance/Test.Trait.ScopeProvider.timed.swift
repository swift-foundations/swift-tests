//
//  Test.Trait.ScopeProvider.timed.swift
//  swift-tests
//
//  Scope provider for timed benchmark execution.
//

import Clocks

extension Test.Trait.ScopeProvider {
    /// Scope provider for timed benchmark measurement.
    public static var timed: Self {
        Self(
            id: "timed",
            priority: 50,
            shouldActivate: { $0[Test.Trait.Timed.self] != nil },
            provideScope: _timedScope
        )
    }

    @Sendable
    private static func _timedScope(
        _ entry: Test.Plan.Entry,
        _ traits: Test.Trait.Collection,
        _ operation: @Sendable () async throws(Error) -> Void
    ) async throws(Error) {
        let config = traits[Test.Trait.Timed.self]!

        // Warmup iterations
        for _ in 0..<config.warmup {
            try await operation()
        }

        // Measured iterations
        var durations: [Duration] = []
        durations.reserveCapacity(config.iterations)

        for _ in 0..<config.iterations {
            let start = Clock_Primitives.Clock.Continuous.now
            try await operation()
            durations.append(Clock_Primitives.Clock.Continuous.now - start)
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
                throw .performanceThresholdExceeded(
                    test: entry.id.name,
                    metric: config.metric,
                    expected: threshold,
                    actual: metricValue
                )
            }
        }
    }
}
