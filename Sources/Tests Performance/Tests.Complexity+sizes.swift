//
//  Tests.Complexity+sizes.swift
//  swift-tests
//
//  Geometric size generation helper.
//

extension Tests.Complexity {
    /// Generates a geometric sequence of input sizes.
    ///
    /// Produces sizes starting at `from`, multiplied by `factor` at each
    /// step, up to and including `through`. The result is deterministic
    /// and always includes the endpoint if it's reachable.
    ///
    /// ```swift
    /// Tests.Complexity.sizes(from: 100, through: 1_000_000)
    /// // [100, 1_000, 10_000, 100_000, 1_000_000]
    ///
    /// Tests.Complexity.sizes(from: 1_024, through: 1_048_576, factor: 4)
    /// // [1_024, 4_096, 16_384, 65_536, 262_144, 1_048_576]
    /// ```
    ///
    /// - Parameters:
    ///   - from: Starting size (must be > 0).
    ///   - through: Maximum size (inclusive if reachable).
    ///   - factor: Multiplicative step between sizes (default: 10).
    /// - Returns: Array of input sizes in ascending order.
    public static func sizes(
        from: Int,
        through: Int,
        factor: Int = 10
    ) -> [Int] {
        precondition(from > 0, "Starting size must be positive")
        precondition(through >= from, "End size must be >= start size")
        precondition(factor >= 2, "Factor must be >= 2")

        var result: [Int] = []
        var current = from
        while current <= through {
            result.append(current)
            // Guard against overflow.
            let next = current.multipliedReportingOverflow(by: factor)
            if next.overflow { break }
            current = next.partialValue
        }
        return result
    }
}
