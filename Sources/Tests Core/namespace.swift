//
//  namespace.swift
//  swift-tests
//
//  Establishes the Test namespace for this module.
//  Resolves ambiguity with Apple's Testing.Test.
//

public import Test_Primitives

/// The Test namespace from Test_Primitives.
///
/// This typealias ensures unambiguous reference to our Test types
/// even when Apple's Testing module is transitively visible.
public typealias Test = Test_Primitives.Test
