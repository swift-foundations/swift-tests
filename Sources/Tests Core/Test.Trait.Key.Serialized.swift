//
//  Test.Trait.Key.Serialized.swift
//  swift-tests
//
//  Witness key for serialized execution traits.
//

extension Test.Trait {
    /// Witness key for serial execution.
    public struct Serialized: Sendable {}
}

extension Test.Trait.Serialized: Witness.Key {
    public typealias Value = Bool

    @inlinable
    public static var liveValue: Bool { false }
}
