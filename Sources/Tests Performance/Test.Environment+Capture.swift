import Kernel

extension Test.Environment {
    /// Captures the current runtime and compile-time environment.
    public static func capture() -> Self {
        let name = System.name
        let osVersion = "\(name.system) \(name.release)"
        let physical = System.Processor.Physical.count
        let logical = System.Processor.count
        let memory = System.Memory.total
        return Self(
            architecture: _architecture,
            physicalCPUCount: physical,
            logicalCPUCount: logical,
            memoryBytes: memory,
            osVersion: osVersion,
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
