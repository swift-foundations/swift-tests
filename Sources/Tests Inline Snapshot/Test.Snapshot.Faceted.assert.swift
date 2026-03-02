//
//  Test.Snapshot.Faceted.assert.swift
//  swift-tests
//
//  Faceted snapshot assertion functions.
//

public import Test_Primitives

// MARK: - assertFacetedSnapshot (Synchronous)

/// Asserts that a value matches all facets of a faceted snapshot.
///
/// The primary strategy asserts against a file-based reference snapshot.
/// Each facet asserts against either an inline expected value (if provided
/// in `matches`) or a file-based reference with a `.facetName` suffix.
///
/// ## Example
///
/// ```swift
/// let faceted = Test.Snapshot.Faceted<Document>(
///     primary: .fullHTML,
///     facets: [
///         ("text", .textContent),
///         ("links", .linkList),
///     ]
/// )
///
/// assertFacetedSnapshot(
///     of: document,
///     as: faceted,
///     matches: [
///         "text": { "Hello, World!" },
///     ]
/// )
/// ```
///
/// - Parameters:
///   - value: The value to snapshot.
///   - faceted: The faceted snapshot configuration.
///   - name: Optional base name for the snapshot files.
///   - recording: Recording mode override.
///   - matches: Inline expected values keyed by facet name.
///   - fileID: Source file ID (captured automatically).
///   - filePath: Source path (captured automatically).
///   - line: Source line (captured automatically).
///   - column: Source column (captured automatically).
///   - function: Test function name (captured automatically).
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertFacetedSnapshot<Value: Sendable>(
    of value: Value,
    as faceted: Test.Snapshot.Faceted<Value>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    matches: [Swift.String: () -> Swift.String] = [:],
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) -> Test.Expectation {
    let location = Source.Location(fileID: fileID, filePath: filePath, line: line, column: column)

    if let failure = verifyFacetedSnapshot(
        of: value,
        as: faceted,
        named: name,
        record: recording,
        matches: matches,
        filePath: filePath,
        line: line,
        column: column,
        function: function
    ) {
        return .record(
            failing: failure,
            sourceCode: "assertFacetedSnapshot(of: ..., as: ...)",
            at: location
        )
    }

    return .record(
        passing: "assertFacetedSnapshot(of: ..., as: ...)",
        at: location
    )
}

// MARK: - assertFacetedSnapshot (Asynchronous)

/// Asserts that a value matches all facets of a faceted snapshot (async variant).
///
/// - Parameters:
///   - value: The value to snapshot.
///   - faceted: The faceted snapshot configuration.
///   - name: Optional base name for the snapshot files.
///   - recording: Recording mode override.
///   - matches: Inline expected values keyed by facet name.
///   - fileID: Source file ID (captured automatically).
///   - filePath: Source path (captured automatically).
///   - line: Source line (captured automatically).
///   - column: Source column (captured automatically).
///   - function: Test function name (captured automatically).
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertFacetedSnapshot<Value: Sendable>(
    of value: Value,
    as faceted: Test.Snapshot.Faceted<Value>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    matches: [Swift.String: () -> Swift.String] = [:],
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) async -> Test.Expectation {
    let location = Source.Location(fileID: fileID, filePath: filePath, line: line, column: column)

    if let failure = await verifyFacetedSnapshot(
        of: value,
        as: faceted,
        named: name,
        record: recording,
        matches: matches,
        filePath: filePath,
        line: line,
        column: column,
        function: function
    ) {
        return .record(
            failing: failure,
            sourceCode: "assertFacetedSnapshot(of: ..., as: ...)",
            at: location
        )
    }

    return .record(
        passing: "assertFacetedSnapshot(of: ..., as: ...)",
        at: location
    )
}
