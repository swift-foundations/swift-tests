//
//  Test.Plan.Entry.swift
//  swift-tests
//
//  A single entry in an execution plan.
//

public import Test_Primitives

extension Test.Plan {
    /// A single entry in an execution plan.
    public struct Entry: Sendable {
        /// The test identifier.
        public let id: Test.ID

        /// Traits applied to this test.
        public let traits: [Test.Trait]

        /// The test body to execute.
        public let body: Test.Body

        /// Creates a plan entry.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - traits: Traits applied to this test.
        ///   - body: The test body.
        public init(
            id: Test.ID,
            traits: [Test.Trait],
            body: Test.Body
        ) {
            self.id = id
            self.traits = traits
            self.body = body
        }
    }
}
