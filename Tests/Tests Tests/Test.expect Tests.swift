import Testing
import Tests_Test_Support

@Suite("Test.expect")
struct TestExpectTests {
    @Suite struct Unit {}
}

// MARK: - Unit

extension TestExpectTests.Unit {

    @Test
    func `expect registers with collector when present`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            expect(true)
            expect(false)
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
        }
    }

    @Test
    func `expect equality registers with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            expect(1, equals: 1)
            expect(1, equals: 2)
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
        }
    }

    @Test
    func `expect works without collector`() {
        let result = expect(true)
        #expect(result.isPassing)
    }
}
