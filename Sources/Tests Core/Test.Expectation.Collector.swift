//
//  Test.Expectation.Collector.swift
//  swift-tests
//
//  Collects expectations during test body execution.
//

public import Test_Primitives
public import Dependency_Primitives
import Synchronization

extension Test.Expectation {
    /// Collects expectations recorded during a test body's execution.
    ///
    /// The runner creates a `Collector` per test and injects it via
    /// `Dependency.Scope`. Assertion functions (`expect`, `assertSnapshot`,
    /// etc.) record each expectation with the current collector. After the
    /// body returns, the runner drains the collector to determine pass/fail.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let collector = Test.Expectation.Collector()
    /// Dependency.Scope.with({ $0[Test.Expectation.Collector.Key.self] = collector }) {
    ///     expect(true)
    ///     expect(false)
    /// }
    /// let results = collector.drain()
    /// // results[0].isPassing == true
    /// // results[1].isFailing == true
    /// ```
    public final class Collector: @unchecked Sendable {
        /// The collector for the current task, if any.
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

// MARK: - Dependency.Key

extension Test.Expectation.Collector {
    /// Dependency key for expectation collector injection.
    public enum Key: Dependency.Key {
        public static var liveValue: Test.Expectation.Collector? { nil }
        public static var testValue: Test.Expectation.Collector? { nil }
    }
}
