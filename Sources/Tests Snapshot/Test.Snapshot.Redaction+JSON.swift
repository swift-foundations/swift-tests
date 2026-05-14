//
//  Test.Snapshot.Redaction+JSON.swift
//  swift-tests
//
//  JSON-aware redaction constructors for snapshot testing.
//

public import Test_Primitives
import JSON

// MARK: - JSON Path Redaction

extension Test.Snapshot.Redaction where Format == Swift.String {
    /// Redacts a JSON key path with a static replacement.
    ///
    /// Navigates the JSON structure using a dot-separated path and replaces
    /// the value at that location with the given replacement string.
    ///
    /// ## Example
    ///
    /// ```swift
    /// assertSnapshot(
    ///     of: user,
    ///     as: .json,
    ///     redacting: [.json(path: "id", replacement: "[uuid]")]
    /// )
    /// ```
    ///
    /// Paths support array indexing with numeric segments:
    /// ```swift
    /// .json(path: "users.0.id", replacement: "[uuid]")
    /// ```
    ///
    /// - Parameters:
    ///   - path: Dot-separated key path (e.g., "user.id", "meta.created_at").
    ///   - replacement: Static string to insert at the matched location.
    /// - Returns: A redaction that replaces the value at the given path.
    public static func json(
        path: Swift.String,
        replacement: Swift.String
    ) -> Self {
        let segments = path.split(separator: ".").map(Swift.String.init)
        return Self { jsonString in
            _redactJSON(jsonString, at: segments, replacement: .string(replacement))
        }
    }

    /// Redacts a JSON key path with a dynamic replacement.
    ///
    /// The replacement closure receives the current value as a string and
    /// returns the replacement.
    ///
    /// ## Example
    ///
    /// ```swift
    /// .json(path: "timestamp") { value in
    ///     "[timestamp:\(value.count) chars]"
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - path: Dot-separated key path.
    ///   - replacement: Closure producing a replacement from the current value.
    /// - Returns: A redaction that applies the dynamic replacement at the path.
    public static func json(
        path: Swift.String,
        replacement: @escaping @Sendable (Swift.String) -> Swift.String
    ) -> Self {
        let segments = path.split(separator: ".").map(Swift.String.init)
        return Self { jsonString in
            _redactJSON(jsonString, at: segments, dynamicReplacement: replacement)
        }
    }

    /// Redacts all JSON keys matching a glob pattern.
    ///
    /// Supports `**` for recursive descent and `*` for single-level wildcard.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Redact all "created_at" keys at any depth
    /// .json(glob: "**.created_at", replacement: "[timestamp]")
    ///
    /// // Redact all keys one level under "meta"
    /// .json(glob: "meta.*", replacement: "[redacted]")
    /// ```
    ///
    /// - Parameters:
    ///   - pattern: Glob pattern with `.` as separator.
    ///   - replacement: Static replacement string.
    /// - Returns: A redaction that replaces all matching values.
    public static func json(
        glob pattern: Swift.String,
        replacement: Swift.String
    ) -> Self {
        let segments = pattern.split(separator: ".").map(Swift.String.init)
        return Self { jsonString in
            _redactJSONGlob(jsonString, pattern: segments, replacement: replacement)
        }
    }
}

// MARK: - Internal Helpers

/// Parses a JSON string, applies a path-based replacement, and re-serializes.
private func _redactJSON(
    _ jsonString: Swift.String,
    at path: [Swift.String],
    replacement: RFC_8259.Value
) -> Swift.String {
    guard let value = try? JSON.Decode.parse(jsonString) else { return jsonString }
    let modified = _replaceAtPath(value, path: path[...], replacement: replacement)
    return JSON(modified).serialize(pretty: true, sortKeys: true)
}

/// Parses a JSON string, applies a dynamic path-based replacement, and re-serializes.
private func _redactJSON(
    _ jsonString: Swift.String,
    at path: [Swift.String],
    dynamicReplacement: (Swift.String) -> Swift.String
) -> Swift.String {
    guard let value = try? JSON.Decode.parse(jsonString) else { return jsonString }
    let modified = _replaceAtPathDynamic(value, path: path[...], replacement: dynamicReplacement)
    return JSON(modified).serialize(pretty: true, sortKeys: true)
}

/// Parses a JSON string, applies glob-based replacement, and re-serializes.
private func _redactJSONGlob(
    _ jsonString: Swift.String,
    pattern: [Swift.String],
    replacement: Swift.String
) -> Swift.String {
    guard let value = try? JSON.Decode.parse(jsonString) else { return jsonString }
    let modified = _replaceGlob(value, pattern: pattern[...], replacement: .string(replacement))
    return JSON(modified).serialize(pretty: true, sortKeys: true)
}

// MARK: - Object/Array Mutation Helpers

/// Creates a new Object with one key's value replaced.
private func _objectReplacing(
    _ obj: RFC_8259.Object,
    key: Swift.String,
    value: RFC_8259.Value
) -> RFC_8259.Object {
    var mutable = obj
    mutable[key] = value
    return mutable
}

