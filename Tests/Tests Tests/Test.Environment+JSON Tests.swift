import Testing
import Tests_Test_Support
import JSON

extension TestEnvironmentTests {
    @Suite struct JSON {}
}

// MARK: - JSON

extension TestEnvironmentTests.JSON {
    @Test
    func `serialize and deserialize preserves all fields`() throws {
        let original = Test.Environment.capture()

        let json = Test.Environment.serialize(original)
        let roundtripped = try Test.Environment.deserialize(json)

        #expect(roundtripped.architecture == original.architecture)
        #expect(roundtripped.physicalCPUCount == original.physicalCPUCount)
        #expect(roundtripped.logicalCPUCount == original.logicalCPUCount)
        #expect(roundtripped.memoryBytes == original.memoryBytes)
        #expect(roundtripped.osVersion == original.osVersion)
        #expect(roundtripped.swiftVersion == original.swiftVersion)
        #expect(roundtripped.optimization.rawValue == original.optimization.rawValue)
        #expect(roundtripped.fingerprint == original.fingerprint)
    }

    @Test
    func `features roundtrip correctly`() throws {
        let original = Test.Environment.capture()

        let json = Test.Environment.serialize(original)
        let roundtripped = try Test.Environment.deserialize(json)

        #expect(
            roundtripped.features.nonisolatedNonsendingByDefault
                == original.features.nonisolatedNonsendingByDefault
        )
        #expect(
            roundtripped.features.strictMemorySafety
                == original.features.strictMemorySafety
        )
    }

    @Test
    func `missing required key throws error`() {
        let incomplete: JSON = .object([
            ("architecture", .string("arm64")),
        ])
        #expect(throws: JSON.Error.self) {
            _ = try Test.Environment.deserialize(incomplete)
        }
    }
}
