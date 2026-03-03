//
//  Test.Trait.ScopeProvider.timed.swift
//  swift-tests
//
//  Scope provider for timed benchmark execution.
//

import Clocks
import Memory

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
        var allocationStats: [Memory.Allocation.Statistics]? = config.trackAllocations ? [] : nil

        for _ in 0..<config.iterations {
            let before = config.trackAllocations
                ? Memory.Allocation.Statistics.capture()
                : nil
            let start = Clock_Primitives.Clock.Continuous.now
            try await operation()
            durations.append(Clock_Primitives.Clock.Continuous.now - start)
            if let before {
                let after = Memory.Allocation.Statistics.capture()
                allocationStats?.append(Memory.Allocation.Statistics.delta(from: before, to: after))
            }
        }

        let measurement = Test.Benchmark.Measurement(durations: durations)

        // Build diagnostic
        let environment = Test.Environment.capture()
        let cv = measurement.batch.coefficientOfVariation
        let mad = measurement.batch.medianAbsoluteDeviation
        let outliers = measurement.batch.outlierCount()
        let trend = Tests.Trend.mannKendall(measurement.durations)

        let metricValue = config.metric.extract(from: measurement)
        let exceeded = config.threshold.map { metricValue > $0 } ?? false
        let factor: Double? = if let threshold = config.threshold, exceeded {
            metricValue.inSeconds / threshold.inSeconds
        } else {
            nil
        }

        let diagnostic = Tests.Diagnostic(
            testName: entry.id.name,
            metric: config.metric,
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: cv,
            medianAbsoluteDeviation: mad,
            outlierCount: outliers,
            trend: trend,
            threshold: config.threshold,
            exceedanceFactor: factor,
            allocations: allocationStats
        )

        // Print results if configured
        if config.printResults {
            print(diagnostic.formatted())
            print(diagnostic.jsonBlock())
        }

        // Throw if threshold exceeded
        if exceeded {
            throw .performanceThresholdExceeded(
                test: entry.id.name,
                metric: config.metric,
                expected: config.threshold!,
                actual: metricValue
            )
        }
    }
}
