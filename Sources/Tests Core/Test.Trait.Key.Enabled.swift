//
//  Test.Trait.Key.Enabled.swift
//  swift-tests
//
//  Witness key for enabled traits.
//

extension Test.Trait {
    /// Witness key for enabled/disabled state.
    public struct Enabled: Sendable {
        /// Whether the test is enabled.
        public let isEnabled: Bool

        /// Optional reason for disabling.
        public let comment: Test.Text?

        /// Creates an enabled value.
        public init(isEnabled: Bool, comment: Test.Text? = nil) {
            self.isEnabled = isEnabled
            self.comment = comment
        }
    }
}

extension Test.Trait.Enabled: Witness.Key {
    public typealias Value = Test.Trait.Enabled?

    @inlinable
    public static var liveValue: Test.Trait.Enabled? { nil }
}
