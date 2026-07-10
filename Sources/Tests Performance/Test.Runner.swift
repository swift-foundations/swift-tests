//
//  Test.Runner.swift
//  swift-tests
//
//  Test plan executor.
//

import Clocks
import Dependency_Primitives
import JSON
import Standard_Library_Extensions
public import Tests_Core
import Tree_Keyed_Primitives

extension Test {
    /// Executes test plans and reports results.
    ///
    /// `Runner` is the core execution engine that:
    /// - Walks the hierarchical test tree from a ``Test/Plan``
    /// - Applies traits (time limits, serialization, etc.)
    /// - Controls concurrency per-suite via ``Concurrency``
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
    /// By default, sibling tests and suites run concurrently. Suites with
    /// the `.serialized` trait force their children to run sequentially.
    /// Use ``run(_:concurrency:)`` to control maximum parallelism:
    /// - `.automatic` — siblings run in parallel (default)
    /// - `.serial` — all tests run sequentially
    /// - `.limited(N)` — at most N concurrent siblings
    public struct Runner: Sendable {
        /// The reporter to send events to.
        public let reporter: Reporter

        /// Scope providers that wrap test execution.
        public var scopeProviders: [Test.Trait.Scope.Provider] = [.timed, .timeLimit, .exclusive]

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
    }
}

extension Test.Runner {
    /// Runs a test plan with default concurrency.
    ///
    /// - Parameter plan: The plan to execute.
    /// - Returns: The run result.
    public func run(_ plan: Test.Plan) async -> Result {
        await run(plan, concurrency: .automatic)
    }

    /// Runs a test plan with specified concurrency.
    ///
    /// Walks the plan's hierarchical tree, executing tests and suites
    /// with the given concurrency mode. The `.serialized` trait on a
    /// suite overrides to `.serial` for that subtree's children.
    ///
    /// - Parameters:
    ///   - plan: The plan to execute.
    ///   - concurrency: The concurrency mode.
    /// - Returns: The run result.
    public func run(_ plan: Test.Plan, concurrency: Concurrency) async -> Result {
        let sink = reporter.sink()
        let sender = sink.sender

        let startTime = Clock_Primitives.Clock.Continuous.now

        // Emit run started
        await sender.send(Test.Event(kind: .runStarted, elapsed: .zero))
        await sender.send(Test.Event(kind: .planCreated, elapsed: elapsed(since: startTime)))

        // Emit structured plan record
        await sender.send(
            Test.Event(
                kind: .planRecord,
                elapsed: elapsed(since: startTime),
                payload: Self.planJSON(plan).serialize()
            )
        )

        // Walk the tree
        let counters: Counters
        if let root = plan.tree.root {
            counters = await walk(
                plan.tree,
                at: root,
                concurrency: concurrency,
                sender: sender,
                startTime: startTime
            )
        } else {
            counters = Counters()
        }

        // Emit run ended
        await sender.send(Test.Event(kind: .runEnded, elapsed: elapsed(since: startTime)))

        // Emit performance diagnostics as events
        let diagnostics = Tests.Diagnostic.Collector.shared.drain()
        for diagnostic in diagnostics {
            // Console output (runner coordinates all printing)
            print(diagnostic.formatted())

            // Emit structured event with JSON payload
            await sender.send(
                Test.Event(
                    kind: .performanceDiagnostic,
                    elapsed: elapsed(since: startTime),
                    payload: diagnostic.jsonBlock()
                )
            )
        }

        // Emit summary if any timed tests ran
        if !diagnostics.isEmpty {
            Tests.Diagnostic.summary(diagnostics)

            await sender.send(
                Test.Event(
                    kind: .performanceSummary,
                    elapsed: elapsed(since: startTime)
                )
            )
        }

        // Emit structured summary record
        await sender.send(
            Test.Event(
                kind: .summaryRecord,
                elapsed: elapsed(since: startTime),
                payload: Self.summaryJSON(counters, elapsed: elapsed(since: startTime)).serialize()
            )
        )

        // Execute post-run actions (e.g., inline snapshot write-back)
        for action in postRunActions {
            await action()
        }

        await sink.finish()

        return Result(passed: counters.passed, failed: counters.failed, skipped: counters.skipped)
    }

