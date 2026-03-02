//
//  Test.Runner.swift
//  swift-tests
//
//  Test plan executor.
//

public import Test_Primitives
import Clocks
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

        /// Scope providers that wrap test execution.
        public var scopeProviders: [Test.Trait.ScopeProvider] = [.timed, .timeLimit, .exclusive]

        /// Actions to execute after all tests complete but before the reporter finishes.
        ///
        /// Used by inline snapshot testing to write accumulated snapshots back
        /// to source files after the test run.
        public var postRunActions: [@Sendable () async -> Void] = []

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

            let startTime = Clock_Primitives.Clock.Continuous.now

            // Emit run started
            await sink.send(Test.Event(kind: .runStarted, elapsed: .zero))
            await sink.send(Test.Event(kind: .planCreated, elapsed: elapsed(since: startTime)))

            var passed = 0
            var failed = 0
            var skipped = 0

            // Execute tests
            for entry in plan.entries {
                // Build trait collection once per entry
                let traits = Test.Trait.Collection(modifiers: entry.modifiers)

                // Check if test is enabled
                if !isEnabled(traits) {
                    skipped += 1
                    await sink.send(Test.Event(
                        id: entry.id,
                        kind: .testSkipped(disabledReason(traits)),
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

                // Create a collector for this test's expectations
                let collector = Test.Expectation.Collector()
                var bodyThrew = false

                let testResult: Test.Event.Result
                do {
                    try await Test.Expectation.Collector.$current.withValue(collector) {
                        try await runWithTraits(entry, traits: traits)
                    }
                } catch {
                    bodyThrew = true

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

                // Drain expectations recorded during the test body
                let expectations = collector.drain()
                let hasExpectationFailures = expectations.contains(where: \.isFailing)

                // Emit events for all recorded expectations
                for expectation in expectations {
                    await sink.send(Test.Event(
                        id: entry.id,
                        kind: .expectationChecked(expectation),
                        elapsed: elapsed(since: startTime)
                    ))

                    if expectation.isFailing {
                        let issue = Test.Issue(
                            kind: .expectationFailed(expectation.id),
                            sourceLocation: expectation.expression.sourceLocation
                        )
                        await sink.send(Test.Event(
                            id: entry.id,
                            kind: .issueRecorded(issue),
                            elapsed: elapsed(since: startTime)
                        ))
                    }
                }

                // Determine result: failed if body threw OR any expectations failed
                if bodyThrew || hasExpectationFailures {
                    testResult = .failed
                    failed += 1
                } else {
                    testResult = .passed
                    passed += 1
                }

                await sink.send(Test.Event(
                    id: entry.id,
                    kind: .testEnded(testResult),
                    elapsed: elapsed(since: startTime)
                ))
            }

            // Emit run ended
            await sink.send(Test.Event(kind: .runEnded, elapsed: elapsed(since: startTime)))

            // Execute post-run actions (e.g., inline snapshot write-back)
            for action in postRunActions {
                await action()
            }

            await sink.finish()

            return Result(passed: passed, failed: failed, skipped: skipped)
        }

        /// Computes elapsed duration since start.
        private func elapsed(since start: Clock_Primitives.Clock.Continuous.Instant) -> Duration {
            Clock_Primitives.Clock.Continuous.now - start
        }

        /// Checks if a test is enabled based on its trait collection.
        private func isEnabled(_ traits: Test.Trait.Collection) -> Bool {
            guard let enabled = traits[Test.Trait.Enabled.self] else {
                return true
            }
            return enabled.isEnabled
        }

        /// Gets the disabled reason from a trait collection, if any.
        private func disabledReason(_ traits: Test.Trait.Collection) -> Test.Text? {
            traits[Test.Trait.Enabled.self].flatMap { !$0.isEnabled ? $0.comment : nil }
        }

        /// Runs an entry with trait handling via composable scope providers.
        private func runWithTraits(_ entry: Plan.Entry, traits: Test.Trait.Collection) async throws(Error) {
            let providers = self.scopeProviders
                .filter { $0.shouldActivate(traits) }
                .sorted { $0.priority < $1.priority }

            // Base operation: run the test body with dependency scope
            var chain: @Sendable () async throws(Error) -> Void = { () async throws(Error) in
                do {
                    try await Dependency.Scope.with(
                        { $0.isTestContext = true },
                        operation: entry.body.run
                    )
                } catch {
                    throw Error.bodyFailed(.caught(
                        type: Swift.String(describing: type(of: error)),
                        description: Swift.String(describing: error)
                    ))
                }
            }

            // Wrap with scope providers (reversed so lowest priority wraps outermost)
            for provider in providers.reversed() {
                let inner = chain
                chain = { () async throws(Error) in
                    try await provider.provideScope(entry, traits, inner)
                }
            }

            try await chain()
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

// MARK: - Error

extension Test.Runner {
    /// Errors thrown during test execution.
    public typealias Error = Test.Trait.ScopeProvider.Error
}
