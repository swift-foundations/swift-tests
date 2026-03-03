import Time_Primitives

extension Tests {
    /// Temporal trend analysis result for a sequence of duration measurements.
    public struct Trend: Sendable {
        /// Mann-Kendall Z statistic.
        ///
        /// |Z| > 1.96 indicates a statistically significant monotonic trend
        /// at the 95% confidence level.
        public let z: Double

        /// Human-readable interpretation of the trend.
        public let interpretation: Interpretation

        /// Trend direction classification.
        public struct Interpretation: Sendable, Codable, Hashable, CustomStringConvertible {
            public let rawValue: Swift.String

            public init(rawValue: Swift.String) {
                self.rawValue = rawValue
            }

            /// Z > 1.96 — significant monotonic increase (e.g., thermal throttling).
            public static let increasing = Self(rawValue: "increasing")

            /// Z < -1.96 — significant monotonic decrease (e.g., caching warmup effect).
            public static let decreasing = Self(rawValue: "decreasing")

            /// |Z| <= 1.96 — no statistically significant trend.
            public static let none = Self(rawValue: "none")

            public var description: Swift.String { rawValue }
        }
    }
}