    // MARK: - Tree Walking

    /// Walks a single node in the test tree.
    ///
    /// Named `walk(_:at:...)` per [API-NAME-002] — single-word verb
    /// with `at:` label for the position parameter.
    ///
    /// Dispatches based on node type:
    /// - `nil` value (structural intermediate) → dispatch children
    /// - Suite node (body == nil) → emit suite events, dispatch children
    /// - Test node (body != nil) → execute with scope providers
    private func walk(
        _ tree: Tree<Test.Plan.Node?>.Keyed<Swift.String>,
        at position: Tree<Test.Plan.Node?>.Keyed<Swift.String>.Position,
        concurrency: Concurrency,
        sender: Test.Reporter.Sink.Sender,
        startTime: Clock_Primitives.Clock.Continuous.Instant
    ) async -> Counters {
        switch tree.peek(at: position) as Test.Plan.Node?? {
        case nil:
            return Counters()

        case .some(nil):
            // Structural nil node — module boundary or implicit nesting.
            return await dispatch(
                tree,
                childrenOf: position,
                concurrency: concurrency,
                traits: nil,
                sender: sender,
                startTime: startTime
            )

        case .some(.some(let node)):
            let traits = node.traits

            if !isEnabled(traits) {
                await sender.send(
                    Test.Event(
                        id: node.id,
                        kind: .testSkipped,
                        elapsed: elapsed(since: startTime),
                        reason: reason(disabled: traits)
                    )
                )
                return Counters(passed: 0, failed: 0, skipped: 1)
            }

            if node.body != nil {
                // Test node — execute with scope providers
                return await execute(
                    node,
                    traits: traits,
                    sender: sender,
                    startTime: startTime
                )
            } else {
                // Suite node — bracket children with suite events
                await sender.send(
                    Test.Event(
                        id: node.id,
                        kind: .testStarted,
                        elapsed: elapsed(since: startTime)
                    )
                )

                let counters = await dispatch(
                    tree,
                    childrenOf: position,
                    concurrency: concurrency,
                    traits: traits,
                    sender: sender,
                    startTime: startTime
                )

                await sender.send(
                    Test.Event(
                        id: node.id,
                        kind: .testEnded,
                        elapsed: elapsed(since: startTime),
                        result: counters.failed > 0 ? .failed : .passed
                    )
                )

                return counters
            }
        }
    }

    /// Dispatches children of a node according to the concurrency mode.
    ///
    /// Named `dispatch(_:childrenOf:...)` per [API-NAME-002] — single-word
    /// verb. The `childrenOf:` label communicates the scope.
    ///
    /// If the node has the `.serialized` trait, forces serial execution
    /// regardless of the top-level concurrency setting.
    private func dispatch(
        _ tree: Tree<Test.Plan.Node?>.Keyed<Swift.String>,
        childrenOf position: Tree<Test.Plan.Node?>.Keyed<Swift.String>.Position,
        concurrency: Concurrency,
        traits: Test.Trait.Collection?,
        sender: Test.Reporter.Sink.Sender,
        startTime: Clock_Primitives.Clock.Continuous.Instant
    ) async -> Counters {
        guard let children = tree.children(of: position), !children.isEmpty else {
            return Counters()
        }

        // .serialized trait on this node forces serial for children
        let effective: Concurrency
        if let traits, traits[Test.Trait.Serialized.self] {
            effective = .serial
        } else {
            effective = concurrency
        }

        switch effective {
        case .serial:
            let sorted = children.sorted { a, b in
                let aLoc = sourceLocation(of: a.position, in: tree)
                let bLoc = sourceLocation(of: b.position, in: tree)
                if let aLoc, let bLoc { return aLoc < bLoc }
                return a.key < b.key
            }
            var counters = Counters()
            for (_, childPos) in sorted {
                counters += await walk(
                    tree,
                    at: childPos,
                    concurrency: effective,
                    sender: sender,
                    startTime: startTime
                )
            }
            return counters

        case .automatic:
            return await withTaskGroup(of: Counters.self, returning: Counters.self) { group in
                for (_, childPos) in children {
                    group.addTask {
                        await walk(
                            tree,
                            at: childPos,
                            concurrency: effective,
                            sender: sender,
                            startTime: startTime
                        )
                    }
                }
                var counters = Counters()
                for await childCounters in group {
                    counters += childCounters
                }
                return counters
            }

        case .limited(let maxConcurrent):
            return await withTaskGroup(of: Counters.self, returning: Counters.self) { group in
                var counters = Counters()
                var inFlight = 0
                var childIter = children.makeIterator()

                // Seed initial batch
                while inFlight < maxConcurrent, let (_, childPos) = childIter.next() {
                    group.addTask {
                        await walk(
                            tree,
                            at: childPos,
                            concurrency: effective,
                            sender: sender,
                            startTime: startTime
                        )
                    }
                    inFlight += 1
                }

                // As tasks complete, spawn more
                for await childCounters in group {
                    counters += childCounters
                    inFlight -= 1
                    if let (_, childPos) = childIter.next() {
                        group.addTask {
                            await walk(
                                tree,
                                at: childPos,
                                concurrency: effective,
                                sender: sender,
                                startTime: startTime
                            )
                        }
                        inFlight += 1
                    }
                }

                return counters
            }
        }
    }

