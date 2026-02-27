import Testing
import Tests_Test_Support

@Suite("Test.Plan.Registry")
struct TestPlanRegistryTests {
    @Suite struct Unit {}
}

// MARK: - Unit

extension TestPlanRegistryTests.Unit {
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
        registry.add(id: .stub("sync")) { /* sync body */ }
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
}
