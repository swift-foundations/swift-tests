//
//  Tests.Complexity.InconclusiveReason.swift
//  swift-tests
//
//  Reasons why complexity classification may be uncertain.
//

extension Tests.Complexity {
    /// Reasons why complexity classification may be uncertain or inconclusive.
    ///
    /// Multiple reasons can apply simultaneously. When confidence is
    /// ``Confidence/inconclusive``, at least one reason will be present.
    /// When confidence is ``Confidence/medium`` or ``Confidence/low``,
    /// reasons provide additional diagnostic context.
    public enum InconclusiveReason: Swift.String, Sendable, Hashable, Codable {
        /// Too few size points for reliable estimation.
        case insufficientData

        /// Sizes don't span enough orders of magnitude.
        case insufficientScaleRange

        /// Durations do not show monotonic growth with input size.
        case nonMonotone

        /// Log-log regression R² is below the quality floor.
        case weakContinuousFit

        /// No single discrete candidate separates from alternatives.
        case noSeparatedWinner

        /// Effective exponent disagrees with the discrete classification.
        case inconsistentSignals
    }
}
