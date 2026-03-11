//
//  Tests.Complexity.swift
//  swift-tests
//
//  Namespace for empirical complexity analysis.
//

extension Tests {
    /// Namespace for empirical complexity analysis.
    ///
    /// Provides the policy layer for complexity deduction. Given raw
    /// ``Test/Benchmark/Complexity/Evidence`` produced by the primitives
    /// layer, this namespace applies thresholds, confidence mapping, and
    /// compatibility semantics to produce an interpreted ``Result``.
    ///
    /// Two primary use cases:
    ///
    /// - **Exploratory**: "What complexity does this function appear to have?"
    ///   ```swift
    ///   let result = try Tests.Complexity.analyze(sizes: [...]) { n in ... }
    ///   print(result.evidence.exponent.value) // effective exponent k
    ///   ```
    ///
    /// - **Contractual**: "This function should remain no worse than linearithmic."
    ///   ```swift
    ///   let result = try Tests.Complexity.analyze(sizes: [...]) { n in ... }
    ///   #expect(result.isNoWorseThan(.linearithmic))
    ///   ```
    public enum Complexity {}
}
