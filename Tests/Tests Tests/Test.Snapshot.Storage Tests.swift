import Testing
import Tests
import Test_Primitives
import Paths

@Suite("Test.Snapshot.Storage")
struct SnapshotStorageTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit

extension SnapshotStorageTests.Unit {
    @Test
    func `path creates __Snapshots__ directory component`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/MyTests.swift",
            function: "testExample()",
            name: nil,
            counter: 1,
            pathExtension: "json"
        )
        #expect(String(path).contains("__Snapshots__"))
    }

    @Test
    func `path uses test file stem as subdirectory`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/UserTests.swift",
            function: "testJSON()",
            name: nil,
            counter: 1,
            pathExtension: "json"
        )
        #expect(String(path).contains("UserTests"))
    }

    @Test
    func `path strips parentheses from function name`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/Tests.swift",
            function: "testFoo(bar:)",
            name: nil,
            counter: 1,
            pathExtension: "txt"
        )
        let pathString = String(path)
        #expect(pathString.contains("testFoo"))
        #expect(!pathString.contains("("))
    }

    @Test
    func `path uses counter when name is nil`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/Tests.swift",
            function: "testExample()",
            name: nil,
            counter: 3,
            pathExtension: "json"
        )
        #expect(String(path).contains(".3."))
    }

    @Test
    func `path uses name when provided`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/Tests.swift",
            function: "testExample()",
            name: "custom-name",
            counter: 1,
            pathExtension: "json"
        )
        #expect(String(path).contains("custom-name"))
    }

    @Test
    func `path uses correct extension`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/Tests.swift",
            function: "testExample()",
            name: nil,
            counter: 1,
            pathExtension: "json"
        )
        #expect(String(path).hasSuffix(".json"))
    }
}

// MARK: - EdgeCase

extension SnapshotStorageTests.EdgeCase {
    @Test
    func `path with special characters in name sanitizes`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/Tests.swift",
            function: "testExample()",
            name: "hello world/test",
            counter: 1,
            pathExtension: "txt"
        )
        let pathString = String(path)
        // Spaces and slashes become hyphens, collapsed
        #expect(pathString.contains("hello-world-test"))
    }
}
