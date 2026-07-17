import Testing
import Tests_Test_Support

extension Test_Primitives.Test.Plan {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

// MARK: - Unit

extension Test_Primitives.Test.Plan.Test.Unit {
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
        registry.add(id: .stub("test1"), body: .sync {})
        registry.add(id: .stub("test2"), body: .sync {})
        registry.add(id: .stub("test3"), body: .sync {})
        let plan = registry.finalize()
        #expect(plan.count == 3)
    }

    @Test
    func `filter by predicate returns matching entries`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("a", module: "ModuleA"), body: .sync {})
        registry.add(id: .stub("b", module: "ModuleB"), body: .sync {})
        registry.add(id: .stub("c", module: "ModuleA"), body: .sync {})
        let plan = registry.finalize()

        let filtered = plan.filter { $0.id.module == "ModuleA" }
        #expect(filtered.count == 2)
    }

    @Test
    func `filter by module returns correct entries`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("a", module: "Alpha"), body: .sync {})
        registry.add(id: .stub("b", module: "Beta"), body: .sync {})
        let plan = registry.finalize()

        let filtered = plan.filter(module: "Alpha")
        #expect(filtered.count == 1)
        #expect(filtered.entries[0].id.module == "Alpha")
    }

    @Test
    func `filter by tags returns tagged entries`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(
            id: .stub("tagged"),
            modifiers: [.tag("smoke")],
            body: .sync {}
        )
        registry.add(
            id: .stub("untagged"),
            modifiers: [],
            body: .sync {}
        )
        let plan = registry.finalize()

        var tagFilter = Test.Trait.Tag.liveValue
        tagFilter.insert("smoke")
        let filtered = plan.filter(tags: tagFilter)
        #expect(filtered.count == 1)
    }

    @Test
    func `sorted orders entries by ID`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("c"), body: .sync {})
        registry.add(id: .stub("a"), body: .sync {})
        registry.add(id: .stub("b"), body: .sync {})
        let plan = registry.finalize()

        let sorted = plan.sorted()
        #expect(sorted.entries[0].id.name == "a")
        #expect(sorted.entries[1].id.name == "b")
        #expect(sorted.entries[2].id.name == "c")
    }
}

// MARK: - EdgeCase

extension Test_Primitives.Test.Plan.Test.EdgeCase {
    @Test
    func `filter returns empty when nothing matches`() {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("test", module: "A"), body: .sync {})
        let plan = registry.finalize()

        let filtered = plan.filter(module: "NonExistent")
        #expect(filtered.isEmpty)
        #expect(filtered.count == 0)
    }
}
