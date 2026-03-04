//
//  Test.Trait.ScopeProvider.swift
//  swift-tests
//
//  A scope provider that wraps test execution.
//

public import Witness_Primitives

extension Test.Trait {
    /// A scope provider that wraps test execution with trait-specific behavior.
    ///
    /// Scope providers replace the hardcoded execution chain in the runner.
    /// Each provider checks whether it should activate for a given trait collection,
    /// and if so, wraps the test execution with its behavior.
    public struct ScopeProvider: Sendable, Witness.`Protocol` {
        /// Unique identifier for this provider.
        public let id: Swift.String

        /// Execution priority (lower runs first, wrapping outer).
        public let priority: Int

        /// Determines whether this provider should activate for the given traits.
        public var shouldActivate: @Sendable (Test.Trait.Collection) -> Bool

        /// Wraps the test execution with this provider's behavior.
        public var provideScope: @Sendable (
            Test.Plan.Entry,
            Test.Trait.Collection,
            @Sendable () async throws(Error) -> Void
        ) async throws(Error) -> Void

        /// Creates a scope provider.
        ///
        /// - Parameters:
        ///   - id: Unique identifier.
        ///   - priority: Execution priority (lower runs first).
        ///   - shouldActivate: Predicate for activation.
        ///   - provideScope: The scoping closure.
        public init(
            id: Swift.String,
            priority: Int,
            shouldActivate: @escaping @Sendable (Test.Trait.Collection) -> Bool,
            provideScope: @escaping @Sendable (
                Test.Plan.Entry,
                Test.Trait.Collection,
                @Sendable () async throws(Error) -> Void
            ) async throws(Error) -> Void
        ) {
            self.id = id
            self.priority = priority
            self.shouldActivate = shouldActivate
            self.provideScope = provideScope
        }
    }
}
