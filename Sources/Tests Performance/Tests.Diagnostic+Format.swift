import Cardinal_Primitives
import Console
import Format_Primitives
import Tagged_Primitives

extension Tests.Diagnostic {

    /// Human-readable formatted diagnostic for console output.
    public func formatted() -> Swift.String {
        let m = measurement
        let cap = Tests.consoleCapability

        var lines: [Swift.String] = []

        // Header
        if let factor = exceedanceFactor {
            let header = Console.Style.error.apply(
                to: "PERFORMANCE THRESHOLD EXCEEDED",
                capability: cap
            )
            lines.append(header)
            lines.append("  Test:     \(qualifiedName)")
            lines.append("  Metric:   \(metric)")
            lines.append("  Expected: < \(threshold!.formatted())")
            lines.append("  Actual:   \(metric.extract(from: m).formatted())")
            let factorStr = "\(factor.formatted(.number.precision(2)))x threshold"
            lines.append("  Factor:   \(Console.Style.error.apply(to: factorStr, capability: cap))")
        } else {
            let header = Console.Style.success.apply(
                to: "PERFORMANCE MEASUREMENT",
                capability: cap
            )
            lines.append(header)
            lines.append("  Test:     \(qualifiedName)")
            lines.append("  Metric:   \(metric)")
            lines.append("  Value:    \(metric.extract(from: m).formatted())")
        }

        // Distribution
        lines.append("")
        lines.append("  Distribution:")
        lines.append("    Median: \(m.median.formatted())  Mean: \(m.mean.formatted())  StdDev: \(m.standardDeviation.formatted())")

        if let cv = coefficientOfVariation {
            let cvStr = "\(cv.formatted(.number.precision(2)))%"
            let label: Swift.String
            if cv <= 5.0 {
                label = Console.Style.success.apply(to: "STABLE - result is trustworthy", capability: cap)
            } else if cv <= 10.0 {
                label = Console.Style.warning.apply(to: "MODERATE - consider more iterations", capability: cap)
            } else {
                label = Console.Style.error.apply(to: "NOISY - result may be unreliable", capability: cap)
            }
            lines.append("    CV:     \(cvStr) (\(label))")
        }

        lines.append("    Min:    \(m.min.formatted())  Max: \(m.max.formatted())")
        lines.append("    p95:    \(m.p95.formatted())  p99: \(m.p99.formatted())")

        if let mad = medianAbsoluteDeviation {
            let outlierStr = outlierCount.map { "\($0) of \(m.durations.count)" } ?? "?"
            lines.append("    MAD:    \(mad.formatted())   Outliers: \(outlierStr)")
        }

        // Trend
        lines.append("")
        lines.append("  Trend:")
        let zStr = trend.z.formatted(.number.precision(2))
        let trendLabel: Swift.String
        if trend.interpretation == .increasing {
            trendLabel = Console.Style.error.apply(
                to: "INCREASING - possible thermal throttle",
                capability: cap
            )
        } else if trend.interpretation == .decreasing {
            trendLabel = Console.Style.warning.apply(
                to: "DECREASING - possible caching/warmup effect",
                capability: cap
            )
        } else {
            trendLabel = "NO TREND - not thermal throttle"
        }
        lines.append("    Mann-Kendall Z: \(zStr) (\(trendLabel))")

        // Baseline comparison
        if let comparison {
            lines.append("")
            lines.append("  Baseline Comparison:")
            lines.append("    Baseline: \(comparison.baselineValue.formatted())")
            lines.append("    Current:  \(comparison.currentValue.formatted())")
            let changePercent = (comparison.change * 100.0).formatted(.number.precision(2))
            if comparison.isRegression {
                let label = Console.Style.error.apply(
                    to: "REGRESSION +\(changePercent)%",
                    capability: cap
                )
                lines.append("    Change:   \(label)")
            } else if comparison.isImprovement {
                let label = Console.Style.success.apply(
                    to: "IMPROVEMENT \(changePercent)%",
                    capability: cap
                )
                lines.append("    Change:   \(label)")
            } else {
                lines.append("    Change:   NO CHANGE")
            }
        } else if baseline == nil, comparison == nil {
            // No baseline section needed
        }

        // History (cross-run trend)
        if let history = historyAnalysis {
            lines.append("")
            lines.append("  History (\(history.recordCount) runs):")
            let historyZStr = history.trend.z.formatted(.number.precision(2))
            let historyTrendLabel: Swift.String
            if history.trend.interpretation == .increasing {
                historyTrendLabel = Console.Style.error.apply(
                    to: "DEGRADING over time",
                    capability: cap
                )
            } else if history.trend.interpretation == .decreasing {
                historyTrendLabel = Console.Style.success.apply(
                    to: "IMPROVING over time",
                    capability: cap
                )
            } else {
                historyTrendLabel = "STABLE across runs"
            }
            lines.append("    Cross-run Z:  \(historyZStr) (\(historyTrendLabel))")
            lines.append("    Earliest:     \(history.earliestValue.formatted())")
            lines.append("    Latest:       \(history.latestValue.formatted())")
            let changePercent = (history.overallChange * 100.0).formatted(.number.precision(2))
            lines.append("    Overall:      \(changePercent)%")
        }

        // Environment
        lines.append("")
        lines.append("  Environment:")
        lines.append("    Architecture:  \(environment.architecture)")
        lines.append("    CPU Cores:     \(environment.physicalCPUCount) (physical) / \(environment.logicalCPUCount) (logical)")
        let memGB = Double(environment.memoryBytes.underlying.rawValue) / (1024.0 * 1024.0 * 1024.0)
        lines.append("    Memory:        \(Int(memGB.rounded())) GB")
        lines.append("    Swift:         \(environment.swiftVersion)")
        lines.append("    Optimization:  \(environment.optimization.rawValue)")

        var flagParts: [Swift.String] = []
        if environment.features.nonisolatedNonsendingByDefault {
            flagParts.append("NonisolatedNonsendingByDefault=true")
        }
        if environment.features.strictMemorySafety {
            flagParts.append("StrictMemorySafety=true")
        }
        if flagParts.isEmpty {
            flagParts.append("none")
        }
        lines.append("    Feature Flags: \(flagParts.joined(separator: ", "))")
        lines.append("    OS:            \(environment.osVersion)")

        return lines.joined(separator: "\n")
    }

