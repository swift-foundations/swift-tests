//
//  Test.Snapshot.Inline.State.Entry.swift
//  swift-tests
//
//  A single pending inline snapshot entry.
//

public import Test_Primitives

extension Test.Snapshot.Inline.State {
    /// A pending inline snapshot entry awaiting source file write-back.
    ///
    /// Captures all information needed to locate the call site in source
    /// and insert or update the trailing closure with the snapshot value.
    public struct Entry: Sendable {
        /// The expected value from the trailing closure, or `nil` on first run.
        public let expected: Swift.String?

        /// The captured snapshot value.
        public let actual: Swift.String

        /// Whether this entry was produced in recording mode.
        public let wasRecording: Bool

        /// Path to the source file containing the call site.
        public let filePath: Swift.String

        /// The enclosing function name.
        public let function: Swift.String

        /// Line number of the call site (1-based).
        public let line: Int

        /// Column number of the call site (1-based).
        public let column: Int

        public init(
            expected: Swift.String?,
            actual: Swift.String,
            wasRecording: Bool,
            filePath: Swift.String,
            function: Swift.String,
            line: Int,
            column: Int
        ) {
            self.expected = expected
            self.actual = actual
            self.wasRecording = wasRecording
            self.filePath = filePath
            self.function = function
            self.line = line
            self.column = column
        }
    }
}