    // MARK: - Test Execution

    /// Executes a single test node with scope providers.
    ///
    /// Named `execute(_:traits:...)` per [API-NAME-002] — single-word verb.
    private func execute(
        _ node: Test.Plan.Node,
        traits: Test.Trait.Collection,
        sender: Test.Reporter.Sink.Sender,
        startTime: Clock_Primitives.Clock.Continuous.Instant
    ) async -> Counters {
        await sender.send(
            Test.Event(
                id: node.id,
                kind: .testStarted,
                elapsed: elapsed(since: startTime)
            )
        )

        let entry = Test.Plan.Entry(
            id: node.id,
            modifiers: node.modifiers,
            body: node.body!
        )

        let collector = Test.Expectation.Collector()
        var bodyThrew = false

        let testResult: Test.Event.Result
        do {
            try await Test.Expectation.Collector.with(collector) {
                try await run(entry, traits: traits)
            }
        } catch {
            bodyThrew = true

            let isRequirementFailure: Bool
            if let runnerError = error as? Self.Error,
                case .bodyFailed(.requirementFailed) = runnerError
            {
                isRequirementFailure = true
            } else {
                isRequirementFailure = false
            }

            if !isRequirementFailure {
                await sender.send(
                    Test.Event(
                        id: node.id,
                        kind: .issueRecorded,
                        elapsed: elapsed(since: startTime),
                        issue: Test.Issue(
                            kind: .errorCaught(
                                type: Swift.String(describing: type(of: error)),
                                description: Test.Text(Swift.String(describing: error))
                            ),
                            sourceLocation: entry.id.sourceLocation
                        )
                    )
                )
            }
        }

        let expectations = collector.drain()
        let hasExpectationFailures = expectations.contains(where: \.isFailing)

        for expectation in expectations {
            await sender.send(
                Test.Event(
                    id: node.id,
                    kind: .expectationChecked,
                    elapsed: elapsed(since: startTime),
                    expectation: expectation
                )
            )

            if expectation.isFailing {
                await sender.send(
                    Test.Event(
                        id: node.id,
                        kind: .issueRecorded,
                        elapsed: elapsed(since: startTime),
                        issue: Test.Issue(
                            kind: .expectationFailed(expectation.id),
                            sourceLocation: expectation.expression.sourceLocation
                        )
                    )
                )
            }
        }

        if bodyThrew || hasExpectationFailures {
            testResult = .failed
        } else {
            testResult = .passed
        }

        await sender.send(
            Test.Event(
                id: node.id,
                kind: .testEnded,
                elapsed: elapsed(since: startTime),
                result: testResult
            )
        )

        return testResult == .passed
            ? Counters(passed: 1, failed: 0, skipped: 0)
            : Counters(passed: 0, failed: 1, skipped: 0)
    }

    // MARK: - Helpers

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
    private func reason(disabled traits: Test.Trait.Collection) -> Test.Text? {
        traits[Test.Trait.Enabled.self].flatMap { !$0.isEnabled ? $0.comment : nil }
    }

