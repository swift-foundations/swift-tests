//
//  Test.Plan.Node.swift
//  swift-tests
//
//  Tree node value for hierarchical test plans.
//

public import Test_Primitives

extension Test.Plan {
    /// A node in the hierarchical test plan tree.
    ///
    /// Nodes represent either suites (grouping containers) or tests
    /// (executable entries). The distinction is determined by the presence
    /// of a ``body``:
    /// - Suite nodes: `body == nil`, provide trait inheritance to children
    /// - Test nodes: `body != nil`, executable with scope providers
    ///
    /// `nil` values in `Tree<Node?>.Keyed<String>` represent structural
    /// intermediates — module boundaries or implicit nesting levels that
    /// were not explicitly registered as suites.
    public struct Node: Sendable {
        /// The identifier for this node.
        public let id: Test.ID

        /// The modifiers declared directly on this node.
        ///
        /// These are the node's own modifiers, not including inherited ones.
        /// After trait propagation, ``traits`` contains the merged result of
        /// inherited parent modifiers plus these own modifiers.
        public let modifiers: [Test.Trait.Collection.Modifier]

        /// The test body, or `nil` for suite nodes.
        public let body: Test.Body?

        /// The resolved trait collection after inheritance propagation.
        ///
        /// During `Registry.finalize()`, parent modifiers are propagated
        /// to children via pre-order traversal. This property holds the
        /// merged result: inherited modifiers applied first, then own
        /// modifiers applied on top (last-write-wins).
        public var traits: Test.Trait.Collection

        /// Whether this node is a suite (has no body).
        public var isSuite: Bool { body == nil }

        /// Whether this node is a test (has a body).
        public var isTest: Bool { body != nil }

        /// Creates a node.
        ///
        /// - Parameters:
        ///   - id: The node identifier.
        ///   - modifiers: Modifiers declared on this node.
        ///   - body: The test body, or nil for suites.
        ///   - traits: The resolved trait collection.
        public init(
            id: Test.ID,
            modifiers: [Test.Trait.Collection.Modifier] = [],
            body: Test.Body? = nil,
            traits: Test.Trait.Collection = Test.Trait.Collection()
        ) {
            self.id = id
            self.modifiers = modifiers
            self.body = body
            self.traits = traits
        }
    }
}
