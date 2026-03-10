//
//  Tests.History.swift
//  swift-tests
//
//  Namespace for run history tracking.
//

extension Tests {
    /// Namespace for append-only run history.
    ///
    /// Each `.timed()` benchmark appends a record to a JSONL file.
    /// Over time, this builds a temporal sequence that enables
    /// cross-run trend analysis via Mann-Kendall.
    ///
    /// ## Directory Convention
    ///
    /// ```
    /// .benchmarks/
    ///   {module}/{suite}/{test-name}/
    ///     {fingerprint}.json   ← baseline (single snapshot)
    ///     {fingerprint}.jsonl  ← history  (append-only)
    /// ```
    public enum History {}
}
