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

public import Time_Primitives

extension Test.Benchmark {
    /// Configuration for timed test execution.
    public struct Configuration: Sendable, Codable, Hashable {
        /// Number of measurement iterations.
        public var iterations: Int

        /// Number of warmup iterations (not measured).
        public var warmup: Int

        /// Whether to print results to console.
        public var printResults: Bool

        /// Optional performance threshold to enforce.
        public var threshold: Duration?

        /// Metric to check against threshold.
        public var metric: Metric

        /// Creates a timed configuration.
        public init(
            iterations: Int = 10,
            warmup: Int = 0,
            printResults: Bool = true,
            threshold: Duration? = nil,
            metric: Metric = .median
        ) {
            self.iterations = iterations
            self.warmup = warmup
            self.printResults = printResults
            self.threshold = threshold
            self.metric = metric
        }
    }
}

// MARK: - Encoding

extension Test.Benchmark.Configuration {
    /// Encodes the configuration to a string for trait storage.
    public func encode() -> String {
        var parts: [String] = []
        parts.append("i=\(iterations)")
        parts.append("w=\(warmup)")
        parts.append("p=\(printResults)")
        parts.append("m=\(metric.rawValue)")
        if let threshold {
            let components = threshold.components
            parts.append("t=\(components.seconds):\(components.attoseconds)")
        }
        return parts.joined(separator: ";")
    }

    /// Decodes configuration from a trait string.
    public static func decode(from string: String) -> Configuration? {
        var config = Configuration()

        for part in string.split(separator: ";") {
            let keyValue = part.split(separator: "=", maxSplits: 1)
            guard keyValue.count == 2 else { continue }
            let key = String(keyValue[0])
            let value = String(keyValue[1])

            switch key {
            case "i":
                config.iterations = Int(value) ?? 10
            case "w":
                config.warmup = Int(value) ?? 0
            case "p":
                config.printResults = value == "true"
            case "m":
                config.metric = Test.Benchmark.Metric(rawValue: value) ?? .median
            case "t":
                let components = value.split(separator: ":")
                if components.count == 2,
                   let seconds = Int64(components[0]),
                   let attoseconds = Int64(components[1]) {
                    config.threshold = Duration(
                        secondsComponent: seconds,
                        attosecondsComponent: attoseconds
                    )
                }
            default:
                break
            }
        }

        return config
    }
}
