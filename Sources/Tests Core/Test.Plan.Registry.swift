//
//  Test.Plan.Registry.swift
//  swift-tests
//
//  ~Copyable builder for test plans.
//

public import Test_Primitives

extension Test.Plan {
    /// A builder for creating test execution plans.
    ///
    /// `Registry` is a ~Copyable type that accumulates suite registrations
    /// and test entries, then produces a finalized ``Test/Plan`` with a
    /// hierarchical tree exactly once.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var registry = Test.Plan.Registry()
    ///
    /// registry.add(suite: Test.Suite.Registration(
    ///     id: Test.ID(module: "MyTests", name: "MySuite", sourceLocation: loc),
    ///     modifiers: [.serialized]
    /// ))
    ///
    /// registry.add(
    ///     id: Test.ID(module: "MyTests", suite: "MySuite", name: "testExample", sourceLocation: loc),
    ///     modifiers: [],
    ///     body: .sync { #expect(true) }
    /// )
    ///
    /// let plan = registry.finalize()
    /// // registry is consumed - cannot be used again
    /// ```
    ///
    /// ## Ownership
    ///
    /// The ~Copyable constraint ensures:
    /// - Each registry produces exactly one plan
    /// - Test registration cannot be accidentally duplicated
    /// - The finalize operation is explicit and consuming
    public struct Registry: ~Copyable, Sendable {
        /// Accumulated test entries.
        private var entries: [Entry]

        /// Accumulated suite registrations.
        private var suites: [Test.Suite.Registration]

        /// Creates an empty registry.
        public init() {
            self.entries = []
            self.suites = []
        }

        /// Adds a suite registration to the registry.
        ///
        /// Suites group tests and provide trait inheritance. Modifiers
        /// on a suite are inherited by all descendant tests and suites
        /// during `finalize()`.
        ///
        /// - Parameter suite: The suite registration.
        public mutating func add(suite: Test.Suite.Registration) {
            suites.append(suite)
        }

        /// Adds a test entry to the registry.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - modifiers: Modifiers for the trait collection.
        ///   - body: The test body.
        public mutating func add(
            id: Test.ID,
            modifiers: [Test.Trait.Collection.Modifier] = [],
            body: Test.Body
        ) {
            entries.append(Entry(id: id, modifiers: modifiers, body: body))
        }

        /// Adds a synchronous test to the registry.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - modifiers: Modifiers for the trait collection.
        ///   - body: The synchronous test body.
        public mutating func add<E: Swift.Error>(
            id: Test.ID,
            modifiers: [Test.Trait.Collection.Modifier] = [],
            body: @escaping @Sendable () throws(E) -> Void
        ) {
            add(id: id, modifiers: modifiers, body: .sync(body))
        }

        /// Adds an asynchronous test to the registry.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - modifiers: Modifiers for the trait collection.
        ///   - body: The asynchronous test body.
        public mutating func add<E: Swift.Error>(
            id: Test.ID,
            modifiers: [Test.Trait.Collection.Modifier] = [],
            body: @escaping @Sendable () async throws(E) -> Void
        ) {
            add(id: id, modifiers: modifiers, body: .async(body))
        }

        /// Finalizes the registry and produces a hierarchical plan.
        ///
        /// This consumes the registry. The finalization process:
        /// 1. Inserts suites into the tree (as nodes with `body == nil`)
        /// 2. Inserts tests into the tree (as nodes with `body != nil`)
        /// 3. Propagates traits from parent suites to descendant nodes
        ///
        /// Intermediate nodes not explicitly registered as suites are created
        /// with `nil` values (structural intermediates) by Tree.Keyed's sparse
        /// insert.
        ///
        /// - Returns: The finalized test plan.
        public consuming func finalize() -> Test.Plan {
            var tree = TreeKeyed<Node?, String>()

            // 1. Insert suites
            for suite in suites {
                tree[Test.Plan.components(for: suite.id)] = Node(
                    id: suite.id,
                    modifiers: suite.modifiers,
                    body: nil
                )
            }

            // 2. Insert tests
            for entry in entries {
                tree[Test.Plan.components(for: entry.id)] = Node(
                    id: entry.id,
                    modifiers: entry.modifiers,
                    body: entry.body,
                    traits: Test.Trait.Collection(modifiers: entry.modifiers)
                )
            }

            // 3. Propagate traits from parents to children
            if let root = tree.root {
                Self.propagate(through: &tree, from: root, inherited: [])
            }

            return Test.Plan(tree: tree)
        }

        /// The current number of entries in the registry.
        public var count: Int {
            entries.count
        }
    }
}

// MARK: - Trait Propagation

extension Test.Plan.Registry {
    /// Propagates inherited modifiers from parent nodes to children.
    ///
    /// Named `propagate(through:from:inherited:)` per [API-NAME-002] —
    /// single-word verb with descriptive parameter labels.
    ///
    /// Uses recursive pre-order traversal. At each node:
    /// - Structural `nil` nodes pass inherited modifiers through unchanged.
    /// - Real nodes merge `inherited + own` modifiers into a resolved
    ///   trait collection. Children receive the merged set.
    ///
    /// Parent modifiers apply first, child modifiers override (last-write-wins
    /// via `Modifier.apply(to:)`).
    ///
    /// - Parameters:
    ///   - tree: The tree to mutate in place.
    ///   - position: The current position.
    ///   - inherited: Modifiers accumulated from ancestor nodes.
    private static func propagate(
        through tree: inout TreeKeyed<Test.Plan.Node?, String>,
        from position: TreeKeyed<Test.Plan.Node?, String>.Position,
        inherited: [Test.Trait.Collection.Modifier]
    ) {
        let passDown: [Test.Trait.Collection.Modifier]

        switch tree.peek(at: position) as Test.Plan.Node?? {
        case nil:
            return
        case .some(nil):
            passDown = inherited
        case .some(.some(var node)):
            node.traits = Test.Trait.Collection(modifiers: inherited + node.modifiers)
            _ = try? tree.update(at: position, node)
            passDown = inherited + node.modifiers
        }

        guard let children = tree.children(of: position) else { return }
        for (_, childPos) in children {
            propagate(through: &tree, from: childPos, inherited: passDown)
        }
    }
}
