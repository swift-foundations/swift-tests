import Testing
import Tests_Test_Support

@Suite
struct TestEnvironmentTests {

    @Suite struct Capture {}
    @Suite struct Fingerprint {}
}

// MARK: - Capture

extension TestEnvironmentTests.Capture {
    @Test
    func captureReturnsNonZeroValues() {
        let env = Test.Environment.capture()
        #expect(!env.architecture.isEmpty)
        #expect(env.physicalCPUCount > 0)
        #expect(env.logicalCPUCount > 0)
        #expect(env.memoryBytes > 0)
        #expect(!env.osVersion.isEmpty)
        #expect(!env.swiftVersion.isEmpty)
    }

    @Test
    func optimizationMatchesBuildConfiguration() {
        let opt = Test.Environment.Optimization.current
        #if DEBUG
            #expect(opt == .debug)
        #else
            #expect(opt == .release)
        #endif
    }
}

// MARK: - Fingerprint

extension TestEnvironmentTests.Fingerprint {
    @Test
    func fingerprintContainsArchitecture() {
        let env = Test.Environment.capture()
        #expect(env.fingerprint.contains(env.architecture))
    }

    @Test
    func fingerprintContainsOptimization() {
        let env = Test.Environment.capture()
        #expect(env.fingerprint.contains(env.optimization.rawValue))
    }
}
