//
//  Test.Snapshot.Strategy+JSON.Structural.swift
//  swift-tests
//
//  JSON snapshot strategy with structural (tree-aware) diffing.
//

public import JSON
public import Test_Primitives

// MARK: - Structural JSON Strategy (JSON.Serializable)

extension Test.Snapshot.Strategy where Value: JSON.Serializable & Sendable, Format == Swift.String {
    /// JSON strategy with structural diffing.
    ///
    /// Serializes values using `JSON.Serializable` and compares using
    /// tree-aware structural diffing instead of line-based comparison.
    /// Produces semantic diff output showing exactly which keys changed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// assertSnapshot(capturing: user, as: .structuralJSON)
    /// ```
    ///
    /// ## Diff Output
    ///
    /// ```
    /// 2 structural changes:
    /// ~ name: "Alice" → "Bob"
    /// + email: "alice@example.com"
    /// ```
    ///
    /// File extension: `.json`
    public static var structuralJSON: Self {
        structuralJSON()
    }

    /// JSON strategy with structural diffing and custom formatting.
    ///
    /// - Parameters:
    ///   - pretty: Whether to pretty-print the serialized output.
    ///   - sortKeys: Whether to sort keys alphabetically.
    /// - Returns: A JSON strategy using structural diffing.
    public static func structuralJSON(
        pretty: Bool = true,
        sortKeys: Bool = true
    ) -> Self {
        Test.Snapshot.Strategy(
            pathExtension: "json",
            diffing: .structuralJSON(sortKeys: sortKeys, pretty: pretty),
            snapshot: { value in
                value.jsonString(pretty: pretty, sortKeys: sortKeys)
            }
        )
    }
}

// MARK: - Structural JSON Strategy (Raw JSON)

extension Test.Snapshot.Strategy where Value == JSON, Format == Swift.String {
    /// JSON strategy with structural diffing for raw `JSON` values.
    ///
    /// File extension: `.json`
    public static var structuralJSON: Self {
        structuralJSON()
    }

    /// JSON strategy with structural diffing for raw `JSON` values.
    ///
    /// - Parameters:
    ///   - pretty: Whether to pretty-print the serialized output.
    ///   - sortKeys: Whether to sort keys alphabetically.
    /// - Returns: A JSON strategy using structural diffing.
    public static func structuralJSON(
        pretty: Bool = true,
        sortKeys: Bool = true
    ) -> Self {
        Test.Snapshot.Strategy(
            pathExtension: "json",
            diffing: .structuralJSON(sortKeys: sortKeys, pretty: pretty),
            snapshot: { json in
                json.serialize(pretty: pretty, sortKeys: sortKeys)
            }
        )
    }
}
