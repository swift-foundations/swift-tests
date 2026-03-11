//
//  Tests.Complexity.Diagnostic+Format.swift
//  swift-tests
//
//  Human-readable and JSON formatting for complexity diagnostics.
//

import Console
import Formatting_Primitives

extension Tests.Complexity.Diagnostic {

    /// Human-readable formatted diagnostic for console output.
    public func formatted() -> Swift.String {
        let cap = Tests.consoleCapability
        let evidence = result.evidence
        var lines: [Swift.String] = []

        // Header
        let header: Swift.String
        if result.confidence == .inconclusive {
            header = Console.Style.warning.apply(
                to: "COMPLEXITY ANALYSIS — INCONCLUSIVE", capability: cap
            )
        } else if let best = result.best {
            header = Console.Style.success.apply(
                to: "COMPLEXITY ANALYSIS — \(best.complexity.rawValue.uppercased())",
                capability: cap
            )
        } else {
            header = Console.Style.warning.apply(
                to: "COMPLEXITY ANALYSIS — NO RESULT", capability: cap
            )
        }
        lines.append(header)

        // Exponent
        lines.append("")
        lines.append("  Continuous Exponent:")
        let k = evidence.exponent.value.formatted(.number.precision(3))
        let r2 = evidence.exponent.fit.rSquared.formatted(.number.precision(4))
        lines.append("    k = \(k)  (T ≈ c·nᵏ)")
        lines.append("    R² = \(r2)")

        // Best candidate
        if let best = result.best {
            lines.append("")
            lines.append("  Best Candidate:")
            let bestR2 = best.regression.rSquared.formatted(.number.precision(4))
            lines.append("    \(best.complexity.rawValue)  R² = \(bestR2)")

            // Confidence
            let confidenceLabel: Swift.String
            switch result.confidence {
            case .high:
                confidenceLabel = Console.Style.success.apply(
                    to: "HIGH", capability: cap
                )
            case .medium:
                confidenceLabel = Console.Style.warning.apply(
                    to: "MEDIUM", capability: cap
                )
            case .low:
                confidenceLabel = Console.Style.warning.apply(
                    to: "LOW", capability: cap
                )
            case .inconclusive:
                confidenceLabel = Console.Style.error.apply(
                    to: "INCONCLUSIVE", capability: cap
                )
            }
            lines.append("    Confidence: \(confidenceLabel)")

            // Ambiguous alternatives
            if !result.ambiguousWith.isEmpty {
                let alt = result.ambiguousWith.map(\.rawValue).joined(separator: ", ")
                lines.append("    Ambiguous with: \(alt)")
            }
        }

        // Reasons
        if !result.reasons.isEmpty {
            lines.append("")
            lines.append("  Reasons:")
            for reason in result.reasons {
                lines.append("    • \(reason)")
            }
        }

        // Size points
        lines.append("")
        lines.append("  Measurements:")
        for point in points {
            let size = Swift.String(point.size)
            let duration = point.metric.formatted()
            lines.append("    n=\(size)  →  \(duration)")
        }

        // Doubling ratios
        if !evidence.growthRatios.isEmpty {
            lines.append("")
            lines.append("  Growth Ratios:")
            let ratioStrs = evidence.growthRatios.map {
                $0.formatted(.number.precision(2))
            }
            lines.append("    [\(ratioStrs.joined(separator: ", "))]")
        }

        // Top candidates
        let topN = Swift.min(evidence.candidates.count, 3)
        if topN > 0 {
            lines.append("")
            lines.append("  Top Candidates:")
            for candidate in evidence.candidates.prefix(topN) {
                let cR2 = candidate.regression.rSquared.formatted(.number.precision(4))
                lines.append("    \(candidate.complexity.rawValue)  R² = \(cR2)")
            }
        }

        // Baseline comparison
        if let comparison = baselineComparison {
            lines.append("")
            lines.append("  Baseline Comparison:")
            let prevClass = comparison.previous.bestClass?.rawValue ?? "inconclusive"
            let currClass = comparison.current.bestClass?.rawValue ?? "inconclusive"
            lines.append("    Previous: \(prevClass) (k=\(comparison.previous.exponent.formatted(.number.precision(3))))")
            lines.append("    Current:  \(currClass) (k=\(comparison.current.exponent.formatted(.number.precision(3))))")

            if comparison.classRegressed {
                let label = Console.Style.error.apply(
                    to: "REGRESSION — class worsened from \(prevClass) to \(currClass)",
                    capability: cap
                )
                lines.append("    \(label)")
            } else if comparison.classImproved {
                let label = Console.Style.success.apply(
                    to: "IMPROVED — class improved from \(prevClass) to \(currClass)",
                    capability: cap
                )
                lines.append("    \(label)")
            } else if comparison.exponentDriftExceeds(0.3) {
                let drift = comparison.exponentDrift.formatted(.number.precision(3))
                let label = Console.Style.warning.apply(
                    to: "DRIFT — exponent shifted by \(drift)",
                    capability: cap
                )
                lines.append("    \(label)")
            } else {
                lines.append("    NO CHANGE")
            }
        }

        return lines.joined(separator: "\n")
    }

