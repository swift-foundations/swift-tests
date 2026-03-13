//
//  Test.Snapshot.Configuration.swift
//  swift-tests
//
//  Task-local snapshot testing configuration.
//

public import Test_Primitives
public import File_System
public import Dependency_Primitives
internal import Kernel
internal import Strings
import Standard_Library_Extensions

extension Test.Snapshot {
    /// Runtime configuration for snapshot testing.
    ///
    /// Configuration can be set at three levels (in precedence order):
    /// 1. Function parameter (highest priority)
    /// 2. Task-local via ``withConfiguration(_:operation:)``
    /// 3. Environment variable `SWIFT_SNAPSHOT_RECORD`
    /// 4. Default (``.missing``)
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Set for a scope
    /// try Test.Snapshot.withConfiguration(.init(recording: .all)) {
    ///     try expectSnapshot(of: output, as: .lines)
    /// }
    ///
    /// // Or via environment variable
    /// // SWIFT_SNAPSHOT_RECORD=all swift test
    /// ```
    public struct Configuration: Sendable {
        /// Default recording mode.
        public var recording: Recording

        /// Custom snapshot directory (nil = `.snapshots` relative to test file).
        public var snapshotDirectory: File.Path?

        /// Custom subdirectory name within the snapshot directory.
        ///
        /// Replaces the default file-stem-based grouping. Use this to group
        /// snapshots by suite name instead of by source file name.
        ///
        /// For example, setting `subdirectory: "PDF.Test.Snapshot"` produces:
        /// ```
        /// .snapshots/PDF.Test.Snapshot/<function>.<name>.<ext>
        /// ```
        /// instead of the default:
        /// ```
        /// .snapshots/Snapshot Tests/<function>.<name>.<ext>
        /// ```
        public var subdirectory: File.Path.Component?

        /// Creates a configuration.
        ///
        /// - Parameters:
        ///   - recording: The recording mode.
        ///   - snapshotDirectory: Custom directory for snapshots.
        ///   - subdirectory: Custom subdirectory name (nil = test file stem).
        public init(
            recording: Recording = .missing,
            snapshotDirectory: File.Path? = nil,
            subdirectory: File.Path.Component? = nil
        ) {
            self.recording = recording
            self.snapshotDirectory = snapshotDirectory
            self.subdirectory = subdirectory
        }

        /// Default configuration.
        ///
        /// Uses ``.missing`` recording mode and stores snapshots alongside tests.
        public static var `default`: Configuration {
            Configuration()
        }

        /// Dependency key for snapshot configuration.
        ///
        /// Provides optional configuration for each scope.
        public enum Key: Dependency.Key {
            public static var liveValue: Configuration? { nil }
            public static var testValue: Configuration? { nil }
        }

        /// Current configuration for this scope.
        public static var current: Configuration? {
            Dependency.Scope.current[Key.self]
        }
    }
}

// MARK: - Configuration Resolution

extension Test.Snapshot.Configuration {
    /// Resolves the effective recording mode.
    ///
    /// Checks (in order):
    /// 1. Explicit parameter
    /// 2. Task-local configuration
    /// 3. Environment variable `SWIFT_SNAPSHOT_RECORD`
    /// 4. Default (``.missing``)
    ///
    /// - Parameter recording: Explicitly provided recording mode, if any.
    /// - Returns: The resolved recording mode.
    public static func resolve(
        recording: Test.Snapshot.Recording?
    ) -> Test.Snapshot.Recording {
        // 1. Explicit parameter takes precedence
        if let recording { return recording }

        // 2. Task-local configuration
        if let current = Test.Snapshot.Configuration.current {
            return current.recording
        }

        // 3. Environment variable
        if let env = unsafe Kernel.Environment.get("SWIFT_SNAPSHOT_RECORD"),
           let mode = Test.Snapshot.Recording(rawValue: Swift.String(env)) {
            return mode
        }

        // 4. Default
        return .missing
    }
}

// MARK: - Scoped Configuration

extension Test.Snapshot {
    /// Runs an operation with the given configuration.
    ///
    /// The configuration is available to all snapshot assertions within the operation.
    ///
    /// - Parameters:
    ///   - configuration: The configuration to use.
    ///   - operation: The operation to run.
    /// - Returns: The operation's result.
    public static func withConfiguration<T, E: Swift.Error>(
        _ configuration: Configuration,
        operation: () throws(E) -> T
    ) throws(E) -> T {
        try Dependency.Scope.with({ $0[Configuration.Key.self] = configuration }, operation: operation)
    }

    /// Runs an async operation with the given configuration.
    ///
    /// - Parameters:
    ///   - configuration: The configuration to use.
    ///   - operation: The async operation to run.
    /// - Returns: The operation's result.
    public static func withConfiguration<T, E: Swift.Error>(
        _ configuration: Configuration,
        operation: () async throws(E) -> T
    ) async throws(E) -> T {
        try await Dependency.Scope.with({ $0[Configuration.Key.self] = configuration }, operation: operation)
    }
}
