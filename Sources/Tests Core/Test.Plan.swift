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
    /// A `Plan` contains a collection of test entries to be executed by a
    /// ``Test/Runner``. Plans are built using ``Test/Plan/Registry`` and
    /// are immutable once created.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var registry = Test.Plan.Registry()
    /// registry.add(
    ///     id: testID,
    ///     modifiers: [.timeLimit(.seconds(30))],
    ///     body: { /* test code */ }
    /// )
    /// let plan = registry.finalize()
    /// ```
    public struct Plan: Sendable {
        /// The entries in this plan.
        public let entries: [Entry]

        /// Creates a plan with the given entries.
        ///
        /// - Parameter entries: The test entries to include.
        internal init(entries: [Entry]) {
            self.entries = entries
        }

        /// Whether this plan has no entries.
        public var isEmpty: Bool {
            entries.isEmpty
        }

        /// The number of entries in this plan.
        public var count: Int {
            entries.count
        }
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
    public func filter(tags: Set<String>) -> Self {
        filter { entry in
            let collection = Test.Trait.Collection(modifiers: entry.modifiers)
            let entryTags = collection[Test.Trait.Tag.self]
            return !entryTags.isDisjoint(with: tags)
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
