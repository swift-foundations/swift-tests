//
//  Test.Snapshot.Counter.swift
//  swift-tests
//
//  Per-test counter for unnamed snapshots.
//

public import Test_Primitives
import Synchronization

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
    /// The counter is keyed by the combination of test file path and function name,
    /// ensuring unique numbering per test.
    public final class Counter: @unchecked Sendable {
        private var counts: [String: Int] = [:]
        private let lock = Mutex(())

        /// Creates a new counter.
        public init() {}

        /// Gets the next counter value for a key.
        ///
        /// - Parameter key: Unique key (typically `<filePath>/<function>`).
        /// - Returns: The next sequential number (1, 2, 3, ...).
        public func next(for key: String) -> Int {
            lock.withLock { _ in
                counts[key, default: 0] += 1
                return counts[key]!
            }
        }

        /// Resets all counters.
        ///
        /// Call between test runs to ensure fresh numbering.
        public func reset() {
            _ = lock.withLock { _ in
                counts.removeAll()
            }
        }

        /// Resets the counter for a specific key.
        ///
        /// - Parameter key: The key to reset.
        public func reset(for key: String) {
            _ = lock.withLock { _ in
                counts.removeValue(forKey: key)
            }
        }
    }

    /// Task-local counter for snapshot numbering.
    ///
    /// Each test execution should set up its own counter via ``withCounter(_:operation:)``.
    @TaskLocal
    public static var counter = Counter()
}

// MARK: - Counter Key Generation

extension Test.Snapshot.Counter {
    /// Generates a counter key from source location and function.
    ///
    /// - Parameters:
    ///   - filePath: The test file path.
    ///   - function: The test function name.
    /// - Returns: A unique key for this test.
    public static func key(filePath: String, function: String) -> String {
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
    public static func withCounter<T>(
        _ counter: Counter = Counter(),
        operation: () throws -> T
    ) rethrows -> T {
        try $counter.withValue(counter) {
            try operation()
        }
    }

    /// Runs an async operation with a fresh counter.
    ///
    /// - Parameters:
    ///   - counter: The counter to use.
    ///   - operation: The async operation to run.
    /// - Returns: The operation's result.
    public static func withCounter<T>(
        _ counter: Counter = Counter(),
        operation: () async throws -> T
    ) async rethrows -> T {
        try await $counter.withValue(counter) {
            try await operation()
        }
    }
}
