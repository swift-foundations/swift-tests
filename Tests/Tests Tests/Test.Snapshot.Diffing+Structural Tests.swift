import Testing
import Tests_Test_Support

// NOTE: Test.Snapshot.Diffing<Format> is generic — the [SWIFT-TEST-002]
// extension pattern is a hard compiler error here, so [SWIFT-TEST-003]'s
// backticked top-level parallel namespace applies instead.
@Suite
struct `Test.Snapshot.Diffing+Structural Tests` {
    @Suite struct Unit {}
    @Suite struct Integration {}
}

extension `Test.Snapshot.Diffing+Structural Tests`.Unit {

    @Test func `identical JSON returns nil diff`() {
        let diffing = Test_Primitives.Test.Snapshot.Diffing<Swift.String>.structuralJSON
        let result = diffing.diff(
            #"{"name":"Alice","age":30}"#,
            #"{"name":"Alice","age":30}"#
        )
        #expect(result == nil)
    }

    @Test func `added key produces structural operation`() {
        let diffing = Test_Primitives.Test.Snapshot.Diffing<Swift.String>.structuralJSON
        let result = diffing.diff(
            #"{"name":"Alice"}"#,
            #"{"name":"Alice","email":"a@b.com"}"#
        )
        #expect(result != nil)
        #expect(result?.structuralOperations != nil)
        let ops = result!.structuralOperations!
        let added = ops.filter {
            if case .added = $0 { return true }
            return false
        }
        #expect(added.count == 1)
        if case .added(let path, let value) = added.first {
            #expect(path == "email")
            #expect(value == #""a@b.com""#)
        }
    }

    @Test func `removed key produces structural operation`() {
        let diffing = Test_Primitives.Test.Snapshot.Diffing<Swift.String>.structuralJSON
        let result = diffing.diff(
            #"{"name":"Alice","age":30}"#,
            #"{"name":"Alice"}"#
        )
        #expect(result != nil)
        let ops = result!.structuralOperations!
        let removed = ops.filter {
            if case .removed = $0 { return true }
            return false
        }
        #expect(removed.count == 1)
        if case .removed(let path, let value) = removed.first {
            #expect(path == "age")
            #expect(value == "30")
        }
    }

    @Test func `modified value produces structural operation`() {
        let diffing = Test_Primitives.Test.Snapshot.Diffing<Swift.String>.structuralJSON
        let result = diffing.diff(
            #"{"name":"Alice"}"#,
            #"{"name":"Bob"}"#
        )
        #expect(result != nil)
        let ops = result!.structuralOperations!
        #expect(ops.count == 1)
        if case .modified(let path, let old, let new) = ops.first {
            #expect(path == "name")
            #expect(old == #""Alice""#)
            #expect(new == #""Bob""#)
        }
    }

    @Test func `nested change produces correct path`() {
        let diffing = Test_Primitives.Test.Snapshot.Diffing<Swift.String>.structuralJSON
        let result = diffing.diff(
            #"{"user":{"name":"Alice"}}"#,
            #"{"user":{"name":"Bob"}}"#
        )
        #expect(result != nil)
        let ops = result!.structuralOperations!
        #expect(ops.count == 1)
        if case .modified(let path, _, _) = ops.first {
            #expect(path == "user.name")
        }
    }

    @Test func `array element change uses index notation`() {
        let diffing = Test_Primitives.Test.Snapshot.Diffing<Swift.String>.structuralJSON
        let result = diffing.diff(
            #"{"items":["apple","banana"]}"#,
            #"{"items":["apple","cherry"]}"#
        )
        #expect(result != nil)
        let ops = result!.structuralOperations!
        let modified = ops.filter {
            if case .modified = $0 { return true }
            return false
        }
        #expect(modified.count >= 1)
        if case .modified(let path, _, _) = modified.first {
            #expect(path.contains("[1]"))
        }
    }

    @Test func `invalid JSON falls back to line diff`() {
        let diffing = Test_Primitives.Test.Snapshot.Diffing<Swift.String>.structuralJSON
        let result = diffing.diff(
            "not json\nline 2",
            "not json\nline 3"
        )
        #expect(result != nil)
        #expect(result?.structuralOperations == nil)
        #expect(!result!.summary.isEmpty)
    }

    @Test func `summary format shows count and operations`() {
        let diffing = Test_Primitives.Test.Snapshot.Diffing<Swift.String>.structuralJSON
        let result = diffing.diff(
            #"{"a":1,"b":2}"#,
            #"{"a":1,"b":3,"c":4}"#
        )
        #expect(result != nil)
        #expect(result!.summary.contains("structural change"))
        #expect(result!.summary.contains("~") || result!.summary.contains("+"))
    }
}

extension `Test.Snapshot.Diffing+Structural Tests`.Integration {

    @Test func `structuralJSON strategy has json extension`() {
        let strategy = Test_Primitives.Test.Snapshot.Strategy<Swift.String, Swift.String>.structuralJSON
        #expect(strategy.pathExtension == "json")
    }

    @Test func `structuralJSON strategy is synchronous`() {
        let strategy = Test_Primitives.Test.Snapshot.Strategy<Swift.String, Swift.String>.structuralJSON
        #expect(strategy.isSynchronous)
    }

    @Test func `structuralJSON strategy captures JSON string`() {
        let strategy = Test_Primitives.Test.Snapshot.Strategy<Swift.String, Swift.String>.structuralJSON
        let captured = strategy.syncSnapshot!("raw input")
        #expect(!captured.isEmpty)
    }

    @Test func `structuralJSON diffing serializes to bytes and back`() {
        let diffing = Test_Primitives.Test.Snapshot.Diffing<Swift.String>.structuralJSON
        let original = #"{"key":"value"}"#
        let bytes = diffing.toBytes(original)
        let roundtripped = diffing.fromBytes(bytes)
        #expect(roundtripped == original)
    }
}
