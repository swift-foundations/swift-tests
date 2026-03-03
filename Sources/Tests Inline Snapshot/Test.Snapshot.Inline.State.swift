//
//  Test.Snapshot.Inline.State.swift
//  swift-tests
//
//  Thread-safe accumulator for pending inline snapshot writes.
//

public import Test_Primitives
import Synchronization
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

extension Test.Snapshot.Inline {
    /// Thread-safe accumulator for pending inline snapshot writes during a test run.
    ///
    /// Entries are registered during test execution and drained after all tests
    /// complete, at which point the ``Rewriter`` processes them into source file
    /// modifications.
    ///
    /// An `atexit` handler is lazily registered on first ``register(_:)`` call
    /// to ensure the rewriter fires even when tests run under Apple's Swift
    /// Testing runner (which does not call `Test.Runner.postRunActions`).
    /// When the Institute's runner is active, `postRunActions` drains first
    /// and `atexit` sees empty state — they are safely composable via the
    /// destructive ``drain()`` operation.
    public final class State: @unchecked Sendable {
        private let mutex = Mutex<[Swift.String: [Entry]]>([:])

        public init() {}

        /// One-time `atexit` registration, triggered lazily on first `register()`.
        private static let _installExitHandler: Void = {
            atexit {
                let state = Test.Snapshot.Inline.state
                guard !state.isEmpty else { return }
                do {
                    try Rewriter.writeAll(from: state.drain())
                } catch {
                    // Non-fatal: match the existing behavior in Testing.Main
                    // where write failures print a warning but do not change
                    // test results.
                    print(
                        "Warning: Failed to write inline snapshots from atexit: \(error)"
                    )
                }
            }
        }()

        /// Registers an entry for deferred write-back.
        ///
        /// On first call, installs an `atexit` handler that drains accumulated
        /// state and invokes the rewriter at process exit.
        ///
        /// - Parameter entry: The inline snapshot entry to register.
        public func register(_ entry: Entry) {
            _ = Self._installExitHandler
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
