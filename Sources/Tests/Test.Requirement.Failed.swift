//
//  Test.Requirement.Failed.swift
//  swift-tests
//
//  Error thrown when a test requirement fails.
//

public import Test_Primitives

extension Test.Requirement {
    /// Error thrown when a requirement fails.
    ///
    /// Contains information about what failed and where.
    public struct Failed: Swift.Error, Sendable {
        /// A message describing the failure.
        public let message: Test.Text

        /// The source location where the requirement failed.
        public let sourceLocation: Test.Source.Location

        /// Creates a requirement failure.
        ///
        /// - Parameters:
        ///   - message: The failure message.
        ///   - sourceLocation: Where the failure occurred.
        public init(message: Test.Text, sourceLocation: Test.Source.Location) {
            self.message = message
            self.sourceLocation = sourceLocation
        }
    }
}

extension Test.Requirement.Failed: CustomStringConvertible {
    public var description: Swift.String {
        "\(message.plainText) at \(sourceLocation)"
    }
}