/// Creates a new Array with one index's value replaced.
private func _arrayReplacing(
    _ arr: RFC_8259.Array,
    index: Int,
    value: RFC_8259.Value
) -> RFC_8259.Array {
    var mutable = arr
    mutable[index] = value
    return mutable
}

// MARK: - Path-Based Replacement

/// Recursively navigates an RFC_8259.Value and replaces the leaf at the path.
private func _replaceAtPath(
    _ value: RFC_8259.Value,
    path: ArraySlice<Swift.String>,
    replacement: RFC_8259.Value
) -> RFC_8259.Value {
    guard let segment = path.first else {
        return replacement
    }

    let remaining = path.dropFirst()

    switch value {
    case .object(let obj):
        guard let existing = obj[segment] else { return value }
        let replaced = _replaceAtPath(existing, path: remaining, replacement: replacement)
        return .object(_objectReplacing(obj, key: segment, value: replaced))

    case .array(let arr):
        if let idx = Int(segment), arr.indices.contains(idx) {
            let replaced = _replaceAtPath(arr[idx], path: remaining, replacement: replacement)
            return .array(_arrayReplacing(arr, index: idx, value: replaced))
        }
        return value

    default:
        return value
    }
}

/// Recursively navigates and applies a dynamic replacement at the path.
private func _replaceAtPathDynamic(
    _ value: RFC_8259.Value,
    path: ArraySlice<Swift.String>,
    replacement: (Swift.String) -> Swift.String
) -> RFC_8259.Value {
    guard let segment = path.first else {
        let currentString: Swift.String
        switch value {
        case .string(let s): currentString = s
        case .number(let n): currentString = "\(n)"
        case .bool(let b): currentString = "\(b)"
        case .null: currentString = "null"
        default: currentString = "\(value)"
        }
        return .string(replacement(currentString))
    }

    let remaining = path.dropFirst()

    switch value {
    case .object(let obj):
        guard let existing = obj[segment] else { return value }
        let replaced = _replaceAtPathDynamic(existing, path: remaining, replacement: replacement)
        return .object(_objectReplacing(obj, key: segment, value: replaced))

    case .array(let arr):
        if let idx = Int(segment), arr.indices.contains(idx) {
            let replaced = _replaceAtPathDynamic(arr[idx], path: remaining, replacement: replacement)
            return .array(_arrayReplacing(arr, index: idx, value: replaced))
        }
        return value

    default:
        return value
    }
}

// MARK: - Glob-Based Replacement

/// Recursively matches a glob pattern against the JSON tree structure.
private func _replaceGlob(
    _ value: RFC_8259.Value,
    pattern: ArraySlice<Swift.String>,
    replacement: RFC_8259.Value
) -> RFC_8259.Value {
    guard let segment = pattern.first else {
        return replacement
    }

    let remaining = pattern.dropFirst()

    if segment == "**" {
        // Recursive descent: try matching remaining pattern at this level,
        // AND propagate the full pattern (including **) into children.
        var result = _replaceGlob(value, pattern: remaining, replacement: replacement)

        switch result {
        case .object(let obj):
            var newPairs: [(key: Swift.String, value: RFC_8259.Value)] = []
            for (key, childValue) in obj {
                newPairs.append((key: key, value: _replaceGlob(childValue, pattern: pattern, replacement: replacement)))
            }
            result = .object(RFC_8259.Object(newPairs))

        case .array(let arr):
            var newElements: [RFC_8259.Value] = []
            for element in arr {
                newElements.append(_replaceGlob(element, pattern: pattern, replacement: replacement))
            }
            result = .array(RFC_8259.Array(newElements))

        default:
            break
        }

        return result
    }

    if segment == "*" {
        // Single-level wildcard: match all keys/indices at this level.
        switch value {
        case .object(let obj):
            var newPairs: [(key: Swift.String, value: RFC_8259.Value)] = []
            for (key, childValue) in obj {
                newPairs.append((key: key, value: _replaceGlob(childValue, pattern: remaining, replacement: replacement)))
            }
            return .object(RFC_8259.Object(newPairs))

        case .array(let arr):
            var newElements: [RFC_8259.Value] = []
            for element in arr {
                newElements.append(_replaceGlob(element, pattern: remaining, replacement: replacement))
            }
            return .array(RFC_8259.Array(newElements))

        default:
            return value
        }
    }

    // Literal key match
    switch value {
    case .object(let obj):
        guard let existing = obj[segment] else { return value }
        let replaced = _replaceGlob(existing, pattern: remaining, replacement: replacement)
        return .object(_objectReplacing(obj, key: segment, value: replaced))

    case .array(let arr):
        if let idx = Int(segment), arr.indices.contains(idx) {
            let replaced = _replaceGlob(arr[idx], pattern: remaining, replacement: replacement)
            return .array(_arrayReplacing(arr, index: idx, value: replaced))
        }
        return value

    default:
        return value
    }
}
