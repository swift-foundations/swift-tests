extension Test.Environment {
    /// Compile-time feature flags detected via `#if hasFeature(...)`.
    ///
    /// These are the flags most likely to affect performance characteristics.
    /// Each flag is a compile-time constant determined by the Package.swift
    /// swift settings of the package being tested.
    ///
    /// Note: detects flags for the *swift-tests* compilation unit, not necessarily
    /// the test target's compilation unit.
    public struct Features: Sendable, Codable, Hashable {
        /// Whether `NonisolatedNonsendingByDefault` is enabled.
        public var nonisolatedNonsendingByDefault: Bool

        /// Whether `StrictMemorySafety` is enabled.
        public var strictMemorySafety: Bool

        public init(
            nonisolatedNonsendingByDefault: Bool,
            strictMemorySafety: Bool
        ) {
            self.nonisolatedNonsendingByDefault = nonisolatedNonsendingByDefault
            self.strictMemorySafety = strictMemorySafety
        }
    }
}

extension Test.Environment.Features {
    /// Detects feature flags for the current compilation unit.
    public static var current: Self {
        Self(
            nonisolatedNonsendingByDefault: {
                #if hasFeature(NonisolatedNonsendingByDefault)
                    return true
                #else
                    return false
                #endif
            }(),
            strictMemorySafety: {
                #if hasFeature(StrictMemorySafety)
                    return true
                #else
                    return false
                #endif
            }()
        )
    }
}
