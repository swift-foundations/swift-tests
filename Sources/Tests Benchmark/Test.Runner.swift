//
//  Test.Runner.swift
//  swift-tests
//
//  Test plan executor.
//

public import Test_Primitives
import Dependency_Primitives
import Standard_Library_Extensions

extension Test {
    /// Executes test plans and reports results.
    ///
    /// `Runner` is the core execution engine that:
    /// - Executes tests from a ``Test/Plan``
    /// - Applies traits (time limits, serialization, etc.)
    /// - Sends events to a ``Test/Reporter``
    /// - Tracks timing via Duration offsets
    ///
    /// ## Example
    ///
    /// ```swift
    /// let runner = Test.Runner(reporter: .console)
    /// let result = await runner.run(plan)
    ///
    /// if result.hasFailures {
    ///     print("Tests failed!")
    /// }
    /// ```
    ///
    /// ## Concurrency
    ///
    /// By default, tests run concurrently. Tests with the `.serialized`
    /// trait run one at a time. Use ``run(_:concurrency:)`` to control
    /// the maximum parallelism.
    public struct Runner: Sendable {
        /// The reporter to send events to.
        public let reporter: Reporter

        /// Creates a runner with the given reporter.
        ///
        /// - Parameter reporter: The reporter for test events.
        public init(reporter: Reporter) {
            self.reporter = reporter
        }

        /// Runs a test plan with default concurrency.
        ///
        /// - Parameter plan: The plan to execute.
        /// - Returns: The run result.
        public func run(_ plan: Plan) async -> Result {
            await run(plan, concurrency: .automatic)
        }

        /// Runs a test plan with specified concurrency.
        ///
        /// - Parameters:
        ///   - plan: The plan to execute.
        ///   - concurrency: The concurrency mode.
        /// - Returns: The run result.
        public func run(_ plan: Plan, concurrency: Concurrency) async -> Result {
            let sink = reporter.makeSink()

            let startTime = ContinuousClock.now

            // Emit run started
            await sink.send(Test.Event(kind: .runStarted, elapsed: .zero))
            await sink.send(Test.Event(kind: .planCreated, elapsed: elapsed(since: startTime)))

            var passed = 0
            var failed = 0
            var skipped = 0

            // Execute tests
            for entry in plan.entries {
                // Check if test is enabled
                if !isEnabled(entry) {
                    skipped += 1
                    await sink.send(Test.Event(
                        id: entry.id,
                        kind: .testSkipped(disabledReason(entry)),
                        elapsed: elapsed(since: startTime)
                    ))
                    continue
                }

                // Run the test
                await sink.send(Test.Event(
                    id: entry.id,
                    kind: .testStarted,
                    elapsed: elapsed(since: startTime)
                ))

                let testResult: Test.Event.Result
                do {
                    try await runWithTraits(entry)
                    testResult = .passed
                    passed += 1
                } catch {
                    testResult = .failed
                    failed += 1

                    // Record the error as an issue
                    let issue = Test.Issue(
                        kind: .errorCaught(
                            type: Swift.String(describing: type(of: error)),
                            description: Test.Text(Swift.String(describing: error))
                        ),
                        sourceLocation: entry.id.sourceLocation
                    )
                    await sink.send(Test.Event(
                        id: entry.id,
                        kind: .issueRecorded(issue),
                        elapsed: elapsed(since: startTime)
                    ))
                }

                await sink.send(Test.Event(
                    id: entry.id,
                    kind: .testEnded(testResult),
                    elapsed: elapsed(since: startTime)
                ))
            }

            // Emit run ended
            await sink.send(Test.Event(kind: .runEnded, elapsed: elapsed(since: startTime)))

            await sink.finish()

            return Result(passed: passed, failed: failed, skipped: skipped)
        }

        /// Computes elapsed duration since start.
        private func elapsed(since start: ContinuousClock.Instant) -> Duration {
            ContinuousClock.now - start
        }

        /// Checks if a test entry is enabled.
        private func isEnabled(_ entry: Plan.Entry) -> Bool {
            for trait in entry.traits {
                if case .enabled(let isEnabled, _) = trait.kind, !isEnabled {
                    return false
                }
            }
            return true
        }

        /// Gets the disabled reason for an entry, if any.
        private func disabledReason(_ entry: Plan.Entry) -> Test.Text? {
            for trait in entry.traits {
                if case .enabled(false, let reason) = trait.kind {
                    return reason
                }
            }
            return nil
        }

