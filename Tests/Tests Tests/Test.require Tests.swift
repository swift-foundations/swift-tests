import Testing
import Tests_Test_Support

@Suite("Test.require")
struct TestRequireTests {
    @Suite struct Runner {}
    @Suite struct Unit {}
}

// MARK: - Runner

extension TestRequireTests.Runner {

    @Test
    func `failing require causes test failure`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("failingRequire")) {
            try require(false)
        }
        let plan = registry.finalize()

        let (reporter, _) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        let result = await runner.run(plan)

        #expect(result.hasFailures)
        #expect(result.failed == 1)
    }

    @Test
    func `failing require emits expectationChecked event`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("requireEvent")) {
            try require(false)
        }
        let plan = registry.finalize()

        let (reporter, spy) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        _ = await runner.run(plan)

        let expectationEvents = spy.events.filter {
            $0.kind == .expectationChecked
        }
        #expect(!expectationEvents.isEmpty,
            ".expectationChecked should be emitted for require()")
    }

    @Test
    func `failing require emits issueRecorded with expectationFailed`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("requireIssue")) {
            try require(false)
        }
        let plan = registry.finalize()

        let (reporter, spy) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        _ = await runner.run(plan)

        let expectationFailedIssues = spy.events.filter {
            guard $0.kind == .issueRecorded, let issue = $0.issue else { return false }
            if case .expectationFailed = issue.kind { return true }
            return false
        }
        #expect(!expectationFailedIssues.isEmpty,
            ".issueRecorded(.expectationFailed) should be emitted, not .errorCaught")
    }

    @Test
    func `failing require does not emit redundant errorCaught`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("noRedundant")) {
            try require(false)
        }
        let plan = registry.finalize()

        let (reporter, spy) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        _ = await runner.run(plan)

        let errorCaughtIssues = spy.events.filter {
            guard $0.kind == .issueRecorded, let issue = $0.issue else { return false }
            if case .errorCaught = issue.kind { return true }
            return false
        }
        #expect(errorCaughtIssues.isEmpty,
            "require() should not produce .errorCaught — the expectation covers it")
    }

    @Test
    func `independent throw still emits errorCaught`() async {
        struct TestError: Swift.Error {}

        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("independentThrow")) {
            throw TestError()
        }
        let plan = registry.finalize()

        let (reporter, spy) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        _ = await runner.run(plan)

        let errorCaughtIssues = spy.events.filter {
            guard $0.kind == .issueRecorded, let issue = $0.issue else { return false }
            if case .errorCaught = issue.kind { return true }
            return false
        }
        #expect(!errorCaughtIssues.isEmpty,
            "Independent throws should still produce .errorCaught")
    }

    @Test
    func `passing require records passing expectation`() async {
        var registry = Test_Primitives.Test.Plan.Registry()
        registry.add(id: .stub("passingRequire")) {
            try require(true)
        }
        let plan = registry.finalize()

        let (reporter, spy) = SpyReporter.make()
        let runner = Test_Primitives.Test.Runner(reporter: reporter)
        let result = await runner.run(plan)

        #expect(result.allPassed)

        let expectationEvents = spy.events.filter {
            $0.kind == .expectationChecked && ($0.expectation?.isPassing ?? false)
        }
        #expect(!expectationEvents.isEmpty,
            "Passing require should emit .expectationChecked")
    }
}

// MARK: - Unit

extension TestRequireTests.Unit {

    @Test
    func `require registers with collector when present`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            try? require(true)
            try? require(false)
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
        }
    }

    @Test
    func `require unwrap registers with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            _ = try? require(Optional(42))
            _ = try? require(nil as Int?)
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
        }
    }

    @Test
    func `require equality registers with collector`() {
        let collector = Test_Primitives.Test.Expectation.Collector()
        Test_Primitives.Test.Expectation.Collector.with(collector) {
            try? require(1, equals: 1)
            try? require(1, equals: 2)
        }
        let expectations = collector.drain()
        #expect(expectations.count == 2)
        if expectations.count == 2 {
            #expect(expectations[0].isPassing)
            #expect(expectations[1].isFailing)
        }
    }
}
