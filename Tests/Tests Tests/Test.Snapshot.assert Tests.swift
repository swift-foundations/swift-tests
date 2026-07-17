import Testing
import Tests_Inline_Snapshot
import Tests_Test_Support

extension Test_Primitives.Test.Snapshot {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Test_Primitives.Test.Snapshot.Test.Unit {

    @Test
    func `snapshot registers passing expectation with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            // .missing mode: no reference exists → records to /tmp/ → passes
            snapshot(
                as: .lines,
                named: "passing",
                record: .missing,
                { "hello" },
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
    func `snapshot registers failing expectation with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            // .never mode: no reference exists → missingReference → fails
            snapshot(
                as: .lines,
                named: "failing",
                record: .never,
                { "hello" },
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
    func `snapshot registers multiple expectations with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            // Passes (records new snapshot in /tmp/)
            snapshot(
                as: .lines,
                named: "multi-pass",
                record: .missing,
                { "hello" },
                filePath: "/tmp/swift-tests-unit/SnapshotMultipleTest.swift",
                function: "multipleTest()"
            )
            // Fails (no reference with .never mode)
            snapshot(
                as: .lines,
                named: "multi-fail",
                record: .never,
                { "world" },
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
