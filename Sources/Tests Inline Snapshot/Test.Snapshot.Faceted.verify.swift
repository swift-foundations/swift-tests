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
    let mode = Test.Snapshot.Configuration.resolve(recording: recording)

    // Verify primary strategy against file-based reference.
    guard let syncSnapshot = faceted.primary.syncSnapshot else {
        return "[primary] Strategy does not support synchronous capture."
    }
    let primaryActual = syncSnapshot(value)
    let primaryName = name ?? "primary"

    if let failure = Test.Snapshot.Storage.resolve(
        actual: primaryActual,
        strategy: faceted.primary,
        name: primaryName,
        mode: mode,
        filePath: filePath,
        function: function
    ) {
        return "[primary] \(failure)"
    }

    // Verify each facet.
    for (facetName, facetStrategy) in faceted.facets {
        guard let syncFacet = facetStrategy.syncSnapshot else {
            return "[\(facetName)] Strategy does not support synchronous capture."
        }
        let facetActual = syncFacet(value)

        if let expectedClosure = matches[facetName] {
            // Inline verification for this facet.
            if let failure = Test.Snapshot.Inline.resolve(
                actual: facetActual,
                strategy: facetStrategy,
                expected: expectedClosure,
                mode: mode,
                filePath: filePath,
                line: line,
                column: column,
                function: function
            ) {
                return "[\(facetName)] \(failure)"
            }
        } else {
            // File-based verification with facet name suffix.
            let facetFullName = name.map { "\($0).\(facetName)" } ?? facetName
            if let failure = Test.Snapshot.Storage.resolve(
                actual: facetActual,
                strategy: facetStrategy,
                name: facetFullName,
                mode: mode,
                filePath: filePath,
                function: function
            ) {
                return "[\(facetName)] \(failure)"
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
    let mode = Test.Snapshot.Configuration.resolve(recording: recording)

    // Verify primary strategy against file-based reference.
    let primaryActual = await faceted.primary.capture(value)
    let primaryName = name ?? "primary"

    if let failure = Test.Snapshot.Storage.resolve(
        actual: primaryActual,
        strategy: faceted.primary,
        name: primaryName,
        mode: mode,
        filePath: filePath,
        function: function
    ) {
        return "[primary] \(failure)"
    }

    // Verify each facet.
    for (facetName, facetStrategy) in faceted.facets {
        let facetActual = await facetStrategy.capture(value)

        if let expectedClosure = matches[facetName] {
            // Inline verification for this facet.
            if let failure = Test.Snapshot.Inline.resolve(
                actual: facetActual,
                strategy: facetStrategy,
                expected: expectedClosure,
                mode: mode,
                filePath: filePath,
                line: line,
                column: column,
                function: function
            ) {
                return "[\(facetName)] \(failure)"
            }
        } else {
            // File-based verification with facet name suffix.
            let facetFullName = name.map { "\($0).\(facetName)" } ?? facetName
            if let failure = Test.Snapshot.Storage.resolve(
                actual: facetActual,
                strategy: facetStrategy,
                name: facetFullName,
                mode: mode,
                filePath: filePath,
                function: function
            ) {
                return "[\(facetName)] \(failure)"
            }
        }
    }

    return nil
}
