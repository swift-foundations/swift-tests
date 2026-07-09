import Testing
import Tests_Test_Support

extension Test_Primitives.Test.Environment {
    @Suite
    struct Test {
        @Suite struct Capture {}
        @Suite struct Fingerprint {}
    }
}

// MARK: - Capture

extension Test_Primitives.Test.Environment.Test.Capture {
    @Test
    func `capture Returns Non Zero Values`() {
        let env = Test.Environment.capture()
        #expect(!env.architecture.isEmpty)
        #expect(env.physicalCPUCount > 0)
        #expect(env.logicalCPUCount > 0)
        #expect(env.memoryBytes > 0)
        #expect(!env.osVersion.isEmpty)
        #expect(!env.swiftVersion.isEmpty)
    }

    @Test
    func `optimization Matches Build Configuration`() {
        let opt = Test.Environment.Optimization.current
        #if DEBUG
            #expect(opt == .debug)
        #else
            #expect(opt == .release)
        #endif
    }
}

// MARK: - Fingerprint

extension Test_Primitives.Test.Environment.Test.Fingerprint {
    @Test
    func `fingerprint Contains Architecture`() {
        let env = Test.Environment.capture()
        #expect(env.fingerprint.contains(env.architecture))
    }

    @Test
    func `fingerprint Contains Optimization`() {
        let env = Test.Environment.capture()
        #expect(env.fingerprint.contains(env.optimization.rawValue))
    }
}
