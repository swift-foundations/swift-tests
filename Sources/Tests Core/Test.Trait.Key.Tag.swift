//
//  Test.Trait.Key.Tag.swift
//  swift-tests
//
//  Witness key for tag traits.
//

extension Test.Trait {
    /// Witness key for tag collection.
    public struct Tag: Sendable {}
}

extension Test.Trait.Tag: Witness.Key {
    public typealias Value = Set<Swift.String>.Ordered

    @inlinable
    public static var liveValue: Set<Swift.String>.Ordered { [] }
}
