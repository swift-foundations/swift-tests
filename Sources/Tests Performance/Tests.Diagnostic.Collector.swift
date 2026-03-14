//
//  Tests.Diagnostic.Collector.swift
//  swift-tests
//
//  Thread-safe collector for performance diagnostics across test suites.
//

import Synchronization

extension Tests.Diagnostic {
    /// Thread-safe collector for accumulating performance diagnostics
    /// across multiple test suites during a test run.
    ///
    /// Used by the `.timed()` scope provider to register diagnostics
    /// as they complete. After all tests finish, the runner prints
    /// a summary table from the collected diagnostics.
    public final class Collector: Sendable {
        /// Shared collector for the current test run.
        public static let shared = Collector()

        private let _storage = Mutex<[Tests.Diagnostic]>([])

        public init() {}

        /// Registers a diagnostic from a completed `.timed()` test.
        public func append(_ diagnostic: Tests.Diagnostic) {
            _storage.withLock { $0.append(diagnostic) }
        }

        /// Drains all collected diagnostics, resetting the collector.
        public func drain() -> [Tests.Diagnostic] {
            _storage.withLock { diagnostics in
                let result = diagnostics
                diagnostics.removeAll()
                return result
            }
        }

        /// Whether any diagnostics have been collected.
        public var isEmpty: Bool {
            _storage.withLock { $0.isEmpty }
        }
    }
}
