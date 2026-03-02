//
//  Test.Snapshot.Inline.assert.swift
//  swift-tests
//
//  Inline snapshot assertion functions.
//
//  API mirrors Point-Free's swift-snapshot-testing for drop-in compatibility:
//    assertInlineSnapshot(of: value, as: .lines) { "expected" }
//

public import Test_Primitives

// MARK: - assertInlineSnapshot (Synchronous, Captured Value)

/// Asserts that a value matches its inline snapshot.
///
/// On first run (or in record mode), registers the snapshot for deferred
/// source file rewriting and returns a failing expectation with instructions
/// to re-run. On subsequent runs, compares the captured value against the
/// expected value from the trailing closure.
///
/// The format is constrained to `Swift.String` — binary strategies cannot
/// be used with inline snapshots.
///
/// ## Example
///
/// ```swift
/// // First run — developer writes:
/// assertInlineSnapshot(of: user.description, as: .lines)
///
/// // Framework rewrites source to:
/// assertInlineSnapshot(of: user.description, as: .lines) {
///     """
///     User: Alice
///     Email: alice@example.com
///     """
/// }
/// ```
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value (String format only).
///   - recording: Recording mode override.
///   - expected: Trailing closure containing the expected value (inserted by rewriter).
///   - fileID: Source file ID (captured automatically).
///   - filePath: Source path (captured automatically).
///   - line: Source line (captured automatically).
///   - column: Source column (captured automatically).
///   - function: Test function name (captured automatically).
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertInlineSnapshot<Value: Sendable>(
    of value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
    matches expected: (() -> Swift.String)? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) -> Test.Expectation {
    let effectiveStrategy = redactions.isEmpty ? strategy : strategy.redacting(redactions)

    guard let syncSnapshot = effectiveStrategy.syncSnapshot else {
        return makeInlineFailingExpectation(
            message: "Strategy does not support synchronous capture. Use async assertInlineSnapshot.",
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    let failure = _verifyInlineSnapshot(
        of: value,
        syncSnapshot: syncSnapshot,
        strategy: effectiveStrategy,
        record: recording,
        expected: expected,
        filePath: filePath,
        line: line,
        column: column,
        function: function
    )

    if let failure {
        return makeInlineFailingExpectation(
            message: failure,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    return makeInlinePassingExpectation(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

// MARK: - assertInlineSnapshot (Synchronous, Autoclosure)

// WORKAROUND: @autoclosure () throws(E) -> Value has a fundamental E inference
// bug in Swift 6.2. See file-based assertSnapshot for details.
// TRACKING: https://github.com/swiftlang/swift/issues/75430

/// Asserts that a value matches its inline snapshot.
///
/// Autoclosure variant — the value expression is captured lazily.
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value (String format only).
///   - recording: Recording mode override.
///   - expected: Trailing closure containing the expected value.
///   - fileID: Source file ID.
///   - filePath: Source path.
///   - line: Source line.
///   - column: Source column.
///   - function: Test function name.
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertInlineSnapshot<Value: Sendable, E: Swift.Error>(
    of value: @autoclosure () throws(E) -> Value,
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
    matches expected: (() -> Swift.String)? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) -> Test.Expectation {
    do {
        let capturedValue = try value()
        let effectiveStrategy = redactions.isEmpty ? strategy : strategy.redacting(redactions)

        guard let syncSnapshot = effectiveStrategy.syncSnapshot else {
            return makeInlineFailingExpectation(
                message: "Strategy does not support synchronous capture. Use async assertInlineSnapshot.",
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        }

        let failure = _verifyInlineSnapshot(
            of: capturedValue,
            syncSnapshot: syncSnapshot,
            strategy: effectiveStrategy,
            record: recording,
            expected: expected,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )

        if let failure {
            return makeInlineFailingExpectation(
                message: failure,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        }

        return makeInlinePassingExpectation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    } catch {
        return makeInlineFailingExpectation(
            message: "Failed to capture value: \(error)",
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}

// MARK: - assertInlineSnapshot (Asynchronous, Captured Value)

/// Asserts that a value matches its inline snapshot (async variant).
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value (String format only).
///   - recording: Recording mode override.
///   - expected: Trailing closure containing the expected value.
///   - fileID: Source file ID.
///   - filePath: Source path.
///   - line: Source line.
///   - column: Source column.
///   - function: Test function name.
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertInlineSnapshot<Value: Sendable>(
    of value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
    matches expected: (() -> Swift.String)? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) async -> Test.Expectation {
    let effectiveStrategy = redactions.isEmpty ? strategy : strategy.redacting(redactions)

    let failure = await _verifyInlineSnapshotAsync(
        of: value,
        strategy: effectiveStrategy,
        record: recording,
        expected: expected,
        filePath: filePath,
        line: line,
        column: column,
        function: function
    )

    if let failure {
        return makeInlineFailingExpectation(
            message: failure,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    return makeInlinePassingExpectation(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

// MARK: - assertInlineSnapshot (Asynchronous, Autoclosure)

// WORKAROUND: See synchronous autoclosure variant above.
// TRACKING: https://github.com/swiftlang/swift/issues/75430

/// Asserts that a value matches its inline snapshot (async autoclosure variant).
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value (String format only).
///   - recording: Recording mode override.
///   - expected: Trailing closure containing the expected value.
///   - fileID: Source file ID.
///   - filePath: Source path.
///   - line: Source line.
///   - column: Source column.
///   - function: Test function name.
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertInlineSnapshot<Value: Sendable, E: Swift.Error>(
    of value: @autoclosure () throws(E) -> Value,
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
    matches expected: (() -> Swift.String)? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) async -> Test.Expectation {
    do {
        let capturedValue = try value()
        let effectiveStrategy = redactions.isEmpty ? strategy : strategy.redacting(redactions)

        let failure = await _verifyInlineSnapshotAsync(
            of: capturedValue,
            strategy: effectiveStrategy,
            record: recording,
            expected: expected,
            filePath: filePath,
            line: line,
            column: column,
            function: function
        )

        if let failure {
            return makeInlineFailingExpectation(
                message: failure,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        }

        return makeInlinePassingExpectation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    } catch {
        return makeInlineFailingExpectation(
            message: "Failed to capture value: \(error)",
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}

// MARK: - verifyInlineSnapshot (Captured Value)

/// Verifies that a value matches its inline snapshot, returning the failure
/// message if any.
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value (String format only).
///   - recording: Recording mode override.
///   - expected: Trailing closure containing the expected value.
///   - filePath: Source path.
///   - line: Source line.
///   - column: Source column.
///   - function: Test function name.
/// - Returns: `nil` if the snapshot matches, or an error message.
public func verifyInlineSnapshot<Value: Sendable>(
    of value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
    matches expected: (() -> Swift.String)? = nil,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) -> Swift.String? {
    let effectiveStrategy = redactions.isEmpty ? strategy : strategy.redacting(redactions)

    guard let syncSnapshot = effectiveStrategy.syncSnapshot else {
        return "Strategy does not support synchronous capture. Use async verifyInlineSnapshot."
    }

    return _verifyInlineSnapshot(
        of: value,
        syncSnapshot: syncSnapshot,
        strategy: effectiveStrategy,
        record: recording,
        expected: expected,
        filePath: filePath,
        line: line,
        column: column,
        function: function
    )
}

/// Verifies that a value matches its inline snapshot (async variant).
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value (String format only).
///   - recording: Recording mode override.
///   - expected: Trailing closure containing the expected value.
///   - filePath: Source path.
///   - line: Source line.
///   - column: Source column.
///   - function: Test function name.
/// - Returns: `nil` if the snapshot matches, or an error message.
public func verifyInlineSnapshot<Value: Sendable>(
    of value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
    matches expected: (() -> Swift.String)? = nil,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) async -> Swift.String? {
    let effectiveStrategy = redactions.isEmpty ? strategy : strategy.redacting(redactions)

    return await _verifyInlineSnapshotAsync(
        of: value,
        strategy: effectiveStrategy,
        record: recording,
        expected: expected,
        filePath: filePath,
        line: line,
        column: column,
        function: function
    )
}

// MARK: - Internal Implementation

/// Internal sync verification for inline snapshots.
private func _verifyInlineSnapshot<Value: Sendable>(
    of value: Value,
    syncSnapshot: @Sendable (Value) -> Swift.String,
    strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    record recording: Test.Snapshot.Recording?,
    expected: (() -> Swift.String)?,
    filePath: Swift.String,
    line: Int,
    column: Int,
    function: Swift.String
) -> Swift.String? {
    let mode = Test.Snapshot.Configuration.resolveRecording(explicit: recording)
    let actual = syncSnapshot(value)

    return _processInlineSnapshot(
        actual: actual,
        expected: expected,
        strategy: strategy,
        mode: mode,
        filePath: filePath,
        line: line,
        column: column,
        function: function
    )
}

/// Internal async verification for inline snapshots.
private func _verifyInlineSnapshotAsync<Value: Sendable>(
    of value: Value,
    strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    record recording: Test.Snapshot.Recording?,
    expected: (() -> Swift.String)?,
    filePath: Swift.String,
    line: Int,
    column: Int,
    function: Swift.String
) async -> Swift.String? {
    let mode = Test.Snapshot.Configuration.resolveRecording(explicit: recording)
    let actual = await strategy.capture(value)

    return _processInlineSnapshot(
        actual: actual,
        expected: expected,
        strategy: strategy,
        mode: mode,
        filePath: filePath,
        line: line,
        column: column,
        function: function
    )
}

/// Shared logic for processing an inline snapshot after capture.
private func _processInlineSnapshot<Value: Sendable>(
    actual: Swift.String,
    expected: (() -> Swift.String)?,
    strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    mode: Test.Snapshot.Recording,
    filePath: Swift.String,
    line: Int,
    column: Int,
    function: Swift.String
) -> Swift.String? {
    let expectedValue = expected?()

    switch mode {
    case .all:
        // Always record
        Test.Snapshot.Inline.state.register(.init(
            expected: expectedValue,
            actual: actual,
            wasRecording: true,
            filePath: filePath,
            function: function,
            line: line,
            column: column
        ))
        return "Automatically recorded inline snapshot. Re-run to assert."

    case .missing where expectedValue == nil:
        // First run — no expected value yet
        Test.Snapshot.Inline.state.register(.init(
            expected: nil,
            actual: actual,
            wasRecording: true,
            filePath: filePath,
            function: function,
            line: line,
            column: column
        ))
        return "Automatically recorded inline snapshot. Re-run to assert."

    case .missing, .never:
        // Compare mode
        guard let expectedValue else {
            if mode == .never {
                return "No inline snapshot found. Run with recording mode '.missing' or '.all' to record."
            }
            return nil
        }

        if let diff = strategy.diffing.diff(expectedValue, actual) {
            var message = "Inline snapshot does not match.\n"
            message += diff.summary
            if let unifiedDiff = diff.unifiedDiff {
                message += "\n\n\(unifiedDiff)"
            }
            return message
        }

        return nil

    case .failed:
        guard let expectedValue else {
            Test.Snapshot.Inline.state.register(.init(
                expected: nil,
                actual: actual,
                wasRecording: true,
                filePath: filePath,
                function: function,
                line: line,
                column: column
            ))
            return "Automatically recorded inline snapshot. Re-run to assert."
        }

        if let diff = strategy.diffing.diff(expectedValue, actual) {
            Test.Snapshot.Inline.state.register(.init(
                expected: expectedValue,
                actual: actual,
                wasRecording: true,
                filePath: filePath,
                function: function,
                line: line,
                column: column
            ))
            var message = "Inline snapshot does not match. Updated snapshot recorded. Re-run to assert.\n"
            message += diff.summary
            if let unifiedDiff = diff.unifiedDiff {
                message += "\n\n\(unifiedDiff)"
            }
            return message
        }

        return nil
    }
}

// MARK: - Expectation Creation

private func makeInlinePassingExpectation(
    fileID: Swift.String,
    filePath: Swift.String,
    line: Int,
    column: Int
) -> Test.Expectation {
    .record(
        passing: "assertInlineSnapshot(of: ..., as: ...)",
        at: Source.Location(fileID: fileID, filePath: filePath, line: line, column: column)
    )
}

private func makeInlineFailingExpectation(
    message: Swift.String,
    fileID: Swift.String,
    filePath: Swift.String,
    line: Int,
    column: Int
) -> Test.Expectation {
    .record(
        failing: message,
        sourceCode: "assertInlineSnapshot(of: ..., as: ...)",
        at: Source.Location(fileID: fileID, filePath: filePath, line: line, column: column)
    )
}
