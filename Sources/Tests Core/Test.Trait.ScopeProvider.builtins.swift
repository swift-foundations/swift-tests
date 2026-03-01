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
            provideScope: _timeLimitScope
        )
    }

    /// Scope provider for mutual exclusion.
    public static var exclusive: Self {
        Self(
            id: "exclusive",
            priority: 200,
            shouldActivate: { $0[Test.Trait.Exclusive.self] != nil },
            provideScope: _exclusiveScope
        )
    }
}

// MARK: - Scope Implementations

extension Test.Trait.ScopeProvider {
    @Sendable
    private static func _timeLimitScope(
        _ entry: Test.Plan.Entry,
        _ traits: Test.Trait.Collection,
        _ operation: @Sendable () async throws(Error) -> Void
    ) async throws(Error) {
        let limit = traits[Test.Trait.TimeLimit.self]!
        // WORKAROUND: withoutActuallyEscaping uses rethrows which doesn't
        // narrow to typed throws. Catch boundary converts untyped rethrow
        // back to our typed Error.
        // WHEN TO REMOVE: When rethrows supports typed throw inference.
        do {
            try await withoutActuallyEscaping(operation) { escapingOp in
                try await _withTimeout(limit, operation: escapingOp)
            }
        } catch let error as Error {
            throw error
        } catch {
            throw Error.bodyFailed(.caught(
                type: Swift.String(describing: type(of: error)),
                description: Swift.String(describing: error)
            ))
        }
    }

    @Sendable
    private static func _exclusiveScope(
        _ entry: Test.Plan.Entry,
        _ traits: Test.Trait.Collection,
        _ operation: @Sendable () async throws(Error) -> Void
    ) async throws(Error) {
        let group = traits[Test.Trait.Exclusive.self]!.group
        try await Test.Exclusion.Controller.shared.withExclusiveAccess(
            group: group,
            operation
        )
    }
}

// MARK: - Timeout

extension Test.Trait.ScopeProvider {
    /// Sentinel error for timeout detection inside `withThrowingTaskGroup`.
    ///
    /// `withThrowingTaskGroup` uses untyped throws, so we throw this private
    /// sentinel and catch it at the task group boundary, converting to the
    /// typed `.timeLimitExceeded` case.
    private struct _Timeout: Swift.Error {
        let limit: Duration
    }

    /// Runs an operation with a timeout.
    ///
    /// - Note: `withThrowingTaskGroup` erases typed throws. The catch
    ///   boundary here converts between untyped task group errors and
    ///   our typed `Error` enum.
    // WORKAROUND: withoutActuallyEscaping needed because @Sendable closure
    // parameters are non-escaping but addTask requires @escaping.
    // WHEN TO REMOVE: When Swift supports @escaping on closure parameters
    // in @Sendable function types.
    @Sendable
    private static func _withTimeout(
        _ timeout: Duration,
        operation: @escaping @Sendable () async throws(Error) -> Void
    ) async throws(Error) {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await operation()
                }
                group.addTask {
                    try await Task.sleep(for: timeout)
                    throw _Timeout(limit: timeout)
                }
                try await group.next()
                group.cancelAll()
            }
        } catch let error as Error {
            throw error
        } catch let error as _Timeout {
            throw .timeLimitExceeded(limit: error.limit)
        } catch {
            throw .bodyFailed(.caught(
                type: Swift.String(describing: type(of: error)),
                description: Swift.String(describing: error)
            ))
        }
    }
}
