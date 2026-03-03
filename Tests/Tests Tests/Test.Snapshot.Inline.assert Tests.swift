import Testing
import Tests_Test_Support
import Dependency_Primitives

@Suite("Test.Snapshot.Inline.assert")
struct TestSnapshotInlineAssertTests {
    @Suite struct Unit {}
}

// MARK: - Unit

extension TestSnapshotInlineAssertTests.Unit {

    @Test
    func `assertInlineSnapshot registers passing expectation with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Dependency.Scope.with({ $0[Test_Primitives.Test.Expectation.Collector.Key.self] = collector }) {
            assertInlineSnapshot(of: "hello", as: .lines, record: .never, matches: { "hello" })
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isPassing)
        }
    }

    @Test
    func `assertInlineSnapshot registers failing expectation with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Dependency.Scope.with({ $0[Test_Primitives.Test.Expectation.Collector.Key.self] = collector }) {
            assertInlineSnapshot(of: "hello", as: .lines, record: .never, matches: { "world" })
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isFailing)
        }
    }

    @Test
    func `assertInlineSnapshot registers multiple expectations with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Dependency.Scope.with({ $0[Test_Primitives.Test.Expectation.Collector.Key.self] = collector }) {
            assertInlineSnapshot(of: "hello", as: .lines, record: .never, matches: { "hello" })
            assertInlineSnapshot(of: "hello", as: .lines, record: .never, matches: { "world" })
            assertInlineSnapshot(of: "foo", as: .lines, record: .never, matches: { "foo" })
        }
        let expectations = collector.drain()
        #expect(expectations.count == 3)
        if expectations.count == 3 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
            #expect(expectations[2].isPassing)
        }
    }

    @Test
    func `async assertInlineSnapshot registers with collector`() async {
        let collector = Test_Primitives.Test.Expectation.Collector()
        await Dependency.Scope.with({ $0[Test_Primitives.Test.Expectation.Collector.Key.self] = collector }) {
            await assertInlineSnapshot(of: "hello", as: .lines, record: .never, matches: { "hello" })
            await assertInlineSnapshot(of: "hello", as: .lines, record: .never, matches: { "world" })
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
        }
    }
}
