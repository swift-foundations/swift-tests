//
//  Test.Snapshot.Faceted.verify.swift
//  swift-tests
//
//  Faceted snapshot verification functions.
//

public import Test_Primitives

// MARK: - verifyFacetedSnapshot (Synchronous)

/// Verifies that a value matches all facets of a faceted snapshot.
///
/// Returns the first failure message encountered, or `nil` if all facets match.
///
/// The primary strategy verifies against a file-based reference. Each facet
/// verifies against either an inline expected value (if provided in `matches`)
/// or a file-based reference with a `.facetName` name suffix.
///
/// - Parameters:
///   - value: The value to snapshot.
///   - faceted: The faceted snapshot configuration.
///   - name: Optional base name for the snapshot files.
///   - recording: Recording mode override.
///   - matches: Inline expected values keyed by facet name.
///   - filePath: Source path (captured automatically).
///   - line: Source line (captured automatically).
///   - column: Source column (captured automatically).
///   - function: Test function name (captured automatically).
/// - Returns: `nil` if all facets match, or an error message describing the first failure.
public func verifyFacetedSnapshot<Value: Sendable>(
    of value: Value,
    as faceted: Test.Snapshot.Faceted<Value>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    matches: [Swift.String: () -> Swift.String] = [:],
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) -> Swift.String? {
    // Verify primary strategy against file-based reference.
    let primaryFailure = verifySnapshot(
        capturing: value,
        as: faceted.primary,
        named: name,
        record: recording,
        filePath: filePath,
        function: function
    )

    if let primaryFailure {
        return "[primary] \(primaryFailure)"
    }

    // Verify each facet.
    for (facetName, facetStrategy) in faceted.facets {
        if let expectedClosure = matches[facetName] {
            // Inline verification for this facet.
            let facetFailure = verifyInlineSnapshot(
                of: value,
                as: facetStrategy,
                record: recording,
                matches: expectedClosure,
                filePath: filePath,
                line: line,
                column: column,
                function: function
            )
            if let facetFailure {
                return "[\(facetName)] \(facetFailure)"
            }
        } else {
            // File-based verification with facet name suffix.
            let facetFullName: Swift.String
            if let name {
                facetFullName = "\(name).\(facetName)"
            } else {
                facetFullName = facetName
            }
            let facetFailure = verifySnapshot(
                capturing: value,
                as: facetStrategy,
                named: facetFullName,
                record: recording,
                filePath: filePath,
                function: function
            )
            if let facetFailure {
                return "[\(facetName)] \(facetFailure)"
            }
        }
    }

    return nil
}

// MARK: - verifyFacetedSnapshot (Asynchronous)

/// Verifies that a value matches all facets of a faceted snapshot (async variant).
///
/// - Parameters:
///   - value: The value to snapshot.
///   - faceted: The faceted snapshot configuration.
///   - name: Optional base name for the snapshot files.
///   - recording: Recording mode override.
///   - matches: Inline expected values keyed by facet name.
///   - filePath: Source path (captured automatically).
///   - line: Source line (captured automatically).
///   - column: Source column (captured automatically).
///   - function: Test function name (captured automatically).
/// - Returns: `nil` if all facets match, or an error message describing the first failure.
public func verifyFacetedSnapshot<Value: Sendable>(
    of value: Value,
    as faceted: Test.Snapshot.Faceted<Value>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    matches: [Swift.String: () -> Swift.String] = [:],
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) async -> Swift.String? {
    // Verify primary strategy against file-based reference.
    let primaryFailure = await verifySnapshot(
        capturing: value,
        as: faceted.primary,
        named: name,
        record: recording,
        filePath: filePath,
        function: function
    )

    if let primaryFailure {
        return "[primary] \(primaryFailure)"
    }

    // Verify each facet.
    for (facetName, facetStrategy) in faceted.facets {
        if let expectedClosure = matches[facetName] {
            // Inline verification for this facet.
            let facetFailure = await verifyInlineSnapshot(
                of: value,
                as: facetStrategy,
                record: recording,
                matches: expectedClosure,
                filePath: filePath,
                line: line,
                column: column,
                function: function
            )
            if let facetFailure {
                return "[\(facetName)] \(facetFailure)"
            }
        } else {
            // File-based verification with facet name suffix.
            let facetFullName: Swift.String
            if let name {
                facetFullName = "\(name).\(facetName)"
            } else {
                facetFullName = facetName
            }
            let facetFailure = await verifySnapshot(
                capturing: value,
                as: facetStrategy,
                named: facetFullName,
                record: recording,
                filePath: filePath,
                function: function
            )
            if let facetFailure {
                return "[\(facetName)] \(facetFailure)"
            }
        }
    }

    return nil
}
