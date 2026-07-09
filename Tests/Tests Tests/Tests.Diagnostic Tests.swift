import Testing
import Tests_Test_Support

extension Tests.Diagnostic {
    @Suite
    struct Test {
        @Suite struct Format {}
    }
}

// MARK: - Format

extension Tests.Diagnostic.Test.Format {

    private static func makeDiagnostic(
        exceeded: Bool = true
    ) -> Tests.Diagnostic {
        let durations: [Duration] = (0..<10).map { .seconds(10 + $0) }
        let measurement = Test.Benchmark.Measurement(durations: durations)
        let environment = Test.Environment.capture()

        return Tests.Diagnostic(
            testName: "example test",
            qualifiedName: "TestModule.ExampleSuite.example test",
            metric: .median,
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: measurement.coefficientOfVariation,
            medianAbsoluteDeviation: measurement.medianAbsoluteDeviation,
            outlierCount: measurement.outlierCount(),
            trend: Test.Benchmark.Trend.mannKendall(durations),
            threshold: exceeded ? .seconds(5) : nil,
            exceedanceFactor: exceeded ? 3.0 : nil,
            allocations: nil
        )
    }

    @Test
    func `formatted Contains Test Name`() {
        let diag = Self.makeDiagnostic()
        #expect(diag.formatted().contains("example test"))
    }

    @Test
    func `formatted Contains CV`() {
        let diag = Self.makeDiagnostic()
        #expect(diag.formatted().contains("CV:"))
    }

    @Test
    func `formatted Contains Environment`() {
        let diag = Self.makeDiagnostic()
        let output = diag.formatted()
        #expect(output.contains("Architecture:"))
        #expect(output.contains("CPU Cores:"))
        #expect(output.contains("Optimization:"))
    }

    @Test
    func `formatted Contains Trend`() {
        let diag = Self.makeDiagnostic()
        #expect(diag.formatted().contains("Mann-Kendall Z:"))
    }

    @Test
    func `formatted Contains Factor`() {
        let diag = Self.makeDiagnostic(exceeded: true)
        #expect(diag.formatted().contains("Factor:"))
    }

    @Test
    func `json Block Has Delimiters`() {
        let diag = Self.makeDiagnostic()
        let json = diag.jsonBlock()
        #expect(json.contains("<!-- PERFORMANCE_DIAGNOSTIC_BEGIN -->"))
        #expect(json.contains("<!-- PERFORMANCE_DIAGNOSTIC_END -->"))
    }

    @Test
    func `json Block Contains Environment`() {
        let diag = Self.makeDiagnostic()
        let json = diag.jsonBlock()
        #expect(json.contains("\"arch\":"))
        #expect(json.contains("\"feature_flags\":"))
    }

    @Test
    func `no Threshold Shows Pass`() {
        let diag = Self.makeDiagnostic(exceeded: false)
        #expect(diag.formatted().contains("PERFORMANCE MEASUREMENT"))
        #expect(!diag.formatted().contains("Factor:"))
    }
}
