import Testing
import Tests_Test_Support

extension Test_Primitives.Test.Plan.Registry {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Test_Primitives.Test.Plan.Registry.Test.Unit {
    @Test
    func `init creates empty registry`() {
        let registry = Test_Primitives.Test.Plan.Registry()
        #expect(registry.count == 0)
    }

    @Test
    func `add increments count`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("test1"), body: .sync {})
        #expect(registry.count == 1)
        registry.add(id: .stub("test2"), body: .sync {})
        #expect(registry.count == 2)
        registry.add(id: .stub("test3"), body: .sync {})
        #expect(registry.count == 3)
    }

    @Test
    func `add with sync body closure`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("sync")) {}
        #expect(registry.count == 1)
    }

    @Test
    func `add with async body closure`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("async")) { @Sendable () async in /* async body */ }
        #expect(registry.count == 1)
    }

    @Test
    func `finalize produces plan with correct count`() {
        // Per [TEST-012]: var binding for mutation, [TEST-013]: consuming last
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("a"), body: .sync {})
        registry.add(id: .stub("b"), body: .sync {})
        #expect(registry.count == 2)

        // Consuming operation — must be last use of registry
        let plan = registry.finalize()
        #expect(plan.count == 2)
        #expect(!plan.isEmpty)
    }

    @Test
    func `components for suite omits empty name`() {
        let suiteID = Test_Primitives.Test.ID(
            module: "M",
            suite: "MySuite",
            name: "",
            sourceLocation: .stub()
        )
        let components = Tests_Core.Test.Plan.components(for: suiteID)
        #expect(components == ["M", "MySuite"])
    }

    @Test
    func `suite trait propagation via finalize`() {
        var registry = Test_Primitives.Test.Plan.Registry()

        // Register a suite with .serialized
        registry.add(
            suite: Tests_Core.Test.Suite.Registration(
                id: .init(module: "M", suite: "MySuite", name: "", sourceLocation: .stub()),
                modifiers: [.serialized]
            )
        )

        // Register a test inside that suite
        registry.add(
            id: .stub("testFoo", module: "M", suite: "MySuite"),
            body: .sync {}
        )

        let plan = registry.finalize()

        // The test node should have inherited .serialized from the suite
        let node: Tests_Core.Test.Plan.Node? = plan.tree["M", "MySuite", "testFoo"]
        #expect(node != nil)
        #expect(node?.traits[Tests_Core.Test.Trait.Serialized.self] == true)
    }
}
