//
//  Test.Trait.Key.Bug.swift
//  swift-tests
//
//  Witness key for bug reference traits.
//

extension Test.Trait {
    /// Witness key for bug reference.
    public struct Bug: Sendable {
        /// The bug tracker identifier.
        public let id: Swift.String

        /// Optional context.
        public let comment: Test.Text?

        /// Creates a bug reference.
        public init(id: Swift.String, comment: Test.Text? = nil) {
            self.id = id
            self.comment = comment
        }
    }
}

extension Test.Trait.Bug: Witness.Key {
    public typealias Value = Test.Trait.Bug?

    @inlinable
    public static var liveValue: Test.Trait.Bug? { nil }
}
