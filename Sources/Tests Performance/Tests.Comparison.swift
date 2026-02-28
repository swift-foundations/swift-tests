//
//  Tests.Comparison.swift
//  swift-tests
//
//  Performance comparison report between current and baseline measurements.
//

public import Formatting_Primitives
public import Time_Primitives
public import Sample_Primitives

extension Tests {
    /// Performance comparison report between current and baseline measurements.
    public struct Comparison: Sendable {
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
                    Baseline: \(baselineValue.formatted())
                    Current:  \(currentValue.formatted())
                    Change:   \(changeColored)
                """
        }
    }
}

@available(*, deprecated, renamed: "Tests.Comparison")
public typealias PerformanceComparison = Tests.Comparison
