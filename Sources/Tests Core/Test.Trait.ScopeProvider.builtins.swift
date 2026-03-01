//
//  Test.Trait.ScopeProvider.builtins.swift
//  swift-tests
//
//  Built-in scope providers for core traits.
//

extension Test.Trait.ScopeProvider {
    /// Scope provider for time limit enforcement.
    public static var timeLimit: Self {
        Self(
            id: "timeLimit",
            priority: 100,
            shouldActivate: { $0[Test.Trait.TimeLimit.self] != nil },
            provideScope: { _, traits, operation in
                let limit = traits[Test.Trait.TimeLimit.self]!
                try await withoutActuallyEscaping(operation) { escapingOp in
                    try await _withTimeout(limit, operation: escapingOp)
                }
            }
        )
    }

    /// Scope provider for mutual exclusion.
    public static var exclusive: Self {
        Self(
            id: "exclusive",
            priority: 200,
            shouldActivate: { $0[Test.Trait.Exclusive.self] != nil },
            provideScope: { _, traits, operation in
                let group = traits[Test.Trait.Exclusive.self]!.group
                try await Test.Exclusion.Controller.shared.withExclusiveAccess(
                    group: group,
                    operation
                )
            }
        )
    }
}

// MARK: - Timeout

extension Test.Trait.ScopeProvider {
    /// Runs an operation with a timeout.
    @Sendable
    private static func _withTimeout(
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
            try await group.next()
            group.cancelAll()
        }
    }
}

// MARK: - Errors

extension Test.Trait.ScopeProvider {
    /// Error thrown when a test exceeds its time limit.
    public struct TimeLimitExceeded: Swift.Error, Sendable {
        /// The time limit that was exceeded.
        public let limit: Duration
    }
}
