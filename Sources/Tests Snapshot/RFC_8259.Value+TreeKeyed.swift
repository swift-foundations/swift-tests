//
//  RFC_8259.Value+TreeKeyed.swift
//  swift-tests
//
//  Bidirectional conversion between JSON values and keyed trees.
//

import JSON

// MARK: - JSON → Tree<RFC_8259.Value>.Keyed

/// Converts an RFC 8259 value to a keyed tree for structural comparison.
///
/// Container nodes (objects, arrays) store an empty marker as their value.
/// Children carry the actual content. Scalars become leaf nodes with
/// their value stored directly.
///
/// Object keys map to tree child keys directly. Array elements use
/// their string index ("0", "1", ...) as the child key.
func _jsonToKeyedTree(_ value: RFC_8259.Value) -> Tree<RFC_8259.Value>.Keyed<Swift.String> {
    var tree = Tree<RFC_8259.Value>.Keyed<Swift.String>()

    let rootPos = try! tree.insert(_jsonLocalValue(value), at: .root)

    var pending: [(parent: Tree<RFC_8259.Value>.Position, key: Swift.String, value: RFC_8259.Value)] = []
    _jsonAppendChildren(of: value, parent: rootPos, to: &pending)

    while let (parent, key, childValue) = pending.popLast() {
        let childPos = try! tree.insert(
            _jsonLocalValue(childValue),
            at: .child(of: parent, key: key)
        )
        _jsonAppendChildren(of: childValue, parent: childPos, to: &pending)
    }

    return tree
}

// MARK: - Helpers

/// Returns the local value for a JSON node — containers become empty markers.
private func _jsonLocalValue(_ value: RFC_8259.Value) -> RFC_8259.Value {
    switch value {
    case .object: .object(.init())
    case .array: .array(.init())
    default: value
    }
}

/// Appends child entries for containers onto the pending stack.
private func _jsonAppendChildren(
    of value: RFC_8259.Value,
    parent: Tree<RFC_8259.Value>.Position,
    to pending: inout [(parent: Tree<RFC_8259.Value>.Position, key: Swift.String, value: RFC_8259.Value)]
) {
    switch value {
    case .object(let obj):
        for (key, childValue) in obj {
            pending.append((parent, key, childValue))
        }
    case .array(let arr):
        for (index, childValue) in arr.enumerated() {
            pending.append((parent, Swift.String(index), childValue))
        }
    default:
        break
    }
}

// MARK: - Value Formatting

/// Formats an RFC 8259 value as a display string for diff output.
func _jsonDisplayValue(_ value: RFC_8259.Value) -> Swift.String {
    switch value {
    case .null: "null"
    case .bool(let b): "\(b)"
    case .number(let n): "\(n)"
    case .string(let s): "\"\(s)\""
    case .object: "{...}"
    case .array: "[...]"
    }
}

/// Whether a JSON value is a container (object or array).
func _jsonIsContainer(_ value: RFC_8259.Value) -> Bool {
    switch value {
    case .object, .array: true
    default: false
    }
}

// MARK: - Path Formatting

/// Formats a key path as a dot-separated string with array index notation.
///
/// - `["user", "name"]` → `"user.name"`
/// - `["items", "0", "name"]` → `"items[0].name"`
/// - `[]` → `"(root)"`
func _jsonFormatPath(_ path: [Swift.String]) -> Swift.String {
    guard !path.isEmpty else { return "(root)" }

    var result = ""
    for (index, segment) in path.enumerated() {
        if Int(segment) != nil {
            result += "[\(segment)]"
        } else {
            if index > 0 {
                result += "."
            }
            result += segment
        }
    }
    return result
}
