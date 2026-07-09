import Testing
import Tests_Test_Support

extension Test_Primitives.Test.Snapshot.Configuration {
    @Suite("Test.Snapshot.Configuration")
    struct Test {
        @Suite struct Unit {}
        @Suite struct EdgeCase {}
    }
}

// MARK: - Unit

extension Test_Primitives.Test.Snapshot.Configuration.Test.Unit {
    @Test
    func `default uses missing recording mode`() {
        let config = Test_Primitives.Test.Snapshot.Configuration.default
        #expect(config.recording == .missing)
    }

    @Test
    func `init stores custom values`() {
        let config = Test_Primitives.Test.Snapshot.Configuration(recording: .all)
        #expect(config.recording == .all)
    }

    @Test
    func `resolve returns explicit when provided`() {
        let result = Test_Primitives.Test.Snapshot.Configuration.resolve(recording: .all)
        #expect(result == .all)
    }

    @Test
    func `resolve returns missing as default fallback`() {
        let result = Test_Primitives.Test.Snapshot.Configuration.resolve(recording: nil)
        // Without task-local or env var, falls back to .missing
        #expect(result == .missing)
    }
}

// MARK: - EdgeCase

extension Test_Primitives.Test.Snapshot.Configuration.Test.EdgeCase {
    @Test
    func `snapshotDirectory defaults to nil`() {
        let config = Test_Primitives.Test.Snapshot.Configuration.default
        #expect(config.snapshotDirectory == nil)
    }
}
