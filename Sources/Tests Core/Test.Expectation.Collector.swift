//
//  Test.Expectation.Collector.swift
//  swift-tests
//
//  Collects expectations during test body execution.
//

public import Dependency_Primitives
import Synchronization
public import Test_Primitives

extension Test.Expectation {
    /// Collects expectations recorded during a test body's execution.
    ///
    /// The runner creates a `Collector` per test and injects it via
    /// `Dependency.Scope`. Assertion functions (`expect`, `assertSnapshot`,
    /// etc.) record each expectation with the current collector. After the
    /// body returns, the runner drains the collector to determine pass/fail.
    ///
    /// ## Safety Invariant
    ///
    /// All mutable state (`_storage`) is guarded by a `Mutex`. All mutation paths
    /// (`record`, `drain`, `hasFailures`) go through `_storage.withLock`.
    ///
    /// ## Intended Use
    ///
    /// - Per-test collection of `expect`/`assertSnapshot` results.
    /// - Injected via `Dependency.Scope` so async test bodies can record.
    ///
    /// ## Non-Goals
    ///
    /// - NOT intended to outlive a single test execution scope.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let collector = Test.Expectation.Collector()
    /// Test.Expectation.Collector.with(collector) {
    ///     expect(true)
    ///     expect(false)
    /// }
    /// let results = collector.drain()
    /// // results[0].isPassing == true
    /// // results[1].isFailing == true
    /// ```
    public final class Collector: @unsafe @unchecked Sendable {

        /// Dependency key for expectation collector injection.
        public enum Key: Dependency.Key {
            public static var liveValue: Collector? { nil }
            public static var testValue: Collector? { nil }
        }

        /// The collector for the current scope, if any.
        public static var current: Collector? {
            Dependency.Scope.current[Key.self]
        }

        private let _storage = Mutex<[Test.Expectation]>([])

        public init() {}

        /// Records an expectation.
        ///
        /// - Parameter expectation: The expectation to record.
        public func record(_ expectation: Test.Expectation) {
            _storage.withLock { $0.append(expectation) }
        }

        /// Drains all recorded expectations, returning them and clearing storage.
        ///
        /// - Returns: All expectations recorded since the last drain.
        public func drain() -> [Test.Expectation] {
            _storage.withLock {
                let result = $0
                $0 = []
                return result
            }
        }

        /// Whether any recorded expectation is failing.
        public var hasFailures: Bool {
            _storage.withLock { $0.contains { $0.isFailing } }
        }
    }
}

// MARK: - Scoped Collector

extension Test.Expectation.Collector {
    /// Runs an operation with the given collector.
    ///
    /// The collector is available via ``current`` within the operation.
    ///
    /// - Parameters:
    ///   - collector: The collector to use.
    ///   - operation: The operation to run.
    /// - Returns: The operation's result.
    public static func with<T, E: Swift.Error>(
        _ collector: Test.Expectation.Collector,
        operation: () throws(E) -> T
    ) throws(E) -> T {
        try Dependency.Scope.with({ $0[Key.self] = collector }, operation: operation)
    }

    /// Runs an async operation with the given collector.
    ///
    /// - Parameters:
    ///   - collector: The collector to use.
    ///   - operation: The async operation to run.
    /// - Returns: The operation's result.
    public static func with<T, E: Swift.Error>(
        _ collector: Test.Expectation.Collector,
        operation: () async throws(E) -> T
    ) async throws(E) -> T {
        try await Dependency.Scope.with({ $0[Key.self] = collector }, operation: operation)
    }
}
