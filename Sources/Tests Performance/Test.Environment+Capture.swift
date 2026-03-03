#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

extension Test.Environment {
    /// Captures the current runtime and compile-time environment.
    public static func capture() -> Self {
        Self(
            architecture: _architecture,
            physicalCPUCount: _physicalCPUCount,
            logicalCPUCount: _logicalCPUCount,
            memoryBytes: _memoryBytes,
            osVersion: _osVersion,
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

// MARK: - Platform Detection

extension Test.Environment {

    private static var _architecture: Swift.String {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #elseif arch(i386)
        return "i386"
        #else
        return "unknown"
        #endif
    }

    private static var _swiftVersion: Swift.String {
        #if swift(>=6.2)
        return "6.2"
        #elseif swift(>=6.1)
        return "6.1"
        #elseif swift(>=6.0)
        return "6.0"
        #else
        return "< 6.0"
        #endif
    }

    #if canImport(Darwin)

    private static var _physicalCPUCount: Int {
        _sysctlInt("hw.physicalcpu") ?? 0
    }

    private static var _logicalCPUCount: Int {
        _sysctlInt("hw.logicalcpu") ?? 0
    }

    private static var _memoryBytes: UInt64 {
        _sysctlUInt64("hw.memsize") ?? 0
    }

    private static var _osVersion: Swift.String {
        var name = utsname()
        uname(&name)
        let sysname = unsafe withUnsafePointer(to: &name.sysname) {
            unsafe $0.withMemoryRebound(to: CChar.self, capacity: 256) {
                unsafe Swift.String(cString: $0)
            }
        }
        let release = unsafe withUnsafePointer(to: &name.release) {
            unsafe $0.withMemoryRebound(to: CChar.self, capacity: 256) {
                unsafe Swift.String(cString: $0)
            }
        }
        return "\(sysname) \(release)"
    }

    private static func _sysctlInt(_ name: Swift.String) -> Int? {
        var value: Int = 0
        var size = MemoryLayout<Int>.size
        let result = unsafe sysctlbyname(name, &value, &size, nil, 0)
        return result == 0 ? value : nil
    }

    private static func _sysctlUInt64(_ name: Swift.String) -> UInt64? {
        var value: UInt64 = 0
        var size = MemoryLayout<UInt64>.size
        let result = unsafe sysctlbyname(name, &value, &size, nil, 0)
        return result == 0 ? value : nil
    }

    #elseif canImport(Glibc) || canImport(Musl)

    private static var _physicalCPUCount: Int {
        Int(sysconf(Int32(_SC_NPROCESSORS_ONLN)))
    }

    private static var _logicalCPUCount: Int {
        _physicalCPUCount
    }

    private static var _memoryBytes: UInt64 {
        var info = sysinfo()
        Glibc.sysinfo(&info)
        return UInt64(info.totalram) * UInt64(info.mem_unit)
    }

    private static var _osVersion: Swift.String {
        var name = utsname()
        uname(&name)
        let sysname = withUnsafePointer(to: &name.sysname) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) {
                Swift.String(cString: $0)
            }
        }
        let release = withUnsafePointer(to: &name.release) {
            $0.withMemoryRebound(to: CChar.self, capacity: 256) {
                Swift.String(cString: $0)
            }
        }
        return "\(sysname) \(release)"
    }

    #else

    private static var _physicalCPUCount: Int { 0 }
    private static var _logicalCPUCount: Int { 0 }
    private static var _memoryBytes: UInt64 { 0 }
    private static var _osVersion: Swift.String { "unknown" }

    #endif
}
