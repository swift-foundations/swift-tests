//
//  Test.Plan.swift
//  swift-tests
//
//  Test execution plan.
//

public import Test_Primitives

extension Test {
    /// An execution plan for running tests.
    ///
    /// A `Plan` organizes tests into a hierarchy using `Tree.Keyed<String, Node?>`.
    /// Suites group tests and provide trait inheritance. The ``Test/Runner``
    /// walks this tree to execute tests with correct concurrency and trait
    /// propagation.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var registry = Test.Plan.Registry()
    /// registry.add(suite: suiteRegistration)
    /// registry.add(
    ///     id: testID,
    ///     modifiers: [.timeLimit(.seconds(30))],
    ///     body: { /* test code */ }
    /// )
    /// let plan = registry.finalize()
    /// ```
    public struct Plan: Sendable {
        /// The hierarchical test tree.
        ///
        /// Keys are path components (module, suite segments, test name).
        /// Values are `Node?` where `nil` represents structural intermediates
        /// (module boundaries or implicit suite nesting levels not explicitly
        /// registered as suites).
        public let tree: Tree.Keyed<String, Node?>

        /// Creates a plan from a hierarchical tree.
        ///
        /// - Parameter tree: The test tree with propagated traits.
        internal init(tree: Tree.Keyed<String, Node?>) {
            self.tree = tree
        }

        /// Creates a plan from flat entries (backward compatibility).
        ///
        /// Builds a tree from the entries, using `components(for:)` to
        /// determine each entry's position. Traits are resolved per-entry
        /// (no inheritance since there are no explicit suites).
        ///
        /// - Parameter entries: The test entries to include.
        internal init(entries: [Entry]) {
            var tree = Tree.Keyed<String, Node?>()
            for entry in entries {
                tree[Self.components(for: entry.id)] = Node(
                    id: entry.id,
                    modifiers: entry.modifiers,
                    body: entry.body,
                    traits: Test.Trait.Collection(modifiers: entry.modifiers)
                )
            }
            self.tree = tree
        }

        /// Flattened test entries for backward compatibility.
        ///
        /// Performs a pre-order traversal collecting all test nodes (nodes
        /// with bodies). Suite nodes and structural intermediates are excluded.
        public var entries: [Entry] {
            guard let root = tree.root else { return [] }
            var result: [Entry] = []
            var stack: [Tree.Position] = [root]
            while let pos = stack.popLast() {
                if let nodeOpt: Node? = tree.peek(at: pos),
                   let node = nodeOpt,
                   let body = node.body {
                    result.append(Entry(id: node.id, modifiers: node.modifiers, body: body))
                }
                if let children = tree.children(of: pos) {
                    for (_, childPos) in children.reversed() {
                        stack.append(childPos)
                    }
                }
            }
            return result
        }

        /// Whether this plan has no entries.
        public var isEmpty: Bool {
            tree.root == nil
        }

        /// The number of test entries in this plan.
        ///
        /// Only counts test nodes (nodes with bodies), not suites or
        /// structural intermediates.
        public var count: Int {
            entries.count
        }
    }
}

// MARK: - Key Path Components

extension Test.Plan {
    /// Converts a Test.ID into tree key path components.
    ///
    /// The key path is: `[module] + suite.split(".") + [name]` (empty names omitted).
    ///
    /// Examples:
    /// - `Test.ID(module: "M", suite: nil, name: "t")` → `["M", "t"]`
    /// - `Test.ID(module: "M", suite: "A.B", name: "t")` → `["M", "A", "B", "t"]`
    /// - `Test.ID(module: "M", suite: "S", name: "")` → `["M", "S"]` (suite registration)
    ///
    /// Named `components` per [API-NAME-002] — the `Test.Plan` context
    /// already establishes the tree key path domain.
    ///
    /// - Parameter id: The test or suite identifier.
    /// - Returns: The key path components for tree insertion.
    public static func components(for id: Test.ID) -> [String] {
        var path = [id.module]
        if let suite = id.suite {
            path.append(contentsOf: suite.split(separator: ".").map(String.init))
        }
        if !id.name.isEmpty {
            path.append(id.name)
        }
        return path
    }
}

// MARK: - Filtering

extension Test.Plan {
    /// Returns a new plan containing only entries matching the predicate.
    ///
    /// - Parameter isIncluded: A closure that returns true for entries to include.
    /// - Returns: A filtered plan.
    public func filter(_ isIncluded: (Entry) -> Bool) -> Self {
        Self(entries: entries.filter(isIncluded))
    }

    /// Returns a new plan containing only entries with the given tags.
    ///
    /// - Parameter tags: The tags to filter by.
    /// - Returns: A plan containing only matching entries.
    public func filter(tags: Set<Swift.String>.Ordered) -> Self {
        filter { entry in
            let collection = Test.Trait.Collection(modifiers: entry.modifiers)
            let entryTags = collection[Test.Trait.Tag.self]
            return tags.contains(where: { entryTags.contains($0) })
        }
    }

    /// Returns a new plan containing only entries in the given module.
    ///
    /// - Parameter module: The module name to filter by.
    /// - Returns: A plan containing only matching entries.
    public func filter(module: Swift.String) -> Self {
        filter { $0.id.module == module }
    }
}

// MARK: - Sorting

extension Test.Plan {
    /// Returns a new plan with entries sorted by their IDs.
    ///
    /// - Returns: A sorted plan.
    public func sorted() -> Self {
        Self(entries: entries.sorted { $0.id < $1.id })
    }
}
