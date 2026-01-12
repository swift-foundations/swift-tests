//
//  Test.Snapshot.Strategy+JSON.swift
//  swift-tests
//
//  JSON snapshot strategy using swift-json.
//

public import Test_Primitives
public import JSON

// MARK: - JSON Strategy

extension Test.Snapshot.Strategy where Value: JSON.Serializable, Format == String {
    /// JSON snapshot strategy with sorted keys and pretty printing.
    ///
    /// Serializes values conforming to `JSON.Serializable` with deterministic output:
    /// - Pretty printed with indentation
    /// - Keys sorted alphabetically for stable diffs
    ///
    /// File extension: `.json`
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct User: JSON.Serializable {
    ///     let name: String
    ///     let age: Int
    ///
    ///     static func serialize(_ value: User) -> JSON {
    ///         [
    ///             "name": .string(value.name),
    ///             "age": .number(value.age)
    ///         ]
    ///     }
    ///
    ///     static func deserialize(_ json: JSON) throws(JSON.Error) -> User {
    ///         User(
    ///             name: try json["name"].require().string ?? "",
    ///             age: try json["age"].require().int ?? 0
    ///         )
    ///     }
    /// }
    ///
    /// @Test
    /// func testUserSnapshot() {
    ///     let user = User(name: "Alice", age: 30)
    ///     expectSnapshot(of: user, as: .json)
    /// }
    /// ```
    ///
    /// ## Output Format
    ///
    /// ```json
    /// {
    ///   "age": 30,
    ///   "name": "Alice"
    /// }
    /// ```
    public static var json: Self {
        Test.Snapshot.Strategy(
            pathExtension: "json",
            diffing: Test.Snapshot.Diffing.lines,
            snapshot: { value in
                value.jsonString(pretty: true, sortKeys: true)
            }
        )
    }

    /// JSON snapshot strategy with custom formatting options.
    ///
    /// - Parameters:
    ///   - pretty: Whether to format with indentation. Default: `true`.
    ///   - sortKeys: Whether to sort keys alphabetically. Default: `true`.
    /// - Returns: A JSON snapshot strategy with the specified options.
    public static func json(pretty: Bool = true, sortKeys: Bool = true) -> Self {
        Test.Snapshot.Strategy(
            pathExtension: "json",
            diffing: Test.Snapshot.Diffing.lines,
            snapshot: { value in
                value.jsonString(pretty: pretty, sortKeys: sortKeys)
            }
        )
    }
}

// MARK: - Raw JSON Strategy

extension Test.Snapshot.Strategy where Value == JSON, Format == String {
    /// JSON snapshot strategy for raw JSON values.
    ///
    /// Use this when you already have a `JSON` value and want to snapshot it.
    ///
    /// File extension: `.json`
    public static var json: Self {
        Test.Snapshot.Strategy(
            pathExtension: "json",
            diffing: Test.Snapshot.Diffing.lines,
            snapshot: { json in
                json.serialize(pretty: true, sortKeys: true)
            }
        )
    }

    /// JSON snapshot strategy for raw JSON with custom formatting.
    ///
    /// - Parameters:
    ///   - pretty: Whether to format with indentation.
    ///   - sortKeys: Whether to sort keys alphabetically.
    /// - Returns: A JSON snapshot strategy with the specified options.
    public static func json(pretty: Bool = true, sortKeys: Bool = true) -> Self {
        Test.Snapshot.Strategy(
            pathExtension: "json",
            diffing: Test.Snapshot.Diffing.lines,
            snapshot: { json in
                json.serialize(pretty: pretty, sortKeys: sortKeys)
            }
        )
    }
}
