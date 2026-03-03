import Testing
import Tests_Test_Support

@Suite("Test.Snapshot.assert")
struct TestSnapshotAssertTests {
    @Suite struct Unit {}
}

// MARK: - Unit

extension TestSnapshotAssertTests.Unit {

    @Test
    func `assertSnapshot registers passing expectation with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.$current.withValue(collector) {
            // .missing mode: no reference exists → records to /tmp/ → passes
            assertSnapshot(
                capturing: "hello",
                as: .lines,
                record: .missing,
                filePath: "/tmp/swift-tests-unit/SnapshotPassingTest.swift",
                function: "passingTest()"
            )
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isPassing)
        }
    }

    @Test
    func `assertSnapshot registers failing expectation with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.$current.withValue(collector) {
            // .never mode: no reference exists → missingReference → fails
            assertSnapshot(
                capturing: "hello",
                as: .lines,
                record: .never,
                filePath: "/tmp/nonexistent-path/SnapshotFailingTest.swift",
                function: "failingTest()"
            )
        }
        let expectations = collector.drain()
        #expect(expectations.count == 1)
        if expectations.count == 1 {
            #expect(expectations[0].isFailing)
        }
    }

    @Test
    func `assertSnapshot registers multiple expectations with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.$current.withValue(collector) {
            // Passes (records new snapshot in /tmp/)
            assertSnapshot(
                capturing: "hello",
                as: .lines,
                record: .missing,
                filePath: "/tmp/swift-tests-unit/SnapshotMultipleTest.swift",
                function: "multipleTest()"
            )
            // Fails (no reference with .never mode)
            assertSnapshot(
                capturing: "world",
                as: .lines,
                record: .never,
                filePath: "/tmp/nonexistent-path/SnapshotMultipleFail.swift",
                function: "multipleFail()"
            )
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
        }
    }
}
