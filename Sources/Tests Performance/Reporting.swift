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
    /// Tests.report("Operation Name", measurement)
    /// ```
    public static func report(
        _ name: Swift.String,
        _ measurement: Test.Benchmark.Measurement,
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
            output += """

                   Allocations:
                     Min:      \((allocations.min() ?? 0).formatted(.bytes))
                     Median:   \(allocations.sorted()[allocations.count / 2].formatted(.bytes))
                     Max:      \((allocations.max() ?? 0).formatted(.bytes))
                     Avg:      \((allocations.reduce(0, +) / allocations.count).formatted(.bytes))
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

    /// Center text within a given width.
    internal static func center(_ text: Swift.String, width: Int) -> Swift.String {
        let padding = width - text.count
        guard padding > 0 else { return text }

        return Swift.String(repeating: " ", count: padding / 2) + text
            + Swift.String(repeating: " ", count: padding - padding / 2)
    }
}

extension Tests {
    /// Print comparison report for multiple benchmarks
    public static func report(comparisons: [Tests.Comparison]) {
        let boxWidth = 58
        let title = "PERFORMANCE COMPARISON REPORT"
        let centeredTitle = center(title, width: boxWidth)

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
        let summaryColored = Console.Style.bold.apply(to: summaryText, capability: consoleCapability)
        print(summaryColored)
        print("╚══════════════════════════════════════════════════════════╝\n")
    }
}
