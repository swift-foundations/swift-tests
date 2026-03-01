//
//  Test.Trait.Key.Exclusive.swift
//  swift-tests
//
//  Witness key for mutual exclusion traits.
//

extension Test.Trait {
    /// Witness key for mutual exclusion.
    public struct Exclusive: Sendable {
        /// The exclusion group name.
        public let group: Swift.String

        /// The default group for global exclusion.
        public static let globalGroup = "__global__"

        /// Creates an exclusive value.
        public init(group: Swift.String) {
            self.group = group
        }
    }
}

extension Test.Trait.Exclusive: Witness.Key {
    public typealias Value = Test.Trait.Exclusive?

    @inlinable
    public static var liveValue: Test.Trait.Exclusive? { nil }
}
