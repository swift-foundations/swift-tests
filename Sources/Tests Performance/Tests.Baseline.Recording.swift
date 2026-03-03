//
//  Tests.Baseline.Recording.swift
//  swift-tests
//
//  Recording mode for baseline storage.
//

import Environment

extension Tests.Baseline {
    /// Controls when baselines are written to disk.
    ///
    /// Resolved from the `SWIFT_BENCHMARK_RECORD` environment variable.
    public enum Recording: Swift.String, Sendable {
        /// Record if missing, compare if exists. Default behavior.
        case normal

        /// Always overwrite the stored baseline after measurement.
        case all

        /// Never write baselines. Fail if no baseline exists.
        case never
    }
}

extension Tests.Baseline.Recording {
    /// Resolves the recording mode from the `SWIFT_BENCHMARK_RECORD` environment variable.
    ///
    /// - `nil` or unset → `.normal`
    /// - `"all"` → `.all`
    /// - `"never"` → `.never`
    /// - Anything else → `.normal`
    public static func fromEnvironment() -> Self {
        guard let value = Environment.read("SWIFT_BENCHMARK_RECORD") else {
            return .normal
        }
        switch value.lowercased() {
        case "all": return .all
        case "never": return .never
        default: return .normal
        }
    }
}
