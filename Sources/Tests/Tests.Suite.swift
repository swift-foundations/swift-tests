//
//  Tests.Suite.swift
//  swift-tests
//
//  Performance benchmark suite for running and reporting multiple benchmarks.
//

public import Time_Primitives

extension Tests {
    /// Performance benchmark suite for running and reporting multiple benchmarks.
    public struct Suite {
        /// Name of the performance suite for reporting.
        public let name: Swift.String
        private var benchmarks: [(name: Swift.String, measurement: Tests.Measurement)] = []

        /// Creates a new performance suite with the given name.
        public init(name: Swift.String) {
            self.name = name
        }

        /// Run and measure a synchronous benchmark operation.
        public mutating func benchmark<T>(
            _ name: Swift.String,
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
        public mutating func benchmark<T, E: Swift.Error>(
            _ name: Swift.String,
            warmup: Int = 0,
            iterations: Int = 10,
            operation: () async throws(E) -> T
        ) async throws(E) -> T {
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
                print("  \(paddedName)  \(value.formatted())")
            }

            print("\n╚══════════════════════════════════════════════════════════╝\n")
        }

        private func padRight(_ string: Swift.String, toLength length: Int) -> Swift.String {
            if string.count >= length { return string }
            return string + Swift.String(repeating: " ", count: length - string.count)
        }
    }
}

@available(*, deprecated, renamed: "Tests.Suite")
public typealias PerformanceSuite = Tests.Suite
