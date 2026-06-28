//
//  Test.Exclusion.Controller.swift
//  swift-tests
//
//  Actor that provides mutual exclusion for test execution.
//

public import Test_Primitives
public import Set_Primitives
public import Set_Ordered_Primitives
public import Hash_Indexed_Primitive
public import Column_Primitives
public import Shared_Primitive
public import Buffer_Linear_Primitive

extension Test.Exclusion {
    /// Actor that provides mutual exclusion for test execution.
    ///
    /// Uses a keyed semaphore pattern: tests with the same group key
    /// are mutually exclusive.
    public actor Controller {
        /// Shared singleton instance.
        public static let shared = Controller()

        /// Tracks which groups are currently running.
        private var runningGroups: Set<Shared<Swift.String, Hash.Indexed<Column.Heap<Swift.String>>>>.Ordered = .init()

        /// Continuations waiting for access, keyed by group.
        private var waiters: [Swift.String: [CheckedContinuation<Void, Never>]] = [:]

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
        public func withExclusiveAccess<T: Sendable, E: Swift.Error>(
            group: Swift.String,
            _ operation: @Sendable () async throws(E) -> T
        ) async throws(E) -> T {
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
}