    /// Structured JSON block delimited for AI agent parsing.
    ///
    /// Emits JSON between `<!-- PERFORMANCE_DIAGNOSTIC_BEGIN -->` and
    /// `<!-- PERFORMANCE_DIAGNOSTIC_END -->` markers. AI agents can extract
    /// this block via simple string search without regex.
    public func jsonBlock() -> Swift.String {
        let m = measurement
        let metricValue = metric.extract(from: m)

        var json: [Swift.String] = []
        json.append("<!-- PERFORMANCE_DIAGNOSTIC_BEGIN -->")
        json.append("{")
        json.append("  \"test\": \(_jsonString(testName)),")
        if let suiteName {
            json.append("  \"suite\": \(_jsonString(suiteName)),")
        }
        json.append("  \"qualified_name\": \(_jsonString(qualifiedName)),")
        json.append("  \"status\": \(exceedanceFactor != nil ? "\"THRESHOLD_EXCEEDED\"" : "\"PASS\""),")
        json.append("  \"metric\": \(_jsonString("\(metric)")),")

        if let t = threshold {
            json.append("  \"threshold\": \(t.inSeconds),")
        }
        json.append("  \"actual\": \(metricValue.inSeconds),")

        if let factor = exceedanceFactor {
            json.append("  \"factor\": \(factor.formatted(.number.precision(2))),")
        }

        // Distribution
        json.append("  \"distribution\": {")
        json.append("    \"count\": \(m.durations.count),")
        json.append("    \"min\": \(m.min.inSeconds),")
        json.append("    \"median\": \(m.median.inSeconds),")
        json.append("    \"mean\": \(m.mean.inSeconds),")
        json.append("    \"max\": \(m.max.inSeconds),")
        json.append("    \"stddev\": \(m.standardDeviation.inSeconds),")
        if let cv = coefficientOfVariation {
            json.append("    \"cv\": \(cv.formatted(.number.precision(2))),")
        }
        if let mad = medianAbsoluteDeviation {
            json.append("    \"mad\": \(mad.inSeconds),")
        }
        json.append("    \"p95\": \(m.p95.inSeconds),")
        json.append("    \"p99\": \(m.p99.inSeconds),")
        if let outliers = outlierCount {
            json.append("    \"outliers\": \(outliers)")
        } else {
            json.append("    \"outliers\": null")
        }
        json.append("  },")

        // Trend
        json.append("  \"trend\": {")
        json.append("    \"mann_kendall_z\": \(trend.z.formatted(.number.precision(2))),")
        json.append("    \"interpretation\": \(_jsonString(trend.interpretation.rawValue))")
        json.append("  },")

        // Environment
        json.append("  \"environment\": {")
        json.append("    \"arch\": \(_jsonString(environment.architecture)),")
        json.append("    \"physical_cores\": \(environment.physicalCPUCount),")
        json.append("    \"logical_cores\": \(environment.logicalCPUCount),")
        json.append("    \"memory_bytes\": \(environment.memoryBytes),")
        json.append("    \"swift_version\": \(_jsonString(environment.swiftVersion)),")
        json.append("    \"optimization\": \(_jsonString(environment.optimization.rawValue)),")
        json.append("    \"feature_flags\": {")
        json.append("      \"NonisolatedNonsendingByDefault\": \(environment.features.nonisolatedNonsendingByDefault),")
        json.append("      \"StrictMemorySafety\": \(environment.features.strictMemorySafety)")
        json.append("    },")
        json.append("    \"os\": \(_jsonString(environment.osVersion))")
        json.append("  },")

        // Baseline
        if let comparison {
            json.append("  \"baseline\": {")
            json.append("    \"value\": \(comparison.baselineValue.inSeconds),")
            json.append("    \"change\": \(comparison.change.formatted(.number.precision(4))),")
            json.append("    \"is_regression\": \(comparison.isRegression)")
            json.append("  },")
        }

        // History
        if let history = historyAnalysis {
            json.append("  \"history\": {")
            json.append("    \"record_count\": \(history.recordCount),")
            json.append("    \"mann_kendall_z\": \(history.trend.z.formatted(.number.precision(2))),")
            json.append("    \"interpretation\": \(_jsonString(history.trend.interpretation.rawValue)),")
            json.append("    \"earliest_s\": \(history.earliestValue.inSeconds),")
            json.append("    \"latest_s\": \(history.latestValue.inSeconds),")
            json.append("    \"overall_change\": \(history.overallChange.formatted(.number.precision(4)))")
            json.append("  },")
        }

        // Raw durations
        let durationsStr = m.durations.map { "\($0.inSeconds.formatted(.number.precision(6)))" }.joined(separator: ", ")
        json.append("  \"durations_seconds\": [\(durationsStr)]")

        json.append("}")
        json.append("<!-- PERFORMANCE_DIAGNOSTIC_END -->")

        return json.joined(separator: "\n")
    }

    /// Simple JSON string escaping without Foundation.
    private func _jsonString(_ s: Swift.String) -> Swift.String {
        var result = "\""
        for c in s {
            switch c {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default: result.append(c)
            }
        }
        result += "\""
        return result
    }
}
