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

public import Binary_Primitives
public import Formatting_Primitives
public import Time_Primitives
public import Console

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
               Min:        \(formatDuration(measurement.min))
               Median:     \(formatDuration(measurement.median))
               Mean:       \(formatDuration(measurement.mean))
               p95:        \(formatDuration(measurement.p95))
               p99:        \(formatDuration(measurement.p99))
               Max:        \(formatDuration(measurement.max))
               StdDev:     \(formatDuration(measurement.standardDeviation))
            """

        if let allocations = allocations, !allocations.isEmpty {
            let minAlloc = allocations.min() ?? 0
            let maxAlloc = allocations.max() ?? 0
            let avgAlloc = allocations.reduce(0, +) / allocations.count

            output += """

                   Allocations:
                     Min:      \(formatBytes(minAlloc))
                     Median:   \(formatBytes(allocations.sorted()[allocations.count / 2]))
                     Max:      \(formatBytes(maxAlloc))
                     Avg:      \(formatBytes(avgAlloc))
                """
        }

        if let peak = peakMemory {
            output += """

                   Peak Memory: \(formatBytes(peak))
                """
        }

        print(output)
    }

    private static func formatBytes(_ bytes: Int) -> Swift.String {
        bytes.formatted(.bytes)
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

/// Performance comparison report
public struct PerformanceComparison: Sendable {
    public let name: Swift.String
    public let current: Tests.Measurement
    public let baseline: Tests.Measurement
    public let metric: Tests.Metric

    public init(
        name: Swift.String,
        current: Tests.Measurement,
        baseline: Tests.Measurement,
        metric: Tests.Metric = .median
    ) {
        self.name = name
        self.current = current
        self.baseline = baseline
        self.metric = metric
    }

    public var currentValue: Duration {
        metric.extract(from: current)
    }

    public var baselineValue: Duration {
        metric.extract(from: baseline)
    }

    public var change: Double {
        (currentValue.inSeconds - baselineValue.inSeconds) / baselineValue.inSeconds
    }

    public var isRegression: Bool {
        change > 0
    }

    public var isImprovement: Bool {
        change < 0
    }

    public func formatted() -> Swift.String {
        let changeSymbol = isRegression ? "↑" : "↓"
        let changeEmoji = isRegression ? "🔴" : "🟢"

        let nameColored =
            isRegression
            ? Tests.OutputStyle.styled(name, .red)
            : Tests.OutputStyle.styled(name, .green)

        let changeText = "\(changeSymbol) \(abs(change).formatted(.percent.precision(1)))"
        let changeColored =
            isRegression
            ? Tests.OutputStyle.styled(changeText, .red)
            : Tests.OutputStyle.styled(changeText, .green)

        return """
            \(changeEmoji) \(nameColored)
                Baseline: \(Tests.formatDuration(baselineValue))
                Current:  \(Tests.formatDuration(currentValue))
                Change:   \(changeColored)
            """
    }
}

extension Tests {
    /// Print comparison report for multiple benchmarks
    public static func printComparisonReport(_ comparisons: [PerformanceComparison]) {
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

/// Performance benchmark suite
public struct PerformanceSuite {
    /// Name of the performance suite for reporting.
    public let name: String
    private var benchmarks: [(name: String, measurement: Tests.Measurement)] = []

    /// Creates a new performance suite with the given name.
    public init(name: String) {
        self.name = name
    }

    /// Run and measure a synchronous benchmark operation.
    public mutating func benchmark<T>(
        _ name: String,
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () -> T
    ) -> T {
        let (result, measurement) = Tests.measure(
            warmup: warmup,
            iterations: iterations,
            operation: operation
        )
        benchmarks.append((name, measurement))
        return result
    }

    /// Run and measure an asynchronous benchmark operation.
    public mutating func benchmark<T>(
        _ name: String,
        warmup: Int = 0,
        iterations: Int = 10,
        operation: () async throws -> T
    ) async rethrows -> T {
        let (result, measurement) = try await Tests.measure(
            warmup: warmup,
            iterations: iterations,
            operation: operation
        )
        benchmarks.append((name, measurement))
        return result
    }

    /// Print a formatted report of all benchmarks in the suite.
    public func printReport(metric: Tests.Metric = .median) {
        let boxWidth = 58
        let centeredTitle = Tests.centerText(name, width: boxWidth)

        print("\n╔══════════════════════════════════════════════════════════╗")
        print("║\(centeredTitle)║")
        print("╚══════════════════════════════════════════════════════════╝\n")

        let maxNameLength = benchmarks.map { $0.name.count }.max() ?? 0

        for (name, measurement) in benchmarks {
            let value = metric.extract(from: measurement)
            let paddedName = padRight(name, toLength: maxNameLength)
            print("  \(paddedName)  \(Tests.formatDuration(value))")
        }

        print("\n╚══════════════════════════════════════════════════════════╝\n")
    }

    private func padRight(_ string: String, toLength length: Int) -> String {
        if string.count >= length {
            return string
        }
        return string + String(repeating: " ", count: length - string.count)
    }
}
