import Time_Primitives

extension Test {
    /// Runtime and compile-time environment fingerprint for performance diagnostics.
    ///
    /// Captures hardware characteristics, compiler settings, and feature flags
    /// that affect performance measurement. Used to explain regressions caused
    /// by environment differences (e.g., debug vs release, feature flags enabled).
    public struct Environment: Sendable, Codable, Hashable {
        /// CPU architecture (e.g., "arm64", "x86_64").
        public var architecture: Swift.String

        /// Number of physical CPU cores.
        public var physicalCPUCount: Int

        /// Number of logical CPU cores (includes hyperthreading).
        public var logicalCPUCount: Int

        /// Total physical memory in bytes.
        public var memoryBytes: UInt64

        /// OS version string (e.g., "Darwin 24.3.0").
        public var osVersion: Swift.String

        /// Swift compiler version (compile-time detected range).
        public var swiftVersion: Swift.String

        /// Build optimization level.
        public var optimization: Optimization

        /// Enabled Swift feature flags.
        ///
        /// Note: detects flags for the *swift-tests* compilation unit, not necessarily
        /// the test target's compilation unit. Still valuable for diagnosing whether
        /// the test framework itself was compiled with those flags.
        public var features: Features

        public init(
            architecture: Swift.String,
            physicalCPUCount: Int,
            logicalCPUCount: Int,
            memoryBytes: UInt64,
            osVersion: Swift.String,
            swiftVersion: Swift.String,
            optimization: Optimization,
            features: Features
        ) {
            self.architecture = architecture
            self.physicalCPUCount = physicalCPUCount
            self.logicalCPUCount = logicalCPUCount
            self.memoryBytes = memoryBytes
            self.osVersion = osVersion
            self.swiftVersion = swiftVersion
            self.optimization = optimization
            self.features = features
        }
    }
}
