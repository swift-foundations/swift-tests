//
//  Tests.Complexity.Confidence.swift
//  swift-tests
//
//  Confidence level for complexity classification.
//

extension Tests.Complexity {
    /// Confidence level for a complexity classification.
    ///
    /// Derived from multiple signals: measurement adequacy, continuous
    /// fit quality, discrete candidate separation, and cross-validation
    /// between the effective exponent and the discrete winner.
    ///
    /// All thresholds that determine confidence are provisional and
    /// subject to calibration against synthetic workloads.
    public enum Confidence: Swift.String, Sendable, Hashable, Codable {
        /// Clear winner with wide separation from alternatives.
        case high

        /// Plausible winner but alternatives are nearby.
        case medium

        /// Multiple viable candidates, weak discrimination.
        case low

        /// Cannot determine complexity from the available evidence.
        case inconclusive

        /// Ordinal ranking for comparison (higher is better).
        internal var order: Int {
            switch self {
            case .high: 3
            case .medium: 2
            case .low: 1
            case .inconclusive: 0
            }
        }
    }
}
