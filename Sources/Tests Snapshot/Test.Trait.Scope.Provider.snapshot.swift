//
//  Test.Trait.Scope.Provider.snapshot.swift
//  swift-tests
//
//  Scope provider for snapshot configuration injection.
//

import Dependency_Primitives

extension Test.Trait.Scope.Provider {
    /// Scope provider that injects snapshot configuration into the dependency scope.
    public static var snapshot: Self {
        Self(
            id: "snapshot",
            priority: 300,
            shouldActivate: { $0[Test.Trait.Snapshot.self] != nil },
            provideScope: _snapshotScope
        )
    }

    @Sendable
    private static func _snapshotScope(
        _ entry: Test.Plan.Entry,
        _ traits: Test.Trait.Collection,
        _ operation: @Sendable () async throws(Error) -> Void
    ) async throws(Error) {
        let snapshot = traits[Test.Trait.Snapshot.self]!
        let config = Test.Snapshot.Configuration(recording: snapshot.recording)
        try await Dependency.Scope.with(
            { $0[Test.Snapshot.Configuration.Key.self] = config },
            operation: operation
        )
    }
}
