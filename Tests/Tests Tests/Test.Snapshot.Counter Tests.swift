import Testing
import Tests_Test_Support

@Suite("Test.Snapshot.Counter")
struct SnapshotCounterTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit

extension SnapshotCounterTests.Unit {
    @Test
    func `next returns sequential values for same key`() {
        let counter = Test_Primitives.Test.Snapshot.Counter()
        #expect(counter.next(for: "key") == 1)
        #expect(counter.next(for: "key") == 2)
        #expect(counter.next(for: "key") == 3)
    }

    @Test
    func `next returns independent sequences per key`() {
        let counter = Test_Primitives.Test.Snapshot.Counter()
        #expect(counter.next(for: "a") == 1)
        #expect(counter.next(for: "b") == 1)
        #expect(counter.next(for: "a") == 2)
        #expect(counter.next(for: "b") == 2)
    }

    @Test
    func `reset clears all counters`() {
        let counter = Test_Primitives.Test.Snapshot.Counter()
        _ = counter.next(for: "a")
        _ = counter.next(for: "b")
        counter.reset()
        #expect(counter.next(for: "a") == 1)
        #expect(counter.next(for: "b") == 1)
    }

    @Test
    func `reset for specific key clears only that key`() {
        let counter = Test_Primitives.Test.Snapshot.Counter()
        _ = counter.next(for: "a")
        _ = counter.next(for: "b")
        counter.reset(for: "a")
        #expect(counter.next(for: "a") == 1)
        #expect(counter.next(for: "b") == 2)
    }

    @Test
    func `key generates from filePath and function`() {
        let key = Test_Primitives.Test.Snapshot.Counter.key(
            filePath: "/path/to/Tests.swift",
            function: "testExample()"
        )
        #expect(key == "/path/to/Tests.swift/testExample()")
    }
}

// MARK: - EdgeCase

extension SnapshotCounterTests.EdgeCase {
    @Test
    func `fresh counter returns 1 for first call`() {
        let counter = Test_Primitives.Test.Snapshot.Counter()
        #expect(counter.next(for: "fresh") == 1)
    }
}
