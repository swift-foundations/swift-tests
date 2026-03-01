//
//  Test.Trait.Collection.Modifier.swift
//  swift-tests
//
//  Closure-based trait transport that sets witness values on a collection.
//

extension Test.Trait.Collection {
    /// A closure that sets witness values on a trait collection.
    ///
    /// Modifiers are the transport mechanism for trait declarations.
    /// Each modifier encapsulates the effect of a single trait
    /// (e.g., `.serialized` sets `Serialized.self = true`,
    /// `.timeLimit(.seconds(30))` sets `TimeLimit.self = .seconds(30)`).
    ///
    /// Factory methods on this type mirror the existing `Test.Trait`
    /// factories, providing identical names and parameters.
    public struct Modifier: Sendable {
        /// The closure that mutates the collection.
        internal let _apply: @Sendable (inout Test.Trait.Collection) -> Void

        /// Creates a modifier from a mutation closure.
        ///
        /// - Parameter apply: A closure that sets witness values on the collection.
        public init(_ apply: @escaping @Sendable (inout Test.Trait.Collection) -> Void) {
            self._apply = apply
        }

        /// Applies this modifier to the given collection.
        ///
        /// - Parameter collection: The collection to mutate.
        public func apply(to collection: inout Test.Trait.Collection) {
            _apply(&collection)
        }
    }
}
