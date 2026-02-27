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
    /// `Registry` is a ~Copyable type that accumulates test entries and
    /// produces a finalized ``Test/Plan`` exactly once.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var registry = Test.Plan.Registry()
    ///
    /// registry.add(
    ///     id: Test.ID(module: "MyTests", name: "testExample", sourceLocation: loc),
    ///     traits: [],
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
        /// Accumulated entries.
        private var entries: [Entry]

        /// Creates an empty registry.
        public init() {
            self.entries = []
        }

        /// Adds a test entry to the registry.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - traits: Traits to apply to this test.
        ///   - body: The test body.
        public mutating func add(
            id: Test.ID,
            traits: [Test.Trait] = [],
            body: Test.Body
        ) {
            entries.append(Entry(id: id, traits: traits, body: body))
        }

        /// Adds a synchronous test to the registry.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - traits: Traits to apply to this test.
        ///   - body: The synchronous test body.
        public mutating func add<E: Swift.Error>(
            id: Test.ID,
            traits: [Test.Trait] = [],
            body: @escaping @Sendable () throws(E) -> Void
        ) {
            add(id: id, traits: traits, body: .sync(body))
        }

        /// Adds an asynchronous test to the registry.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - traits: Traits to apply to this test.
        ///   - body: The asynchronous test body.
        public mutating func add<E: Swift.Error>(
            id: Test.ID,
            traits: [Test.Trait] = [],
            body: @escaping @Sendable () async throws(E) -> Void
        ) {
            add(id: id, traits: traits, body: .async(body))
        }

        /// Finalizes the registry and produces a plan.
        ///
        /// This consumes the registry - it cannot be used after calling this method.
        ///
        /// - Returns: The finalized test plan.
        public consuming func finalize() -> Test.Plan {
            Test.Plan(entries: entries)
        }

        /// The current number of entries in the registry.
        public var count: Int {
            entries.count
        }
    }
}
