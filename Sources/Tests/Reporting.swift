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

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif os(Windows)
    import CRT
#endif

extension Tests {
    /// Print a performance measurement summary
    ///
    /// Example:
    /// ```swift
    /// let measurement = Tests.measure(iterations: 100) { operation() }
    /// Tests.printPerformance("Operation Name", measurement)
    /// ```
    public static func printPerformance(
        _ name: String,
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

    private static func formatBytes(_ bytes: Int) -> String {
        bytes.formatted(.bytes)
    }
}

// MARK: - ANSI Color Support

extension Tests {
    /// ANSI color codes for terminal output
    internal enum ANSIColor: String {
        case reset = "\u{001B}[0m"
        case red = "\u{001B}[31m"
        case green = "\u{001B}[32m"
        case yellow = "\u{001B}[33m"
        case blue = "\u{001B}[34m"
        case bold = "\u{001B}[1m"
        case dim = "\u{001B}[2m"

        /// Check if terminal supports ANSI colors
        static var isSupported: Bool {
            #if os(Linux) || os(macOS)
                guard let termPtr = getenv("TERM") else {
                    return false
                }
                let term = String(cString: termPtr)
                return term != "dumb" && !term.isEmpty
            #else
                return false
            #endif
        }

        /// Wrap text in color if supported
        static func colored(_ text: String, color: ANSIColor) -> String {
            guard isSupported else { return text }
            return color.rawValue + text + ANSIColor.reset.rawValue
        }
    }

    /// Center text within a given width
    internal static func centerText(_ text: String, width: Int) -> String {
        let padding = width - text.count
        guard padding > 0 else { return text }

        let leftPad = padding / 2
        let rightPad = padding - leftPad

        return String(repeating: " ", count: leftPad) + text
            + String(repeating: " ", count: rightPad)
    }
}

/// Performance comparison report
public struct PerformanceComparison: Sendable {
    public let name: String
    public let current: Tests.Measurement
    public let baseline: Tests.Measurement
    public let metric: Tests.Metric

    public init(
        name: String,
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

    public func formatted() -> String {
        let changeSymbol = isRegression ? "↑" : "↓"
        let changeEmoji = isRegression ? "🔴" : "🟢"

        let nameColored =
            isRegression
            ? Tests.ANSIColor.colored(name, color: .red)
            : Tests.ANSIColor.colored(name, color: .green)

        let changeText = "\(changeSymbol) \(abs(change).formatted(.percent.precision(1)))"
        let changeColored =
            isRegression
            ? Tests.ANSIColor.colored(changeText, color: .red)
            : Tests.ANSIColor.colored(changeText, color: .green)

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
        let summaryColored = ANSIColor.colored(summaryText, color: .bold)
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
