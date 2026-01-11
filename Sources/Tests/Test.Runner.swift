//
//  Test.Runner.swift
//  swift-tests
//
//  Test plan executor.
//

public import Test_Primitives

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
            var sink = reporter.makeSink()

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
                            type: String(describing: type(of: error)),
                            description: Test.Text(String(describing: error))
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
        private func runWithTraits(_ entry: Plan.Entry) async throws {
            // Get time limit if any
            var timeLimit: Duration?
            for trait in entry.traits {
                if case .timeLimit(let limit) = trait.kind {
                    timeLimit = limit
                    break
                }
            }

            if let timeLimit {
                try await withTimeout(timeLimit) {
                    try await entry.body.run()
                }
            } else {
                try await entry.body.run()
            }
        }

        /// Runs a closure with a timeout.
        private func withTimeout(
            _ timeout: Duration,
            operation: @escaping @Sendable () async throws -> Void
        ) async throws {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await operation()
                }

                group.addTask {
                    try await Task.sleep(for: timeout)
                    throw TimeLimitExceeded(limit: timeout)
                }

                // Wait for first to complete
                try await group.next()
                group.cancelAll()
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
    /// Error thrown when a test exceeds its time limit.
    public struct TimeLimitExceeded: Error, Sendable {
        /// The time limit that was exceeded.
        public let limit: Duration
    }
}
