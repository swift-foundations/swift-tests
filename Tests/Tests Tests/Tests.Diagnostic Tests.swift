import Testing
import Tests_Test_Support

@Suite
struct TestsDiagnosticTests {

    @Suite struct Format {}
}

// MARK: - Format

extension TestsDiagnosticTests.Format {

    private static func makeDiagnostic(
        exceeded: Bool = true
    ) -> Tests.Diagnostic {
        let durations: [Duration] = (0..<10).map { .seconds(10 + $0) }
        let measurement = Tests.Measurement(durations: durations)
        let environment = Test.Environment.capture()

        return Tests.Diagnostic(
            testName: "example test",
            metric: .median,
            measurement: measurement,
            environment: environment,
            coefficientOfVariation: measurement.batch.coefficientOfVariation,
            medianAbsoluteDeviation: measurement.batch.medianAbsoluteDeviation,
            outlierCount: measurement.batch.outlierCount(),
            trend: Tests.Trend.mannKendall(durations),
            threshold: exceeded ? .seconds(5) : nil,
            exceedanceFactor: exceeded ? 3.0 : nil,
            allocations: nil
        )
    }

    @Test
    func formattedContainsTestName() {
        let diag = Self.makeDiagnostic()
        #expect(diag.formatted().contains("example test"))
    }

    @Test
    func formattedContainsCV() {
        let diag = Self.makeDiagnostic()
        #expect(diag.formatted().contains("CV:"))
    }

    @Test
    func formattedContainsEnvironment() {
        let diag = Self.makeDiagnostic()
        let output = diag.formatted()
        #expect(output.contains("Architecture:"))
        #expect(output.contains("CPU Cores:"))
        #expect(output.contains("Optimization:"))
    }

    @Test
    func formattedContainsTrend() {
        let diag = Self.makeDiagnostic()
        #expect(diag.formatted().contains("Mann-Kendall Z:"))
    }

    @Test
    func formattedContainsFactor() {
        let diag = Self.makeDiagnostic(exceeded: true)
        #expect(diag.formatted().contains("Factor:"))
    }

    @Test
    func jsonBlockHasDelimiters() {
        let diag = Self.makeDiagnostic()
        let json = diag.jsonBlock()
        #expect(json.contains("<!-- PERFORMANCE_DIAGNOSTIC_BEGIN -->"))
        #expect(json.contains("<!-- PERFORMANCE_DIAGNOSTIC_END -->"))
    }

    @Test
    func jsonBlockContainsEnvironment() {
        let diag = Self.makeDiagnostic()
        let json = diag.jsonBlock()
        #expect(json.contains("\"arch\":"))
        #expect(json.contains("\"feature_flags\":"))
    }

    @Test
    func noThresholdShowsPass() {
        let diag = Self.makeDiagnostic(exceeded: false)
        #expect(diag.formatted().contains("PERFORMANCE MEASUREMENT"))
        #expect(!diag.formatted().contains("Factor:"))
    }
}
