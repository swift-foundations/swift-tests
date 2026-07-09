import Testing
import Tests_Test_Support

// NOTE: Test.Snapshot.Redaction<Format> is generic — the [SWIFT-TEST-002]
// extension pattern is a hard compiler error here, so [SWIFT-TEST-003]'s
// backticked top-level parallel namespace applies instead.
@Suite
struct `Test.Snapshot.Redaction+JSON Tests` {
    @Suite struct Unit {}
}

extension `Test.Snapshot.Redaction+JSON Tests`.Unit {

    @Test func `json path replaces simple key`() {
        let redaction = Test_Primitives.Test.Snapshot.Redaction<Swift.String>.json(
            path: "id",
            replacement: "[id]"
        )
        let input = #"{"id":"abc-123","name":"Alice"}"#
        let output = redaction.apply(input)
        #expect(output.contains("\"[id]\""))
        #expect(!output.contains("abc-123"))
    }

    @Test func `json path replaces nested key`() {
        let redaction = Test_Primitives.Test.Snapshot.Redaction<Swift.String>.json(
            path: "user.id",
            replacement: "[uuid]"
        )
        let input = #"{"user":{"id":"abc","name":"Alice"}}"#
        let output = redaction.apply(input)
        #expect(output.contains("\"[uuid]\""))
        #expect(!output.contains("abc"))
    }

    @Test func `json path replaces array element`() {
        let redaction = Test_Primitives.Test.Snapshot.Redaction<Swift.String>.json(
            path: "items.0",
            replacement: "[first]"
        )
        let input = #"{"items":["apple","banana"]}"#
        let output = redaction.apply(input)
        #expect(output.contains("\"[first]\""))
        #expect(!output.contains("apple"))
        #expect(output.contains("banana"))
    }

    @Test func `json glob replaces recursive descent`() {
        let redaction = Test_Primitives.Test.Snapshot.Redaction<Swift.String>.json(
            glob: "**.created_at",
            replacement: "[timestamp]"
        )
        let input = #"{"user":{"created_at":"2024-01-01"},"post":{"created_at":"2024-06-15"}}"#
        let output = redaction.apply(input)
        #expect(!output.contains("2024-01-01"))
        #expect(!output.contains("2024-06-15"))
        #expect(output.contains("\"[timestamp]\""))
    }

    @Test func `json glob replaces single level wildcard`() {
        let redaction = Test_Primitives.Test.Snapshot.Redaction<Swift.String>.json(
            glob: "meta.*",
            replacement: "[redacted]"
        )
        let input = #"{"meta":{"a":"1","b":"2"},"data":"keep"}"#
        let output = redaction.apply(input)
        #expect(output.contains("\"[redacted]\""))
        #expect(output.contains("keep"))
    }

    @Test func `json dynamic replacement receives current value`() {
        let redaction = Test_Primitives.Test.Snapshot.Redaction<Swift.String>.json(
            path: "count"
        ) { value in
            "[was:\(value)]"
        }
        let input = #"{"count":42}"#
        let output = redaction.apply(input)
        #expect(output.contains("[was:42]"))
    }

    @Test func `json path on missing key returns unchanged`() {
        let redaction = Test_Primitives.Test.Snapshot.Redaction<Swift.String>.json(
            path: "nonexistent.key",
            replacement: "[replaced]"
        )
        let input = #"{"name":"Alice"}"#
        let output = redaction.apply(input)
        #expect(output.contains("Alice"))
        #expect(!output.contains("[replaced]"))
    }

    @Test func `json redaction on invalid JSON returns input unchanged`() {
        let redaction = Test_Primitives.Test.Snapshot.Redaction<Swift.String>.json(
            path: "id",
            replacement: "[id]"
        )
        let input = "not valid json {"
        let output = redaction.apply(input)
        #expect(output == input)
    }
}
