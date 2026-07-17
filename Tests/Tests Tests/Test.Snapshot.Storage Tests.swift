import Paths
import Testing
import Tests_Test_Support

extension Test_Primitives.Test.Snapshot.Storage {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

// MARK: - Unit

extension Test_Primitives.Test.Snapshot.Storage.Test.Unit {
    @Test
    func `path is flat under .snapshots by default`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/MyTests.swift",
            function: "testExample()",
            name: "my-snapshot",
            counter: 0,
            pathExtension: "json"
        )
        let pathString = Swift.String(path)
        #expect(pathString == "/path/to/.snapshots/my-snapshot.json")
    }

    @Test
    func `path uses custom snapshot directory when provided`() {
        let customDir = File.Path("/custom/snapshots")
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/MyTests.swift",
            function: "testExample()",
            name: "my-snapshot",
            counter: 0,
            pathExtension: "json",
            snapshotDirectory: customDir
        )
        #expect(Swift.String(path) == "/custom/snapshots/my-snapshot.json")
    }

    @Test
    func `path uses subdirectory when provided`() throws {
        let sub = try File.Path.Component("PDF.Test.Snapshot")
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/Tests.swift",
            function: "testExample()",
            name: "my-snapshot",
            counter: 0,
            pathExtension: "pdf",
            subdirectory: sub
        )
        let pathString = Swift.String(path)
        #expect(pathString == "/path/to/.snapshots/PDF.Test.Snapshot/my-snapshot.pdf")
    }

    @Test
    func `unnamed path uses function and counter`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/Tests.swift",
            function: "testFoo(bar:)",
            name: nil,
            counter: 3,
            pathExtension: "txt"
        )
        let pathString = Swift.String(path)
        #expect(pathString == "/path/to/.snapshots/testFoo.3.txt")
    }

    @Test
    func `named path uses name directly without function prefix`() {
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/Tests.swift",
            function: "testExample()",
            name: "user-profile",
            counter: 1,
            pathExtension: "json"
        )
        let pathString = Swift.String(path)
        #expect(pathString == "/path/to/.snapshots/user-profile.json")
    }
}

// MARK: - EdgeCase

extension Test_Primitives.Test.Snapshot.Storage.Test.EdgeCase {
    @Test
    func `subdirectory combined with custom snapshot directory`() throws {
        let sub = try File.Path.Component("MyType")
        let path = Test_Primitives.Test.Snapshot.Storage.path(
            testFilePath: "/path/to/Tests.swift",
            function: "testExample()",
            name: "output",
            counter: 0,
            pathExtension: "txt",
            snapshotDirectory: File.Path("/custom"),
            subdirectory: sub
        )
        #expect(Swift.String(path) == "/custom/MyType/output.txt")
    }
}