    /// Structured JSON block delimited for AI agent parsing.
    public func jsonBlock() -> Swift.String {
        let evidence = result.evidence
        var json: [Swift.String] = []
        json.append("<!-- COMPLEXITY_DIAGNOSTIC_BEGIN -->")
        json.append("{")

        // Exponent
        json.append("  \"exponent\": {")
        json.append("    \"k\": \(evidence.exponent.value.formatted(.number.precision(4))),")
        json.append("    \"r_squared\": \(evidence.exponent.fit.rSquared.formatted(.number.precision(4)))")
        json.append("  },")

        // Best
        if let best = result.best {
            json.append("  \"best\": {")
            json.append("    \"class\": \(_jsonString(best.complexity.rawValue)),")
            json.append("    \"r_squared\": \(best.regression.rSquared.formatted(.number.precision(4)))")
            json.append("  },")
        } else {
            json.append("  \"best\": null,")
        }

        // Confidence
        json.append("  \"confidence\": \(_jsonString("\(result.confidence)")),")

        // Ambiguous
        let ambStr = result.ambiguousWith.map { _jsonString($0.rawValue) }.joined(separator: ", ")
        json.append("  \"ambiguous_with\": [\(ambStr)],")

        // Reasons
        let reasonStr = result.reasons.map { _jsonString("\($0)") }.joined(separator: ", ")
        json.append("  \"reasons\": [\(reasonStr)],")

        // Candidates
        json.append("  \"candidates\": [")
        for (i, c) in evidence.candidates.enumerated() {
            let comma = i < evidence.candidates.count - 1 ? "," : ""
            json.append("    {\"class\": \(_jsonString(c.complexity.rawValue)), \"r_squared\": \(c.regression.rSquared.formatted(.number.precision(4)))}\(comma)")
        }
        json.append("  ],")

        // Points
        json.append("  \"points\": [")
        for (i, p) in points.enumerated() {
            let comma = i < points.count - 1 ? "," : ""
            json.append("    {\"size\": \(p.size), \"seconds\": \(p.metric.inSeconds.formatted(.number.precision(6)))}\(comma)")
        }
        json.append("  ],")

        // Doubling ratios
        let ratioStr = evidence.growthRatios.map { $0.formatted(.number.precision(3)) }.joined(separator: ", ")
        json.append("  \"growth_ratios\": [\(ratioStr)],")

        // Baseline
        if let comparison = baselineComparison {
            json.append("  \"baseline\": {")
            if let prevClass = comparison.previous.bestClass {
                json.append("    \"previous_class\": \(_jsonString(prevClass.rawValue)),")
            } else {
                json.append("    \"previous_class\": null,")
            }
            json.append("    \"previous_exponent\": \(comparison.previous.exponent.formatted(.number.precision(4))),")
            json.append("    \"exponent_drift\": \(comparison.exponentDrift.formatted(.number.precision(4))),")
            json.append("    \"class_regressed\": \(comparison.classRegressed),")
            json.append("    \"is_regression\": \(comparison.isRegression)")
            json.append("  }")
        } else {
            json.append("  \"baseline\": null")
        }

        json.append("}")
        json.append("<!-- COMPLEXITY_DIAGNOSTIC_END -->")

        return json.joined(separator: "\n")
    }

    private func _jsonString(_ s: Swift.String) -> Swift.String {
        var result = "\""
        for c in s {
            switch c {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            default: result.append(c)
            }
        }
        result += "\""
        return result
    }
}
