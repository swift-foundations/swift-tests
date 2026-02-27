import Testing
import Tests
import Test_Primitives

@Suite("Test.Body")
struct TestBodyTests {
    @Suite struct Unit {}
    @Suite struct EdgeCase {}
}

// MARK: - Unit

extension TestBodyTests.Unit {
    @Test
    func `sync factory creates synchronous body`() {
        let body = Test_Primitives.Test.Body.sync {}
        #expect(body.isSync)
        #expect(!body.isAsync)
    }

    @Test
    func `async factory creates asynchronous body`() {
        let body = Test_Primitives.Test.Body.async {}
        #expect(body.isAsync)
        #expect(!body.isSync)
    }

    @Test
    func `sync body run succeeds`() async throws {
        let body = Test_Primitives.Test.Body.sync {}
        do throws(Test_Primitives.Test.Body.Error) {
            try await body.run()
        } catch {
            Issue.record("Expected sync body to succeed, got: \(error)")
        }
    }

    @Test
    func `async body run succeeds`() async throws {
        let body = Test_Primitives.Test.Body.async {}
        do throws(Test_Primitives.Test.Body.Error) {
            try await body.run()
        } catch {
            Issue.record("Expected async body to succeed, got: \(error)")
        }
    }

    @Test
    func `sync body catches thrown error`() async {
        struct TestError: Error, CustomStringConvertible {
            var description: String { "test failure" }
        }

        let body = Test_Primitives.Test.Body.sync { throw TestError() }
        do throws(Test_Primitives.Test.Body.Error) {
            try await body.run()
            Issue.record("Expected body.run() to throw")
        } catch {
            if case .caught(let type, let description) = error {
                #expect(type.contains("TestError"))
                #expect(description.contains("test failure"))
            } else {
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }

    @Test
    func `async body catches thrown error`() async {
        struct TestError: Error, CustomStringConvertible {
            var description: String { "async failure" }
        }

        let body = Test_Primitives.Test.Body.async { throw TestError() }
        do throws(Test_Primitives.Test.Body.Error) {
            try await body.run()
            Issue.record("Expected body.run() to throw")
        } catch {
            if case .caught(let type, let description) = error {
                #expect(type.contains("TestError"))
                #expect(description.contains("async failure"))
            } else {
                Issue.record("Unexpected error case: \(error)")
            }
        }
    }
}

// MARK: - EdgeCase

extension TestBodyTests.EdgeCase {
    @Test
    func `caught error stores type and description`() async {
        struct SpecificError: Error, CustomStringConvertible {
            let detail: String
            var description: String { "detail: \(detail)" }
        }

        let body = Test_Primitives.Test.Body.sync { throw SpecificError(detail: "abc123") }
        do throws(Test_Primitives.Test.Body.Error) {
            try await body.run()
        } catch {
            if case .caught(let type, let description) = error {
                #expect(type == "SpecificError")
                #expect(description.contains("abc123"))
            }
        }
    }
}
