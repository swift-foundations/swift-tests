extension Test.Environment {
    /// Build optimization level, detected at runtime via assert-probing.
    public struct Optimization: Sendable, Codable, Hashable, CustomStringConvertible {
        public let rawValue: Swift.String

        public init(rawValue: Swift.String) {
            self.rawValue = rawValue
        }
    }
}

extension Test.Environment.Optimization {
    /// Debug build (-Onone). Asserts are active.
    public static let debug = Self(rawValue: "debug")

    /// Release build (-O or -Osize). Asserts are stripped.
    public static let release = Self(rawValue: "release")

    /// Detects the current optimization level.
    ///
    /// Uses `assert()` side-effect: in debug builds, the closure executes
    /// and flips the flag. In release builds, `assert` is a no-op.
    public static var current: Self {
        var isDebug = false
        assert(
            {
                isDebug = true
                return true
            }()
        )
        return isDebug ? .debug : .release
    }

    public var description: Swift.String { rawValue }
}
