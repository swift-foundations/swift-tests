import Testing
import Tests_Inline_Snapshot
import Tests_Test_Support

extension Test_Primitives.Test.Snapshot.Inline {
    @Suite("snapshot (inline)")
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Test_Primitives.Test.Snapshot.Inline.Test.Unit {

    @Test
    func `snapshot registers passing expectation with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            snapshot(as: .lines, record: .never, { "hello" }, matches: { "hello" })
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isPassing)
        }
    }

    @Test
    func `snapshot registers failing expectation with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            snapshot(as: .lines, record: .never, { "hello" }, matches: { "world" })
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isFailing)
        }
    }

    @Test
    func `snapshot registers multiple expectations with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            snapshot(as: .lines, record: .never, { "hello" }, matches: { "hello" })
            snapshot(as: .lines, record: .never, { "hello" }, matches: { "world" })
            snapshot(as: .lines, record: .never, { "foo" }, matches: { "foo" })
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
    func `async snapshot registers with collector`() async {
        let collector = Test_Primitives.Test.Expectation.Collector()
        await Test_Primitives.Test.Expectation.Collector.with(collector) {
            await snapshot(as: .lines, record: .never, { "hello" }, matches: { "hello" })
            await snapshot(as: .lines, record: .never, { "hello" }, matches: { "world" })
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
        }
    }
}
