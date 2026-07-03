//
//  Test.Trait.Key.Tag.swift
//  swift-tests
//
//  Witness key for tag traits.
//

public import Buffer_Linear_Primitive
public import Column_Primitives
public import Hash_Indexed_Primitive
public import Set_Ordered_Primitives
public import Set_Primitives
public import Shared_Primitive

extension Test.Trait {
    /// Witness key for tag collection.
    public struct Tag: Sendable {}
}

extension Test.Trait.Tag: Witness.Key {
    public typealias Value = Set<Shared<Swift.String, Hash.Indexed<Column.Heap<Swift.String>>>>.Ordered

    @inlinable
    public static var liveValue: Value { .init() }
}
