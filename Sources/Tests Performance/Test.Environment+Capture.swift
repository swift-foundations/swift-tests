import Kernel

extension Test.Environment {
    /// Captures the current runtime and compile-time environment.
    public static func capture() -> Self {
        let name = System.name
        return Self(
            architecture: _architecture,
            physicalCPUCount: Int(System.Processor.Physical.count),
            logicalCPUCount: Int(System.Processor.count),
            memoryBytes: UInt64(System.Memory.total),
            osVersion: "\(name.system) \(name.release)",
            swiftVersion: _swiftVersion,
            optimization: .current,
            features: .current
        )
    }

    /// Human-readable fingerprint for file keying and display.
    ///
    /// Example: `"arm64-10c-debug-nnbd-sms"` or `"x86_64-8c-release"`
    public var fingerprint: Swift.String {
        var parts = [architecture, "\(physicalCPUCount)c"]
        parts.append(optimization.rawValue)
        if features.nonisolatedNonsendingByDefault { parts.append("nnbd") }
        if features.strictMemorySafety { parts.append("sms") }
        return parts.joined(separator: "-")
    }
}

// MARK: - Compile-Time Detection

extension Test.Environment {
    private static var _architecture: Swift.String {
        #if arch(arm64)
        "arm64"
        #elseif arch(x86_64)
        "x86_64"
        #elseif arch(i386)
        "i386"
        #else
        "unknown"
        #endif
    }

    private static var _swiftVersion: Swift.String {
        #if swift(>=6.2)
        "6.2"
        #elseif swift(>=6.1)
        "6.1"
        #elseif swift(>=6.0)
        "6.0"
        #else
        "< 6.0"
        #endif
    }
}
