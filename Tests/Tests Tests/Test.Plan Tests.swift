import Testing
import Tests
import Test_Primitives

@Suite("Test.Plan")
struct TestPlanTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Helpers

private func makeLocation(line: Int = 1) -> Test_Primitives.Test.Source.Location {
    .init(fileID: "TestModule/File.swift", line: line, column: 1)
}

private func makeID(_ name: String, module: String = "TestModule") -> Test_Primitives.Test.ID {
    .init(module: module, name: name, sourceLocation: makeLocation())
}

// MARK: - Unit

extension TestPlanTests.Unit {
    @Test
    func `empty plan has isEmpty true and count zero`() {
        let registry = Test_Primitives.Test.Plan.Registry()
        let plan = registry.finalize()
        #expect(plan.isEmpty)
        #expect(plan.count == 0)
    }

    @Test
    func `plan count matches added entries`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: makeID("test1"), body: .sync {})
        registry.add(id: makeID("test2"), body: .sync {})
        registry.add(id: makeID("test3"), body: .sync {})
        let plan = registry.finalize()
        #expect(plan.count == 3)
    }

    @Test
    func `filter by predicate returns matching entries`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: makeID("a", module: "ModuleA"), body: .sync {})
        registry.add(id: makeID("b", module: "ModuleB"), body: .sync {})
        registry.add(id: makeID("c", module: "ModuleA"), body: .sync {})
        let plan = registry.finalize()

        let filtered = plan.filter { $0.id.module == "ModuleA" }
        #expect(filtered.count == 2)
    }

    @Test
    func `filter by module returns correct entries`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: makeID("a", module: "Alpha"), body: .sync {})
        registry.add(id: makeID("b", module: "Beta"), body: .sync {})
        let plan = registry.finalize()

        let filtered = plan.filter(module: "Alpha")
        #expect(filtered.count == 1)
        #expect(filtered.entries[0].id.module == "Alpha")
    }

    @Test
    func `filter by tags returns tagged entries`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(
            id: makeID("tagged"),
            traits: [.tag("smoke")],
            body: .sync {}
        )
        registry.add(
            id: makeID("untagged"),
            traits: [],
            body: .sync {}
        )
        let plan = registry.finalize()

        let filtered = plan.filter(tags: ["smoke"])
        #expect(filtered.count == 1)
    }

    @Test
    func `sorted orders entries by ID`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: makeID("c"), body: .sync {})
        registry.add(id: makeID("a"), body: .sync {})
        registry.add(id: makeID("b"), body: .sync {})
        let plan = registry.finalize()

        let sorted = plan.sorted()
        #expect(sorted.entries[0].id.name == "a")
        #expect(sorted.entries[1].id.name == "b")
        #expect(sorted.entries[2].id.name == "c")
    }
}

// MARK: - EdgeCase

extension TestPlanTests.EdgeCase {
    @Test
    func `filter returns empty when nothing matches`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: makeID("test", module: "A"), body: .sync {})
        let plan = registry.finalize()

        let filtered = plan.filter(module: "NonExistent")
        #expect(filtered.isEmpty)
        #expect(filtered.count == 0)
    }
}
