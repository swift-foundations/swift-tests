// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-tests open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-tests project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

import Binary_Primitives
import Formatting_Primitives
import Time_Primitives
import Console

extension Tests {
    /// Print a performance measurement summary
    ///
    /// Example:
    /// ```swift
    /// let measurement = Tests.measure(iterations: 100) { operation() }
    /// Tests.printPerformance("Operation Name", measurement)
    /// ```
    public static func printPerformance(
        _ name: Swift.String,
        _ measurement: Tests.Measurement,
        allocations: [Int]? = nil,
        peakMemory: Int? = nil
    ) {
        var output = """
            ⏱️ \(name)
               Iterations: \(measurement.durations.count)
               Min:        \(measurement.min.formatted())
               Median:     \(measurement.median.formatted())
               Mean:       \(measurement.mean.formatted())
               p95:        \(measurement.p95.formatted())
               p99:        \(measurement.p99.formatted())
               Max:        \(measurement.max.formatted())
               StdDev:     \(measurement.standardDeviation.formatted())
            """

        if let allocations = allocations, !allocations.isEmpty {
            let minAlloc = allocations.min() ?? 0
            let maxAlloc = allocations.max() ?? 0
            let avgAlloc = allocations.reduce(0, +) / allocations.count

            output += """

                   Allocations:
                     Min:      \(minAlloc.formatted(.bytes))
                     Median:   \(allocations.sorted()[allocations.count / 2].formatted(.bytes))
                     Max:      \(maxAlloc.formatted(.bytes))
                     Avg:      \(avgAlloc.formatted(.bytes))
                """
        }

        if let peak = peakMemory {
            output += """

                   Peak Memory: \(peak.formatted(.bytes))
                """
        }

        print(output)
    }

}

// MARK: - Console Styling Support

extension Tests {
    /// Console capability detection (cached).
    internal static let consoleCapability = Console.Capability.detect()

    /// Predefined styles for test output.
    internal enum OutputStyle {
        case red
        case green
        case yellow
        case blue
        case bold
        case dim

        var style: Console.Style {
            switch self {
            case .red: return .error
            case .green: return .success
            case .yellow: return .warning
            case .blue: return .info
            case .bold: return .bold
            case .dim: return .dim
            }
        }

        /// Apply style to text using detected capability.
        static func styled(_ text: Swift.String, _ style: OutputStyle) -> Swift.String {
            style.style.apply(to: text, capability: consoleCapability)
        }
    }

    /// Center text within a given width.
    internal static func centerText(_ text: Swift.String, width: Int) -> Swift.String {
        let padding = width - text.count
        guard padding > 0 else { return text }

        let leftPad = padding / 2
        let rightPad = padding - leftPad

        return Swift.String(repeating: " ", count: leftPad) + text
            + Swift.String(repeating: " ", count: rightPad)
    }
}

extension Tests {
    /// Print comparison report for multiple benchmarks
    public static func printComparisonReport(_ comparisons: [Tests.Comparison]) {
        let boxWidth = 58
        let title = "PERFORMANCE COMPARISON REPORT"
        let centeredTitle = centerText(title, width: boxWidth)

        print("\n╔══════════════════════════════════════════════════════════╗")
        print("║\(centeredTitle)║")
        print("╚══════════════════════════════════════════════════════════╝\n")

        for comparison in comparisons {
            print(comparison.formatted())
            print("")
        }

        let regressions = comparisons.filter { $0.isRegression }.count
        let improvements = comparisons.filter { $0.isImprovement }.count
        let neutral = comparisons.count - regressions - improvements

        let summaryText =
            "Summary: \(improvements) improvements, \(neutral) neutral, \(regressions) regressions"
        let summaryColored = OutputStyle.styled(summaryText, .bold)
        print(summaryColored)
        print("╚══════════════════════════════════════════════════════════╝\n")
    }
}
