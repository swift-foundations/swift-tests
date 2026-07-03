//
//  Test.Snapshot.Recording.Trait.swift
//  swift-tests
//
//  Swift Testing SuiteTrait/TestTrait bridge for snapshot recording mode.
//
//  Allows `@Suite(.snapshots(record: .all))` to work natively with
//  Apple's Swift Testing runner, without requiring the custom Test.Runner.
//

#if canImport(Testing)
    public import Test_Primitives
    public import Testing
    import Dependency_Primitives

    extension Test_Primitives.Test.Snapshot.Recording {
        /// Swift Testing trait that sets the snapshot recording mode for a suite or test.
        ///
        /// ## Usage
        ///
        /// ```swift
        /// @Suite(.snapshots(record: .all))
        /// struct MySnapshotTests {
        ///     @Test func mySnapshot() {
        ///         assertInlineSnapshot(of: value, as: .lines)
        ///     }
        /// }
        /// ```
        public struct Trait: Testing.SuiteTrait, Testing.TestTrait, Sendable {
            /// The recording mode to apply within this scope.
            public let recording: Test_Primitives.Test.Snapshot.Recording

            /// Propagate to all nested tests and suites.
            public var isRecursive: Bool { true }
        }
    }

    // MARK: - Test Scoping

    extension Test_Primitives.Test.Snapshot.Recording.Trait: Testing.TestScoping {
        @concurrent
        public func provideScope(
            for test: Testing.Test,
            testCase: Testing.Test.Case?,
            performing function: @Sendable @concurrent () async throws -> Void
        ) async throws {
            let config = Test_Primitives.Test.Snapshot.Configuration(recording: recording)
            try await Dependency.Scope.with(
                { $0[Test_Primitives.Test.Snapshot.Configuration.Key.self] = config },
                operation: function
            )
        }
    }

    // MARK: - Trait Factory

    extension Testing.Trait where Self == Test_Primitives.Test.Snapshot.Recording.Trait {
        /// Sets the snapshot recording mode for a suite or test.
        ///
        /// - Parameter recording: The recording mode to use.
        /// - Returns: A trait that configures snapshot recording.
        public static func snapshots(
            record recording: Test_Primitives.Test.Snapshot.Recording
        ) -> Self {
            Test_Primitives.Test.Snapshot.Recording.Trait(recording: recording)
        }
    }
#endif
