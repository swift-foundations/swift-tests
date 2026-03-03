import Sample_Primitives

extension Tests.Trend {
    /// Computes the Mann-Kendall trend statistic from a temporal sequence of durations.
    ///
    /// The Mann-Kendall test is a nonparametric test for monotonic trend in a time series.
    /// It does not assume any distribution. It counts concordant vs discordant pairs:
    ///
    /// - S = Σ sign(xj - xi) for all i < j
    /// - Var(S) = n(n-1)(2n+5)/18
    /// - Z = (S - sign(S)) / sqrt(Var(S))
    ///
    /// The durations MUST be in temporal (insertion) order, NOT sorted order.
    /// Use `measurement.durations`, not `measurement.batch`.
    ///
    /// - Parameter durations: Temporal sequence of duration measurements.
    /// - Returns: Trend result with Z statistic and interpretation.
    public static func mannKendall(_ durations: [Duration]) -> Self {
        let n = durations.count
        guard n >= 3 else {
            return Self(z: 0, interpretation: .none)
        }

        let averaging = Sample.Averaging<Duration>.duration

        // Compute S: sum of sign(xj - xi) for all i < j
        var s: Int = 0
        for i in 0..<(n - 1) {
            let xi = averaging.project(durations[i])
            for j in (i + 1)..<n {
                let xj = averaging.project(durations[j])
                let diff = xj - xi
                if diff > 0 { s += 1 }
                else if diff < 0 { s -= 1 }
            }
        }

        // Variance of S (without tie correction — sufficient for small n typical of benchmarks)
        let variance = Double(n * (n - 1) * (2 * n + 5)) / 18.0

        // Z statistic with continuity correction
        let z: Double
        if s > 0 {
            z = (Double(s) - 1.0) / variance.squareRoot()
        } else if s < 0 {
            z = (Double(s) + 1.0) / variance.squareRoot()
        } else {
            z = 0.0
        }

        // Interpretation at α = 0.05 (Z critical = 1.96)
        let interpretation: Tests.Trend.Interpretation
        if z > 1.96 {
            interpretation = .increasing
        } else if z < -1.96 {
            interpretation = .decreasing
        } else {
            interpretation = .none
        }

        return Self(z: z, interpretation: interpretation)
    }
}
