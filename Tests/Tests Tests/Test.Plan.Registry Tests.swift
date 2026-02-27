import Testing
import Tests
import Test_Primitives

@Suite("Test.Plan.Registry")
struct TestPlanRegistryTests {
    @Suite struct Unit {}
}

// MARK: - Helpers

private func makeLocation(line: Int = 1) -> Test_Primitives.Test.Source.Location {
    .init(fileID: "TestModule/File.swift", line: line, column: 1)
}

private func makeID(_ name: String) -> Test_Primitives.Test.ID {
    .init(module: "TestModule", name: name, sourceLocation: makeLocation())
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
        registry.add(id: makeID("test1"), body: .sync {})
        #expect(registry.count == 1)
        registry.add(id: makeID("test2"), body: .sync {})
        #expect(registry.count == 2)
        registry.add(id: makeID("test3"), body: .sync {})
        #expect(registry.count == 3)
    }

    @Test
    func `add with sync body closure`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: makeID("sync")) { /* sync body */ }
        #expect(registry.count == 1)
    }

    @Test
    func `add with async body closure`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: makeID("async")) { @Sendable () async in /* async body */ }
        #expect(registry.count == 1)
    }

    @Test
    func `finalize produces plan with correct count`() {
        // Per [TEST-012]: var binding for mutation, [TEST-013]: consuming last
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: makeID("a"), body: .sync {})
        registry.add(id: makeID("b"), body: .sync {})
        #expect(registry.count == 2)

        // Consuming operation — must be last use of registry
        let plan = registry.finalize()
        #expect(plan.count == 2)
        #expect(!plan.isEmpty)
    }
}
