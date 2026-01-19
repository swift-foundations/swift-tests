//
//  Test.Runner.swift
//  swift-tests
//
//  Test plan executor.
//

public import Test_Primitives
public import Dependency_Primitives

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
        private func runWithTraits(_ entry: Plan.Entry) async throws {
            // Extract trait configurations
            var timeLimit: Duration?
            var timedConfig: TimedConfig?
            var exclusionGroup: Swift.String?

            for trait in entry.traits {
                switch trait.kind {
                case .timeLimit(let limit):
                    timeLimit = limit
                case .custom(let name, let value):
                    if name == "__timed__", let value {
                        timedConfig = TimedConfig.decode(from: value)
                    } else if name == "__exclusive__" {
                        exclusionGroup = value ?? "__global__"
                    }
                default:
                    break
                }
            }

            // Build the execution chain
            // Wrap in test context so dependencies resolve to testValue
            let baseOperation: @Sendable () async throws -> Void = {
                try await Dependency.Scope.with({ $0.isTestContext = true }) {
                    try await entry.body.run()
                }
            }

            // Wrap with timed measurement if configured
            let timedOperation: @Sendable () async throws -> Void
            if let config = timedConfig {
                timedOperation = { [testName = entry.id.name] in
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
            let timeLimitedOperation: @Sendable () async throws -> Void
            if let timeLimit {
                timeLimitedOperation = {
                    try await self.withTimeout(timeLimit, operation: timedOperation)
                }
            } else {
                timeLimitedOperation = timedOperation
            }

            // Wrap with exclusion if configured
            if let group = exclusionGroup {
                try await ExclusionController.shared.withExclusiveAccess(group: group) {
                    try await timeLimitedOperation()
                }
            } else {
                try await timeLimitedOperation()
            }
        }

        /// Runs an operation with timed measurement.
        private func runTimed(
            name: Swift.String,
            config: TimedConfig,
            operation: @Sendable () async throws -> Void
        ) async throws {
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

            // Print results if configured
            if config.printResults {
                let sorted = durations.sorted()
                let min = sorted.first ?? .zero
                let max = sorted.last ?? .zero
                let median = sorted.isEmpty ? .zero : sorted[sorted.count / 2]
                let mean = durations.isEmpty ? .zero : durations.reduce(.zero, +) / durations.count
                let p95 = sorted.isEmpty ? .zero : sorted[Int(Double(sorted.count) * 0.95)]
                let p99 = sorted.isEmpty ? .zero : sorted[Int(Double(sorted.count) * 0.99)]

                print("""
                    ⏱️ \(name)
                       Iterations: \(durations.count)
                       Min:        \(min)
                       Median:     \(median)
                       Mean:       \(mean)
                       p95:        \(p95)
                       p99:        \(p99)
                       Max:        \(max)
                    """)
            }

            // Check threshold if configured
            if let threshold = config.threshold {
                let sorted = durations.sorted()
                let metricValue: Duration
                switch config.metric {
                case "min":
                    metricValue = sorted.first ?? .zero
                case "max":
                    metricValue = sorted.last ?? .zero
                case "mean":
                    metricValue = durations.isEmpty ? .zero : durations.reduce(.zero, +) / durations.count
                case "p95":
                    metricValue = sorted.isEmpty ? .zero : sorted[Int(Double(sorted.count) * 0.95)]
                case "p99":
                    metricValue = sorted.isEmpty ? .zero : sorted[min(Int(Double(sorted.count) * 0.99), sorted.count - 1)]
                default: // median
                    metricValue = sorted.isEmpty ? .zero : sorted[sorted.count / 2]
                }

                if metricValue > threshold {
                    throw PerformanceThresholdExceeded(
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

    /// Error thrown when a performance threshold is exceeded.
    public struct PerformanceThresholdExceeded: Error, Sendable {
        /// The test name.
        public let test: Swift.String
        /// The metric that exceeded.
        public let metric: Swift.String
        /// The expected threshold.
        public let expected: Duration
        /// The actual measured value.
        public let actual: Duration
    }
}

// MARK: - Timed Configuration

extension Test.Runner {
    /// Configuration for timed test execution.
    struct TimedConfig: Sendable {
        var iterations: Int = 10
        var warmup: Int = 0
        var printResults: Bool = true
        var threshold: Duration?
        var metric: Swift.String = "median"

        /// Decodes configuration from a trait string.
        static func decode(from string: Swift.String) -> TimedConfig? {
            var config = TimedConfig()

            for part in string.split(separator: ";") {
                let keyValue = part.split(separator: "=", maxSplits: 1)
                guard keyValue.count == 2 else { continue }
                let key = Swift.String(keyValue[0])
                let value = Swift.String(keyValue[1])

                switch key {
                case "i":
                    config.iterations = Int(value) ?? 10
                case "w":
                    config.warmup = Int(value) ?? 0
                case "p":
                    config.printResults = value == "true"
                case "m":
                    config.metric = value
                case "t":
                    let components = value.split(separator: ":")
                    if components.count == 2,
                       let seconds = Int64(components[0]),
                       let attoseconds = Int64(components[1]) {
                        config.threshold = Duration(
                            secondsComponent: seconds,
                            attosecondsComponent: attoseconds
                        )
                    }
                default:
                    break
                }
            }

            return config
        }
    }
}

// MARK: - Exclusion Controller

/// Actor that provides mutual exclusion for test execution.
///
/// Uses a keyed semaphore pattern: tests with the same group key
/// are mutually exclusive.
public actor ExclusionController {
    /// Shared singleton instance.
    public static let shared = ExclusionController()

    /// Tracks which groups are currently running.
    private var runningGroups: Set<String> = []

    /// Continuations waiting for access, keyed by group.
    private var waiters: [String: [CheckedContinuation<Void, Never>]] = [:]

    /// Private init for singleton.
    private init() {}

    /// Executes an operation with exclusive access to the specified group.
    ///
    /// If another operation is currently running with the same group,
    /// this will suspend until that operation completes.
    ///
    /// - Parameters:
    ///   - group: The exclusion group.
    ///   - operation: The operation to execute.
    /// - Returns: The result of the operation.
    /// - Throws: Rethrows any error from the operation.
    public func withExclusiveAccess<T: Sendable>(
        group: Swift.String,
        _ operation: @Sendable () async throws -> T
    ) async rethrows -> T {
        // Wait until we can acquire the lock for this group
        while runningGroups.contains(group) {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                waiters[group, default: []].append(continuation)
            }
        }

        // Acquire lock
        runningGroups.insert(group)

        do {
            let result = try await operation()
            release(group: group)
            return result
        } catch {
            release(group: group)
            throw error
        }
    }

    /// Releases the lock for a group and resumes one waiter.
    private func release(group: Swift.String) {
        runningGroups.remove(group)

        // Resume one waiter for this group
        if var groupWaiters = waiters[group], !groupWaiters.isEmpty {
            let next = groupWaiters.removeFirst()
            if groupWaiters.isEmpty {
                waiters.removeValue(forKey: group)
            } else {
                waiters[group] = groupWaiters
            }
            next.resume()
        }
    }
}
