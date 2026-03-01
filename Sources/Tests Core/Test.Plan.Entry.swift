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

        /// Modifiers that configure this test's trait collection.
        public let modifiers: [Test.Trait.Collection.Modifier]

        /// The test body to execute.
        public let body: Test.Body

        /// Creates a plan entry.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - modifiers: Modifiers for the trait collection.
        ///   - body: The test body.
        public init(
            id: Test.ID,
            modifiers: [Test.Trait.Collection.Modifier] = [],
            body: Test.Body
        ) {
            self.id = id
            self.modifiers = modifiers
            self.body = body
        }
    }
}
