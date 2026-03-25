//
//  Tests.Comparison.swift
//  swift-tests
//
//  Performance comparison report between current and baseline measurements.
//

import Formatting_Primitives
public import Time_Primitives
public import Sample_Primitives
import Console

extension Tests {
    /// Performance comparison report between current and baseline measurements.
    public struct Comparison: Sendable {
        public let name: Swift.String
        public let current: Test.Benchmark.Measurement
        public let baseline: Test.Benchmark.Measurement
        public let metric: Test.Benchmark.Metric

        public init(
            name: Swift.String,
            current: Test.Benchmark.Measurement,
            baseline: Test.Benchmark.Measurement,
            metric: Test.Benchmark.Metric = .median
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
            let comparison = Sample.Comparison(
                baseline: baseline.batch,
                current: current.batch,
                metric: metric,
                polarity: .lowerIsBetter
            )
            return comparison.change(using: .duration) ?? 0.0
        }

        public var isRegression: Bool { change > 0 }
        public var isImprovement: Bool { change < 0 }

        public func formatted() -> Swift.String {
            let changeSymbol = isRegression ? "↑" : "↓"
            let changeEmoji = isRegression ? "🔴" : "🟢"

            let nameColored = (isRegression ? Console.Style.error : .success)
                .apply(to: name, capability: Tests.consoleCapability)

            let changeText = "\(changeSymbol) \(abs(change).formatted(.percent.precision(1)))"
            let changeColored = (isRegression ? Console.Style.error : .success)
                .apply(to: changeText, capability: Tests.consoleCapability)

            return """
                \(changeEmoji) \(nameColored)
                    Baseline: \(baselineValue.formatted())
                    Current:  \(currentValue.formatted())
                    Change:   \(changeColored)
                """
        }
    }
}

