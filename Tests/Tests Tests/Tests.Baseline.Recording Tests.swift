import Testing
import Tests_Test_Support

extension Tests.Baseline.Recording {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Tests.Baseline.Recording.Test.Unit {
    @Test
    func `raw values match expected strings`() {
        #expect(Tests.Baseline.Recording.normal.rawValue == "normal")
        #expect(Tests.Baseline.Recording.all.rawValue == "all")
        #expect(Tests.Baseline.Recording.never.rawValue == "never")
    }

    @Test
    func `fromEnvironment defaults to normal`() {
        // Assumes SWIFT_BENCHMARK_RECORD is not set in the test process.
        let mode = Tests.Baseline.Recording.fromEnvironment()
        #expect(mode == .normal)
    }
}
