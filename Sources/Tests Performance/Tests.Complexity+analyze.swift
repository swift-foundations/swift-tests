//
//  Tests.Complexity+analyze.swift
//  swift-tests
//
//  Full complexity analysis orchestrator.
//

public import Test_Primitives
import Clocks

extension Tests.Complexity {
    /// Analyzes the empirical complexity of an operation.
    ///
    /// Measures execution time at each input size, constructs analytical
    /// evidence via L1 fitting, and applies policy-based classification.
    /// Returns a ``Diagnostic`` containing the ``Result`` and all
    /// measurement data needed for human or machine interpretation.
    ///
    /// The operation closure receives the input size and should perform
    /// the workload under test. The framework measures **total** execution
    /// time of the closure (total-work semantics). If you want per-operation
    /// complexity, structure the closure accordingly.
    ///
    /// ```swift
    /// @Test(.serialized)
    /// func sortIsNLogN() async throws {
    ///     let diagnostic = try Tests.Complexity.analyze(
    ///         sizes: [1_000, 10_000, 100_000, 1_000_000]
    ///     ) { n in
    ///         var array = (0..<n).map { _ in Int.random(in: 0..<n) }
    ///         array.sort()
    ///     }
    ///     #expect(diagnostic.result.isCompatible(with: .linearithmic))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - sizes: Input sizes to measure at. Should span >= 2 orders of magnitude.
    ///   - warmup: Warmup iterations per size point (not timed).
    ///   - iterations: Timed iterations per size point.
    ///   - metric: Which statistic represents each size point (default: median).
    ///   - policy: Classification thresholds.
    ///   - baselineKey: Optional key for baseline storage. When provided,
    ///     loads the previous baseline, compares, and saves the current result.
    ///   - printDiagnostic: Whether to print the diagnostic to console (default: true).
    ///   - operation: The workload to measure. Receives the input size.
    /// - Returns: A ``Diagnostic`` containing the ``Result`` and measurement data.
    @discardableResult
    public static func analyze<E: Swift.Error>(
        sizes: [Int],
        warmup: Int = 2,
        iterations: Int = 10,
        metric: Sample.Metric = .median,
        policy: Policy = .default,
        baselineKey: Swift.String? = nil,
        printDiagnostic: Bool = true,
        operation: (Int) throws(E) -> Void
    ) throws(E) -> Diagnostic {
        let points = try _measure(
            sizes: sizes,
            warmup: warmup,
            iterations: iterations,
            metric: metric,
            operation: operation
        )

        return _finalize(
            points: points,
            metric: metric,
            policy: policy,
            baselineKey: baselineKey,
            printDiagnostic: printDiagnostic
        )
    }

    /// Async variant for async workloads.
    @discardableResult
    public static func analyze<E: Swift.Error>(
        sizes: [Int],
        warmup: Int = 2,
        iterations: Int = 10,
        metric: Sample.Metric = .median,
        policy: Policy = .default,
        baselineKey: Swift.String? = nil,
        printDiagnostic: Bool = true,
        operation: (Int) async throws(E) -> Void
    ) async throws(E) -> Diagnostic {
        let points = try await _measureAsync(
            sizes: sizes,
            warmup: warmup,
            iterations: iterations,
            metric: metric,
            operation: operation
        )

        return _finalize(
            points: points,
            metric: metric,
            policy: policy,
            baselineKey: baselineKey,
            printDiagnostic: printDiagnostic
        )
    }
}

// MARK: - Finalization

extension Tests.Complexity {
    private static func _finalize(
        points: [(size: Int, metric: Duration)],
        metric: Sample.Metric,
        policy: Policy,
        baselineKey: Swift.String?,
        printDiagnostic: Bool
    ) -> Diagnostic {
        let evidence = Test.Benchmark.Complexity.evidence(
            from: points,
            classes: policy.candidateClasses
        )

        let result = classify(evidence, under: policy)

        var diagnostic = Diagnostic(
            result: result,
            points: points,
            metric: metric,
            policy: policy
        )

        // Baseline comparison.
        _handleBaseline(key: baselineKey, result: result, diagnostic: &diagnostic)

        // Print diagnostic output.
        if printDiagnostic {
            print(diagnostic.formatted())
        }

        return diagnostic
    }
}

// MARK: - Measurement

extension Tests.Complexity {
    private static func _measure<E: Swift.Error>(
        sizes: [Int],
        warmup: Int,
        iterations: Int,
        metric: Sample.Metric,
        operation: (Int) throws(E) -> Void
    ) throws(E) -> [(size: Int, metric: Duration)] {
        var points: [(size: Int, metric: Duration)] = []
        points.reserveCapacity(sizes.count)

        for size in sizes.sorted() {
            for _ in 0..<warmup {
                try operation(size)
            }

            var durations: [Duration] = []
            durations.reserveCapacity(iterations)
            for _ in 0..<iterations {
                let start = Clock_Primitives.Clock.Continuous.now
                try operation(size)
                durations.append(Clock_Primitives.Clock.Continuous.now - start)
            }

            let measurement = Test.Benchmark.Measurement(durations: durations)
            let value = metric.extract(from: measurement)
            points.append((size: size, metric: value))
        }

        return points
    }

    private static func _measureAsync<E: Swift.Error>(
        sizes: [Int],
        warmup: Int,
        iterations: Int,
        metric: Sample.Metric,
        operation: (Int) async throws(E) -> Void
    ) async throws(E) -> [(size: Int, metric: Duration)] {
        var points: [(size: Int, metric: Duration)] = []
        points.reserveCapacity(sizes.count)

        for size in sizes.sorted() {
            for _ in 0..<warmup {
                try await operation(size)
            }

            var durations: [Duration] = []
            durations.reserveCapacity(iterations)
            for _ in 0..<iterations {
                let start = Clock_Primitives.Clock.Continuous.now
                try await operation(size)
                durations.append(Clock_Primitives.Clock.Continuous.now - start)
            }

            let measurement = Test.Benchmark.Measurement(durations: durations)
            let value = metric.extract(from: measurement)
            points.append((size: size, metric: value))
        }

        return points
    }
}

// MARK: - Baseline

extension Tests.Complexity {
    private static func _handleBaseline(
        key: Swift.String?,
        result: Result,
        diagnostic: inout Diagnostic
    ) {
        guard let key else { return }

        let path = Baseline.path(key: key)
        let recording = Tests.Baseline.Recording.current

        // Load previous baseline.
        let previous = Baseline.load(at: path)

        // Compare if previous exists.
        if let previous {
            let current = Baseline(result: result)
            diagnostic.baselineComparison = Baseline.Comparison(
                previous: previous,
                current: current
            )
        }

        // Save current baseline based on recording mode.
        let shouldSave: Bool
        switch recording {
        case .all:
            shouldSave = true
        case .normal:
            shouldSave = previous == nil
        case .never:
            shouldSave = false
        }

        if shouldSave {
            let current = Baseline(result: result)
            try? current.save(to: path)
        }
    }
}
