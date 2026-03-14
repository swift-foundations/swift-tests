import Testing
import Tests_Test_Support

@Suite("Test.Runner")
struct TestRunnerTests {
    @Suite struct Expectations {}
    @Suite struct Events {}
}

// MARK: - Expectations

extension TestRunnerTests.Expectations {

    @Test
    func `failing expect causes test failure`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("failingExpect")) {
            expect(false)
        }
        let plan = registry.finalize()

        let (reporter, _) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        let result = await runner.run(plan)

        #expect(result.hasFailures, "expect(false) should cause test failure")
        #expect(result.failed == 1)
    }

    @Test
    func `passing expect keeps test passing`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("passingExpect")) {
            expect(true)
        }
        let plan = registry.finalize()

        let (reporter, _) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        let result = await runner.run(plan)

        #expect(result.allPassed)
        #expect(result.passed == 1)
    }

    @Test
    func `multiple failing expects all recorded`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("multipleFailures")) {
            expect(false, "first")
            expect(false, "second")
            expect(true)
        }
        let plan = registry.finalize()

        let (reporter, spy) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        let result = await runner.run(plan)

        #expect(result.hasFailures)

        let expectationEvents = spy.events.filter {
            $0.kind == .expectationChecked
        }
        #expect(expectationEvents.count == 3, "All 3 expectations should be reported")
    }

    @Test
    func `mix of passing and failing tests`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("pass")) { expect(true) }
        registry.add(id: .stub("fail")) { expect(false) }
        let plan = registry.finalize()

        let (reporter, _) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        let result = await runner.run(plan)

        #expect(result.passed == 1)
        #expect(result.failed == 1)
    }
}

// MARK: - Events

extension TestRunnerTests.Events {

    @Test
    func `expectationChecked events are emitted`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("eventsTest")) {
            expect(true)
        }
        let plan = registry.finalize()

        let (reporter, spy) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        _ = await runner.run(plan)

        let expectationEvents = spy.events.filter {
            $0.kind == .expectationChecked
        }
        #expect(!expectationEvents.isEmpty, ".expectationChecked events should be emitted")
    }

    @Test
    func `issueRecorded emitted for failing expectations`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("issueTest")) {
            expect(false)
        }
        let plan = registry.finalize()

        let (reporter, spy) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        _ = await runner.run(plan)

        let issueEvents = spy.events.filter {
            $0.kind == .issueRecorded
        }
        #expect(!issueEvents.isEmpty, ".issueRecorded should be emitted for failures")
    }
}
