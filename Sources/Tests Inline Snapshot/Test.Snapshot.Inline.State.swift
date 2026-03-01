//
//  Test.Snapshot.Inline.State.swift
//  swift-tests
//
//  Thread-safe accumulator for pending inline snapshot writes.
//

public import Test_Primitives
import Synchronization

extension Test.Snapshot.Inline {
    /// Thread-safe accumulator for pending inline snapshot writes during a test run.
    ///
    /// Entries are registered during test execution and drained after all tests
    /// complete, at which point the ``Rewriter`` processes them into source file
    /// modifications.
    public final class State: @unchecked Sendable {
        private let mutex = Mutex<[Swift.String: [Entry]]>([:])

        public init() {}

        /// Registers an entry for deferred write-back.
        ///
        /// - Parameter entry: The inline snapshot entry to register.
        public func register(_ entry: Entry) {
            mutex.withLock { entries in
                entries[entry.filePath, default: []].append(entry)
            }
        }

        /// Drains all accumulated entries, grouped by file path.
        ///
        /// After draining, the state is empty.
        ///
        /// - Returns: Entries grouped by source file path.
        public func drain() -> [Swift.String: [Entry]] {
            mutex.withLock { entries in
                let result = entries
                entries.removeAll()
                return result
            }
        }

        /// Whether there are no pending entries.
        public var isEmpty: Bool {
            mutex.withLock { $0.isEmpty }
        }
    }
}
