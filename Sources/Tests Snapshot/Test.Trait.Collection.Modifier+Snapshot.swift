//
//  Test.Trait.Collection.Modifier+Snapshot.swift
//  swift-tests
//
//  Snapshot modifier factory for macro-declared snapshot configuration.
//

import Dependency_Primitives

extension Test.Trait.Collection.Modifier {
    /// Creates a modifier that sets snapshot configuration on the trait collection.
    ///
    /// Used in `@Suite` and `#Tests` macro expansions:
    /// ```swift
    /// @Suite(.serialized, .snapshots(configuration: config))
    /// struct MySnapshotTests { }
    /// ```
    ///
    /// - Parameter configuration: The snapshot configuration to apply.
    /// - Returns: A modifier that sets the snapshot recording mode.
    public static func snapshots(configuration: Test.Snapshot.Configuration) -> Self {
        Self(
            apply: { collection in
                collection[Test.Trait.Snapshot.self] = Test.Trait.Snapshot(
                    recording: configuration.recording
                )
            },
            provideScope: { function in
                try await Dependency.Scope.with(
                    { $0[Test.Snapshot.Configuration.Key.self] = configuration },
                    operation: function
                )
            }
        )
    }

    /// Creates a modifier that sets snapshot recording mode.
    ///
    /// Shorthand for `.snapshots(configuration: .init(recording: recording))`.
    ///
    /// ```swift
    /// @Suite(.serialized, .snapshots(record: .missing))
    /// struct MySnapshotTests { }
    /// ```
    ///
    /// - Parameter recording: The recording mode to apply.
    /// - Returns: A modifier that sets the snapshot recording mode.
    public static func snapshots(record recording: Test.Snapshot.Recording) -> Self {
        .snapshots(configuration: .init(recording: recording))
    }
}
