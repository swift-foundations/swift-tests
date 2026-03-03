//
//  Tests.Baseline.swift
//  swift-tests
//
//  Namespace for baseline storage and comparison.
//

extension Tests {
    /// Namespace for file-backed performance baseline storage.
    ///
    /// Baselines are stored as JSON files in a `.benchmarks/` directory,
    /// keyed by test identity and environment fingerprint. The scope
    /// provider loads, compares, and saves baselines automatically when
    /// `baselineTolerance` is configured on a `.timed()` trait.
    public enum Baseline {}
}
