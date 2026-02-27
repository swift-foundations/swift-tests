import Testing
import Tests

extension Tests.Error {
    @Suite
    struct Test {
        @Suite struct Unit {}
    }
}

// MARK: - Unit

extension Tests.Error.Test.Unit {
    @Test
    func `thresholdExceeded description contains test name`() {
        let error = Tests.Error.thresholdExceeded(
            test: "myTest",
            metric: .median,
            expected: .milliseconds(10),
            actual: .milliseconds(20)
        )
        #expect(error.description.contains("myTest"))
    }

    @Test
    func `allocationLimitExceeded description contains limit`() {
        let error = Tests.Error.allocationLimitExceeded(
            test: "myTest", limit: 1024, actual: 2048
        )
        #expect(error.description.contains("myTest"))
    }

    @Test
    func `memoryLeakDetected description contains net allocations`() {
        let error = Tests.Error.memoryLeakDetected(
            test: "myTest", netAllocations: 5, netBytes: 512
        )
        #expect(error.description.contains("5"))
    }

    @Test
    func `peakMemoryExceeded description contains limit`() {
        let error = Tests.Error.peakMemoryExceeded(
            test: "myTest", limit: 1024, actual: 2048
        )
        #expect(error.description.contains("myTest"))
    }

    @Test
    func `performanceExpectationFailed description contains metric`() {
        let error = Tests.Error.performanceExpectationFailed(
            metric: .p95,
            threshold: .milliseconds(10),
            actual: .milliseconds(20)
        )
        #expect(error.description.contains("p95"))
    }

    @Test
    func `regressionDetected description contains tolerance`() {
        let error = Tests.Error.regressionDetected(
            metric: .median,
            baseline: .milliseconds(10),
            current: .milliseconds(15),
            regression: 0.5,
            tolerance: 0.1
        )
        #expect(error.description.contains("Tolerance"))
    }
}
