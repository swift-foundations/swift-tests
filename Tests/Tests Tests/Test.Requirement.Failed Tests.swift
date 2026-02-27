import Testing
import Tests
import Test_Primitives

@Suite("Test.Requirement.Failed")
struct TestRequirementFailedTests {
    @Suite struct Unit {}
}

// MARK: - Unit

extension TestRequirementFailedTests.Unit {
    @Test
    func `init stores message and sourceLocation`() {
        let location = Test_Primitives.Test.Source.Location(
            fileID: "Module/File.swift", line: 42, column: 5
        )
        let message = Test_Primitives.Test.Text("requirement not met")
        let failed = Test_Primitives.Test.Requirement.Failed(
            message: message,
            sourceLocation: location
        )
        #expect(failed.message.plainText == "requirement not met")
        #expect(failed.sourceLocation.line == 42)
        #expect(failed.sourceLocation.column == 5)
    }

    @Test
    func `description contains message text`() {
        let location = Test_Primitives.Test.Source.Location(
            fileID: "Module/File.swift", line: 10, column: 1
        )
        let failed = Test_Primitives.Test.Requirement.Failed(
            message: Test_Primitives.Test.Text("expected true"),
            sourceLocation: location
        )
        #expect(failed.description.contains("expected true"))
    }

    @Test
    func `description contains source location`() {
        let location = Test_Primitives.Test.Source.Location(
            fileID: "Module/File.swift", line: 99, column: 3
        )
        let failed = Test_Primitives.Test.Requirement.Failed(
            message: Test_Primitives.Test.Text("failed"),
            sourceLocation: location
        )
        let desc = failed.description
        #expect(desc.contains("99"))
    }
}
