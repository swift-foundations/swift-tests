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
    ///
    /// The operation closure receives the input size and should perform
    /// the workload under test. The framework measures **total** execution
    /// time of the closure (total-work semantics). If you want per-operation
    /// complexity, structure the closure accordingly.
    ///
    /// ```swift
    /// @Test(.serialized)
    /// func sortIsNLogN() async throws {
    ///     let result = try Tests.Complexity.analyze(
    ///         sizes: [1_000, 10_000, 100_000, 1_000_000]
    ///     ) { n in
    ///         var array = (0..<n).map { _ in Int.random(in: 0..<n) }
    ///         array.sort()
    ///     }
    ///     #expect(result.isCompatible(with: .linearithmic))
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - sizes: Input sizes to measure at. Should span ≥ 2 orders of magnitude.
    ///   - warmup: Warmup iterations per size point (not timed).
    ///   - iterations: Timed iterations per size point.
    ///   - metric: Which statistic represents each size point (default: median).
    ///   - policy: Classification thresholds.
    ///   - operation: The workload to measure. Receives the input size.
    /// - Returns: An interpreted ``Result`` with evidence and classification.
    @discardableResult
    public static func analyze<E: Swift.Error>(
        sizes: [Int],
        warmup: Int = 2,
        iterations: Int = 10,
        metric: Sample.Metric = .median,
        policy: Policy = .default,
        operation: (Int) throws(E) -> Void
    ) throws(E) -> Result {
        var points: [(size: Int, metric: Duration)] = []
        points.reserveCapacity(sizes.count)

        for size in sizes.sorted() {
            // Warmup (not timed).
            for _ in 0..<warmup {
                try operation(size)
            }

            // Measure.
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

        let evidence = Test.Benchmark.Complexity.evidence(
            from: points,
            classes: policy.candidateClasses
        )

        return classify(evidence, under: policy)
    }

    /// Async variant for async workloads.
    @discardableResult
    public static func analyze<E: Swift.Error>(
        sizes: [Int],
        warmup: Int = 2,
        iterations: Int = 10,
        metric: Sample.Metric = .median,
        policy: Policy = .default,
        operation: (Int) async throws(E) -> Void
    ) async throws(E) -> Result {
        var points: [(size: Int, metric: Duration)] = []
        points.reserveCapacity(sizes.count)

        for size in sizes.sorted() {
            // Warmup (not timed).
            for _ in 0..<warmup {
                try await operation(size)
            }

            // Measure.
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

        let evidence = Test.Benchmark.Complexity.evidence(
            from: points,
            classes: policy.candidateClasses
        )

        return classify(evidence, under: policy)
    }
}
