//
//  Tests.Complexity.Diagnostic Tests.swift
//  swift-tests
//
//  Tests for complexity diagnostic formatting and construction.
//

import Testing
import Tests_Test_Support

private typealias SUT = Test_Primitives.Test

@Suite
struct ComplexityDiagnosticTests {

    @Suite struct Formatted {}
    @Suite struct JSON {}
}

// MARK: - Helpers

extension ComplexityDiagnosticTests {
    static let defaultSizes = [
        100, 300, 1_000, 3_000, 10_000,
        30_000, 100_000, 300_000, 1_000_000, 3_000_000,
    ]

    fileprivate static func linearDiagnostic() -> Tests.Complexity.Diagnostic {
        let points: [(size: Int, metric: Duration)] = defaultSizes.map { n in
            (size: n, metric: Duration.seconds(1e-8 * Double(n)))
        }
        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .linearithmic, .quadratic, .cubic]
        )
        let result = Tests.Complexity.classify(evidence)

        return Tests.Complexity.Diagnostic(
            result: result,
            points: points,
            metric: .median,
            policy: .default
        )
    }

    fileprivate static func inconclusiveDiagnostic() -> Tests.Complexity.Diagnostic {
        let points: [(size: Int, metric: Duration)] = [
            (size: 100, metric: .milliseconds(1)),
            (size: 200, metric: .milliseconds(1)),
        ]
        let evidence = SUT.Benchmark.Complexity.evidence(
            from: points,
            classes: [.constant, .logarithmic, .linear, .quadratic]
        )
        let result = Tests.Complexity.classify(evidence)

        return Tests.Complexity.Diagnostic(
            result: result,
            points: points,
            metric: .median,
            policy: .default
        )
    }
}

// MARK: - Formatted Output

extension ComplexityDiagnosticTests.Formatted {

    @Test
    func `linear diagnostic contains expected sections`() {
        let diagnostic = ComplexityDiagnosticTests.linearDiagnostic()
        let output = diagnostic.formatted()

        #expect(output.contains("COMPLEXITY ANALYSIS"))
        #expect(output.contains("Continuous Exponent"))
        #expect(output.contains("Best Candidate"))
        #expect(output.contains("Confidence"))
        #expect(output.contains("Measurements"))
        #expect(output.contains("Top Candidates"))
    }

    @Test
    func `inconclusive diagnostic shows inconclusive header`() {
        let diagnostic = ComplexityDiagnosticTests.inconclusiveDiagnostic()
        let output = diagnostic.formatted()

        #expect(output.contains("INCONCLUSIVE"))
        #expect(output.contains("Continuous Exponent"))
        #expect(output.contains("Measurements"))
    }

    @Test
    func `baseline comparison appears in formatted output`() {
        var diagnostic = ComplexityDiagnosticTests.linearDiagnostic()
        diagnostic.baselineComparison = Tests.Complexity.Baseline.Comparison(
            previous: Tests.Complexity.Baseline(
                bestClass: .quadratic,
                exponent: 2.0,
                confidence: .high,
                bestRSquared: 0.99
            ),
            current: Tests.Complexity.Baseline(
                bestClass: .linear,
                exponent: 1.0,
                confidence: .high,
                bestRSquared: 0.99
            )
        )
        let output = diagnostic.formatted()

        #expect(output.contains("Baseline Comparison"))
        #expect(output.contains("Previous"))
        #expect(output.contains("Current"))
        #expect(output.contains("IMPROVED"))
    }

    @Test
    func `regression baseline shows regression label`() {
        var diagnostic = ComplexityDiagnosticTests.linearDiagnostic()
        diagnostic.baselineComparison = Tests.Complexity.Baseline.Comparison(
            previous: Tests.Complexity.Baseline(
                bestClass: .linear,
                exponent: 1.0,
                confidence: .high,
                bestRSquared: 0.99
            ),
            current: Tests.Complexity.Baseline(
                bestClass: .quadratic,
                exponent: 2.0,
                confidence: .high,
                bestRSquared: 0.99
            )
        )
        let output = diagnostic.formatted()

        #expect(output.contains("REGRESSION"))
    }

    @Test
    func `reasons section appears when reasons exist`() {
        let diagnostic = ComplexityDiagnosticTests.inconclusiveDiagnostic()
        let output = diagnostic.formatted()

        #expect(output.contains("Reasons"))
    }
}

// MARK: - JSON Output

extension ComplexityDiagnosticTests.JSON {

    @Test
    func `JSON block contains delimiters`() {
        let diagnostic = ComplexityDiagnosticTests.linearDiagnostic()
        let json = diagnostic.jsonBlock()

        #expect(json.contains("<!-- COMPLEXITY_DIAGNOSTIC_BEGIN -->"))
        #expect(json.contains("<!-- COMPLEXITY_DIAGNOSTIC_END -->"))
    }

    @Test
    func `JSON block contains required fields`() {
        let diagnostic = ComplexityDiagnosticTests.linearDiagnostic()
        let json = diagnostic.jsonBlock()

        #expect(json.contains("\"exponent\""))
        #expect(json.contains("\"best\""))
        #expect(json.contains("\"confidence\""))
        #expect(json.contains("\"candidates\""))
        #expect(json.contains("\"points\""))
        #expect(json.contains("\"growth_ratios\""))
    }

    @Test
    func `JSON block includes baseline when present`() {
        var diagnostic = ComplexityDiagnosticTests.linearDiagnostic()
        diagnostic.baselineComparison = Tests.Complexity.Baseline.Comparison(
            previous: Tests.Complexity.Baseline(
                bestClass: .linear,
                exponent: 1.0,
                confidence: .high,
                bestRSquared: 0.99
            ),
            current: Tests.Complexity.Baseline(
                bestClass: .quadratic,
                exponent: 2.0,
                confidence: .high,
                bestRSquared: 0.99
            )
        )
        let json = diagnostic.jsonBlock()

        #expect(json.contains("\"baseline\""))
        #expect(json.contains("\"previous_class\""))
        #expect(json.contains("\"class_regressed\": true"))
    }

    @Test
    func `JSON block has null baseline when absent`() {
        let diagnostic = ComplexityDiagnosticTests.linearDiagnostic()
        let json = diagnostic.jsonBlock()

        #expect(json.contains("\"baseline\": null"))
    }
}
