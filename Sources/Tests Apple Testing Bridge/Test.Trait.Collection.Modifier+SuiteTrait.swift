//
//  Test.Trait.Collection.Modifier+SuiteTrait.swift
//  swift-tests
//
//  Bridges custom trait modifiers to Apple's Swift Testing runner.
//
//  When Apple's test runner discovers suites annotated with the custom @Suite
//  macro, it calls provideScope for each SuiteTrait. This conformance delegates
//  to the modifier's _provideScope closure (if present) to inject dependency
//  scope — making traits like .snapshots(configuration:) work in Xcode.
//

#if canImport(Testing)
public import Testing
public import Test_Primitives

extension Test_Primitives.Test.Trait.Collection.Modifier: Testing.SuiteTrait, Testing.TestScoping {
    public var isRecursive: Bool { true }

    @concurrent
    public func provideScope(
        for test: Testing.Test,
        testCase: Testing.Test.Case?,
        performing function: @Sendable @concurrent () async throws -> Void
    ) async throws {
        if let provideScope = _provideScope {
            try await provideScope(function)
        } else {
            try await function()
        }
    }
}
#endif