    /// Returns the source location for the node at a position.
    ///
    /// Named `sourceLocation(of:in:)` per [API-NAME-002] — labels
    /// carry the semantics instead of a compound method name.
    private func sourceLocation(
        of position: Tree<Test.Plan.Node?>.Keyed<Swift.String>.Position,
        in tree: Tree<Test.Plan.Node?>.Keyed<Swift.String>
    ) -> Source.Location? {
        switch tree.peek(at: position) as Test.Plan.Node?? {
        case .some(.some(let node)): node.id.sourceLocation
        default: nil
        }
    }

    /// Runs an entry with trait handling via composable scope providers.
    private func run(_ entry: Test.Plan.Entry, traits: Test.Trait.Collection) async throws(Error) {
        let providers = self.scopeProviders
            .filter { $0.shouldActivate(traits) }
            .sorted { $0.priority < $1.priority }

        // Base operation: run the test body
        // Note: L1 isTestContext is propagated by Witness.Context.with(mode: .test)
        // in Testing.Main.runReturningResult — no explicit L1 push needed here.
        var chain: @Sendable () async throws(Error) -> Void = { () async throws(Error) in
            do throws(Test.Body.Error) {
                try await entry.body.run()
            } catch {
                let bodyError =
                    error as? Test.Body.Error
                    ?? .caught(
                        type: Swift.String(describing: type(of: error)),
                        description: Swift.String(describing: error)
                    )
                throw Error.bodyFailed(bodyError)
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

// MARK: - Structured Records

extension Test.Runner {
    /// Serializes the test plan as a JSON record.
    fileprivate static func planJSON(_ plan: Test.Plan) -> JSON {
        let git = Test.Git.capture()
        let env = Test.Environment.capture()

        let tests: [JSON] = plan.entries.map { entry in
            .object([
                ("id", .string(entry.id.fullyQualifiedName)),
                ("module", .string(entry.id.module)),
                ("suite", entry.id.suite.map { .string($0) } ?? .null),
                ("name", .string(entry.id.name)),
            ])
        }

        return .object([
            (
                "git",
                .object([
                    ("sha", git.sha.map { .string($0) } ?? .null),
                    ("branch", git.branch.map { .string($0) } ?? .null),
                    ("dirty", git.dirty.map { .bool($0) } ?? .null),
                ])
            ),
            ("environment", env.json),
            ("tests", .array(tests)),
            (
                "counts",
                .object([
                    ("discovered", .number(plan.count))
                ])
            ),
        ])
    }

    /// Serializes the run summary as a JSON record.
    private static func summaryJSON(_ counters: Counters, elapsed: Duration) -> JSON {
        .object([
            ("duration_seconds", .number(elapsed.inSeconds)),
            (
                "counts",
                .object([
                    ("passed", .number(counters.passed)),
                    ("failed", .number(counters.failed)),
                    ("skipped", .number(counters.skipped)),
                ])
            ),
        ])
    }
}

// MARK: - Counters

extension Test.Runner {
    /// Aggregated test result counters.
    ///
    /// Each `walk` call returns a `Counters` value. These are aggregated
    /// functionally — no shared mutable state needed, even across concurrent
    /// task groups.
    private struct Counters: Sendable {
        var passed: Int = 0
        var failed: Int = 0
        var skipped: Int = 0

        static func + (lhs: Self, rhs: Self) -> Self {
            Self(
                passed: lhs.passed + rhs.passed,
                failed: lhs.failed + rhs.failed,
                skipped: lhs.skipped + rhs.skipped
            )
        }

        static func += (lhs: inout Self, rhs: Self) {
            lhs = lhs + rhs
        }
    }
}

// MARK: - Concurrency

extension Test.Runner {
    /// Concurrency mode for test execution.
    public enum Concurrency: Sendable {
        /// System determines concurrency level.
        ///
        /// Sibling tests and suites run in parallel via `withTaskGroup`.
        case automatic

        /// Run tests serially.
        ///
        /// All tests execute sequentially, sorted by source location.
        case serial

        /// Run up to N tests in parallel.
        ///
        /// Uses `withTaskGroup` with backpressure: at most N concurrent
        /// tasks at any time.
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
    }
}

extension Test.Runner.Result {
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

// MARK: - Error

extension Test.Runner {
    /// Errors thrown during test execution.
    public typealias Error = Test.Trait.Scope.Provider.Error
}