        /// Runs an entry with trait handling.
        private func runWithTraits(_ entry: Plan.Entry) async throws(Error) {
            // Extract trait configurations
            var timeLimit: Duration?
            var timedConfig: Test.Benchmark.Configuration?
            var exclusionGroup: Swift.String?

            for trait in entry.traits {
                switch trait.kind {
                case .timeLimit(let limit):
                    timeLimit = limit
                case .custom(let name, let value):
                    if name == "__timed__", let value {
                        timedConfig = Test.Benchmark.Configuration.decode(from: value)
                    } else if name == "__exclusive__" {
                        exclusionGroup = value ?? "__global__"
                    }
                default:
                    break
                }
            }

            // Build the execution chain
            // Wrap in test context so dependencies resolve to testValue
            let baseOperation: @Sendable () async throws(Error) -> Void = { () async throws(Error) in
                do throws(Test.Body.Error) {
                    try await Dependency.Scope.with({ $0.isTestContext = true }, operation: entry.body.run)
                } catch {
                    throw Error.bodyFailed(error)
                }
            }

            // Wrap with timed measurement if configured
            let timedOperation: @Sendable () async throws(Error) -> Void
            if let config = timedConfig {
                timedOperation = { [testName = entry.id.name] () async throws(Error) in
                    try await self.runTimed(
                        name: testName,
                        config: config,
                        operation: baseOperation
                    )
                }
            } else {
                timedOperation = baseOperation
            }

            // Wrap with time limit if configured
            let timeLimitedOperation: @Sendable () async throws(Error) -> Void
            if let timeLimit {
                timeLimitedOperation = { () async throws(Error) in
                    try await self.withTimeout(timeLimit, operation: timedOperation)
                }
            } else {
                timeLimitedOperation = timedOperation
            }

            // Wrap with exclusion if configured
            if let group = exclusionGroup {
                try await Test.Exclusion.Controller.shared.withExclusiveAccess(group: group, { () async throws(Error) in
                    try await timeLimitedOperation()
                })
            } else {
                try await timeLimitedOperation()
            }
        }

        /// Runs an operation with timed measurement.
        private func runTimed(
            name: Swift.String,
            config: Test.Benchmark.Configuration,
            operation: @Sendable () async throws(Error) -> Void
        ) async throws(Error) {
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
                Test.Benchmark.printPerformance(name, measurement)
            }

            // Check threshold if configured
            if let threshold = config.threshold {
                let metricValue = config.metric.extract(from: measurement)
                if metricValue > threshold {
                    throw Error.performanceThresholdExceeded(
                        test: name,
                        metric: config.metric,
                        expected: threshold,
                        actual: metricValue
                    )
                }
            }
        }

        /// Runs a closure with a timeout.
        private func withTimeout(
            _ timeout: Duration,
            operation: @escaping @Sendable () async throws(Error) -> Void
        ) async throws(Error) {
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        try await operation()
                    }

                    group.addTask {
                        try await Task.sleep(for: timeout)
                        throw Error.timeLimitExceeded(limit: timeout)
                    }

                    // Wait for first to complete
                    try await group.next()
                    group.cancelAll()
                }
            } catch let error as Error {
                throw error
            } catch {
                throw Error.timeLimitExceeded(limit: timeout)
            }
        }
    }
}

// MARK: - Concurrency

extension Test.Runner {
    /// Concurrency mode for test execution.
    public enum Concurrency: Sendable {
        /// System determines concurrency level.
        case automatic

        /// Run tests serially.
        case serial

        /// Run up to N tests in parallel.
        case limited(Int)
    }
}

// MARK: - Result

extension Test.Runner {
    /// The result of a test run.
    public struct Result: Sendable {
        /// Number of tests that passed.
        public let passed: Int

        /// Number of tests that failed.
        public let failed: Int

        /// Number of tests that were skipped.
        public let skipped: Int

        /// Total number of tests.
        public var total: Int {
            passed + failed + skipped
        }

        /// Whether any tests failed.
        public var hasFailures: Bool {
            failed > 0
        }

        /// Whether all tests passed.
        public var allPassed: Bool {
            failed == 0
        }
    }
}

// MARK: - Errors

extension Test.Runner {
    /// Errors thrown during test execution.
    public enum Error: Swift.Error, Sendable {
        /// Test exceeded its configured time limit.
        case timeLimitExceeded(limit: Duration)

        /// Performance metric exceeded the configured threshold.
        case performanceThresholdExceeded(
            test: Swift.String,
            metric: Test.Benchmark.Metric,
            expected: Duration,
            actual: Duration
        )

        /// The test body threw an error.
        case bodyFailed(Test.Body.Error)
    }
}


