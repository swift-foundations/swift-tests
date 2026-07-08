//
//  Test.Snapshot.Counter.swift
//  swift-tests
//
//  Per-test counter for unnamed snapshots.
//

public import Dependency_Primitives
import Synchronization
public import Test_Primitives

extension Test.Snapshot {
    /// Thread-safe counter for unnamed snapshots within a test.
    ///
    /// Each test function needs sequential numbering for multiple unnamed snapshots:
    /// ```swift
    /// @Test func testMultiple() {
    ///     expectSnapshot(of: a, as: .lines)  // testMultiple.1.txt
    ///     expectSnapshot(of: b, as: .lines)  // testMultiple.2.txt
    ///     expectSnapshot(of: c, as: .lines)  // testMultiple.3.txt
    /// }
    /// ```
    ///
    /// ## Safety Invariant
    ///
    /// All mutable state (`counts` dictionary) is guarded by a `Mutex`. Every
    /// mutation path goes through `lock.withLock`.
    ///
    /// ## Intended Use
    ///
    /// - Sequential numbering per test function for unnamed `expectSnapshot` calls.
    /// - Shared as a `Dependency.Scope` dependency across a test run.
    ///
    /// ## Non-Goals
    ///
    /// - NOT a general-purpose counter; specific to snapshot numbering.
    public final class Counter: @unsafe @unchecked Sendable {
        private var counts: [String: Int] = [:]
        private let lock = Mutex(())

        /// Creates a new counter.
        public init() {}
    }

    /// Current counter for snapshot numbering.
    ///
    /// Each test execution should set up its own counter via ``withCounter(_:operation:)``.
    public static var counter: Counter {
        Dependency.Scope.current[Counter.Key.self]
    }
}

extension Test.Snapshot.Counter {
    /// Gets the next counter value for a key.
    ///
    /// - Parameter key: Unique key (typically `<filePath>/<function>`).
    /// - Returns: The next sequential number (1, 2, 3, ...).
    public func next(for key: Swift.String) -> Int {
        lock.withLock { _ in
            counts[key, default: 0] += 1
            return counts[key]!
        }
    }

    /// Resets all counters.
    ///
    /// Call between test runs to ensure fresh numbering.
    public func reset() {
        lock.withLock { _ in
            counts.removeAll()
        }
    }

    /// Resets the counter for a specific key.
    ///
    /// - Parameter key: The key to reset.
    public func reset(for key: Swift.String) {
        _ = lock.withLock { _ in
            counts.removeValue(forKey: key)
        }
    }
}

// MARK: - Counter Key

extension Test.Snapshot.Counter {
    /// Dependency key for snapshot counter.
    ///
    /// Provides a default counter for each scope.
    public enum Key: Dependency.Key {
    }
}

extension Test.Snapshot.Counter.Key {
    public typealias Value = Test.Snapshot.Counter
    public static var liveValue: Value { Value() }
    public static var testValue: Value { Value() }
}

// MARK: - Counter Key Generation

extension Test.Snapshot.Counter {
    /// Generates a counter key from source location and function.
    ///
    /// - Parameters:
    ///   - filePath: The test file path.
    ///   - function: The test function name.
    /// - Returns: A unique key for this test.
    public static func key(filePath: Swift.String, function: Swift.String) -> Swift.String {
        "\(filePath)/\(function)"
    }
}

// MARK: - Scoped Counter

extension Test.Snapshot {
    /// Runs an operation with a fresh counter.
    ///
    /// Use this to ensure each test gets fresh snapshot numbering:
    /// ```swift
    /// Test.Snapshot.withCounter(Counter()) {
    ///     // Snapshots in here start at 1
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - counter: The counter to use (defaults to a new counter).
    ///   - operation: The operation to run.
    /// - Returns: The operation's result.
    public static func withCounter<T, E: Swift.Error>(
        _ counter: Counter = Counter(),
        operation: () throws(E) -> T
    ) throws(E) -> T {
        try Dependency.Scope.with({ $0[Counter.Key.self] = counter }, operation: operation)
    }

    /// Runs an async operation with a fresh counter.
    ///
    /// - Parameters:
    ///   - counter: The counter to use.
    ///   - operation: The async operation to run.
    /// - Returns: The operation's result.
    public static func withCounter<T, E: Swift.Error>(
        _ counter: Counter = Counter(),
        operation: () async throws(E) -> T
    ) async throws(E) -> T {
        try await Dependency.Scope.with({ $0[Counter.Key.self] = counter }, operation: operation)
    }
}
