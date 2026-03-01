//
//  Test.Snapshot.assert.swift
//  swift-tests
//
//  Snapshot testing assertion functions.
//

public import Test_Primitives
public import Identity_Primitives
import Synchronization
public import File_System

// MARK: - assertSnapshot (Synchronous, Captured Value)

/// Asserts that a captured value matches its snapshot.
///
/// The value is evaluated eagerly at the call site. If the value expression
/// throws, the caller handles it with `try` and the typed error propagates
/// naturally.
///
/// ## Example
///
/// ```swift
/// @Test
/// func testUserJSON() {
///     let user = User(name: "Alice", age: 30)
///     assertSnapshot(capturing: user.description, as: .lines)
/// }
/// ```
///
/// ## Recording Modes
///
/// - `.never`: Compare only; fail if reference missing
/// - `.missing`: Record if missing; compare if exists (default)
/// - `.failed`: Record on failure + fail
/// - `.all`: Always record (overwrite)
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: Optional snapshot name (auto-numbered if nil).
///   - record: Recording mode override (uses configuration default if nil).
///   - fileID: Source file ID (captured automatically).
///   - filePath: Source path (captured automatically).
///   - line: Source line (captured automatically).
///   - column: Source column (captured automatically).
///   - function: Test function name (captured automatically).
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertSnapshot<Value: Sendable, Format: Sendable>(
    capturing value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) -> Test.Expectation {
    // Check for sync snapshot support
    guard let syncSnapshot = strategy.syncSnapshot else {
        return makeFailingExpectation(
            message: "Strategy does not support synchronous capture. Use async assertSnapshot.",
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    let failure = _verifySnapshot(
        of: value,
        syncSnapshot: syncSnapshot,
        strategy: strategy,
        named: name,
        record: recording,
        filePath: filePath,
        function: function
    )

    if let failure {
        return makeFailingExpectation(
            message: failure,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    return makePassingExpectation(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

// MARK: - assertSnapshot (Synchronous, Autoclosure)

// WORKAROUND: @autoclosure () throws(E) -> Value has a fundamental E inference
// bug in Swift 6.2. E cannot be inferred in ANY context — not from non-throwing
// expressions, not even from typed-throwing expressions.
// WHY: SE-0413 FullTypedThrows inference was never implemented (experimental only).
// WHEN TO REMOVE: When FullTypedThrows ships in a Swift release.
// TRACKING: https://github.com/swiftlang/swift/issues/75430

/// Asserts that a value matches its snapshot.
///
/// On first run (or in record mode), records the snapshot.
/// On subsequent runs, compares against the stored reference.
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: Optional snapshot name (auto-numbered if nil).
///   - record: Recording mode override (uses configuration default if nil).
///   - fileID: Source file ID (captured automatically).
///   - filePath: Source path (captured automatically).
///   - line: Source line (captured automatically).
///   - column: Source column (captured automatically).
///   - function: Test function name (captured automatically).
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertSnapshot<Value: Sendable, Format: Sendable, E: Swift.Error>(
    of value: @autoclosure () throws(E) -> Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) -> Test.Expectation {
    do {
        let capturedValue = try value()

        // Check for sync snapshot support
        guard let syncSnapshot = strategy.syncSnapshot else {
            return makeFailingExpectation(
                message: "Strategy does not support synchronous capture. Use async assertSnapshot.",
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        }

        let failure = _verifySnapshot(
            of: capturedValue,
            syncSnapshot: syncSnapshot,
            strategy: strategy,
            named: name,
            record: recording,
            filePath: filePath,
            function: function
        )

        if let failure {
            return makeFailingExpectation(
                message: failure,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        }

        return makePassingExpectation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    } catch {
        return makeFailingExpectation(
            message: "Failed to capture value: \(error)",
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}

// MARK: - assertSnapshot (Asynchronous, Captured Value)

/// Asserts that a captured value matches its snapshot (async variant).
///
/// Supports strategies with async snapshot capture.
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: Optional snapshot name.
///   - record: Recording mode override.
///   - fileID: Source file ID.
///   - filePath: Source path.
///   - line: Source line.
///   - column: Source column.
///   - function: Test function name.
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertSnapshot<Value: Sendable, Format: Sendable>(
    capturing value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) async -> Test.Expectation {
    let failure = await _verifySnapshot(
        of: value,
        strategy: strategy,
        named: name,
        record: recording,
        filePath: filePath,
        function: function
    )

    if let failure {
        return makeFailingExpectation(
            message: failure,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    return makePassingExpectation(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

// MARK: - assertSnapshot (Asynchronous, Autoclosure)

// WORKAROUND: See synchronous autoclosure variant above.
// TRACKING: https://github.com/swiftlang/swift/issues/75430

/// Asserts that a value matches its snapshot (async variant).
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: Optional snapshot name.
///   - record: Recording mode override.
///   - fileID: Source file ID.
///   - filePath: Source path.
///   - line: Source line.
///   - column: Source column.
///   - function: Test function name.
/// - Returns: The snapshot expectation result.
@discardableResult
public func assertSnapshot<Value: Sendable, Format: Sendable, E: Swift.Error>(
    of value: @autoclosure () throws(E) -> Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) async -> Test.Expectation {
    do {
        let capturedValue = try value()

        let failure = await _verifySnapshot(
            of: capturedValue,
            strategy: strategy,
            named: name,
            record: recording,
            filePath: filePath,
            function: function
        )

        if let failure {
            return makeFailingExpectation(
                message: failure,
                fileID: fileID,
                filePath: filePath,
                line: line,
                column: column
            )
        }

        return makePassingExpectation(
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    } catch {
        return makeFailingExpectation(
            message: "Failed to capture value: \(error)",
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }
}

// MARK: - verifySnapshot (Captured Value)

/// Verifies that a captured value matches its snapshot, returning the failure message if any.
///
/// Unlike ``assertSnapshot(capturing:as:named:record:fileID:filePath:line:column:function:)``,
/// this function returns the failure message instead of recording a test failure.
/// Useful when you want to handle snapshot failures programmatically.
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: Optional snapshot name.
///   - record: Recording mode override.
///   - filePath: Source path.
///   - function: Test function name.
/// - Returns: `nil` if the snapshot matches, or an error message describing the failure.
public func verifySnapshot<Value: Sendable, Format: Sendable>(
    capturing value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    filePath: Swift.String = #filePath,
    function: Swift.String = #function
) -> Swift.String? {
    guard let syncSnapshot = strategy.syncSnapshot else {
        return "Strategy does not support synchronous capture. Use async verifySnapshot."
    }

    return _verifySnapshot(
        of: value,
        syncSnapshot: syncSnapshot,
        strategy: strategy,
        named: name,
        record: recording,
        filePath: filePath,
        function: function
    )
}

/// Verifies that a captured value matches its snapshot (async variant).
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: Optional snapshot name.
///   - record: Recording mode override.
///   - filePath: Source path.
///   - function: Test function name.
/// - Returns: `nil` if the snapshot matches, or an error message describing the failure.
public func verifySnapshot<Value: Sendable, Format: Sendable>(
    capturing value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    filePath: Swift.String = #filePath,
    function: Swift.String = #function
) async -> Swift.String? {
    await _verifySnapshot(
        of: value,
        strategy: strategy,
        named: name,
        record: recording,
        filePath: filePath,
        function: function
    )
}

// MARK: - verifySnapshot (Autoclosure)

// WORKAROUND: See assertSnapshot autoclosure variant above.
// TRACKING: https://github.com/swiftlang/swift/issues/75430

/// Verifies that a value matches its snapshot, returning the failure message if any.
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: Optional snapshot name.
///   - record: Recording mode override.
///   - filePath: Source path.
///   - function: Test function name.
/// - Returns: `nil` if the snapshot matches, or an error message describing the failure.
public func verifySnapshot<Value: Sendable, Format: Sendable, E: Swift.Error>(
    of value: @autoclosure () throws(E) -> Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    filePath: Swift.String = #filePath,
    function: Swift.String = #function
) -> Swift.String? {
    do {
        let capturedValue = try value()

        guard let syncSnapshot = strategy.syncSnapshot else {
            return "Strategy does not support synchronous capture. Use async verifySnapshot."
        }

        return _verifySnapshot(
            of: capturedValue,
            syncSnapshot: syncSnapshot,
            strategy: strategy,
            named: name,
            record: recording,
            filePath: filePath,
            function: function
        )
    } catch {
        return "Failed to capture value: \(error)"
    }
}

/// Verifies that a value matches its snapshot (async variant).
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: Optional snapshot name.
///   - record: Recording mode override.
///   - filePath: Source path.
///   - function: Test function name.
/// - Returns: `nil` if the snapshot matches, or an error message describing the failure.
public func verifySnapshot<Value: Sendable, Format: Sendable, E: Swift.Error>(
    of value: @autoclosure () throws(E) -> Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    filePath: Swift.String = #filePath,
    function: Swift.String = #function
) async -> Swift.String? {
    do {
        let capturedValue = try value()
        return await _verifySnapshot(
            of: capturedValue,
            strategy: strategy,
            named: name,
            record: recording,
            filePath: filePath,
            function: function
        )
    } catch {
        return "Failed to capture value: \(error)"
    }
}

// MARK: - Internal Implementation

/// Internal sync verification.
private func _verifySnapshot<Value: Sendable, Format: Sendable>(
    of value: Value,
    syncSnapshot: @Sendable (Value) -> Format,
    strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String?,
    record recording: Test.Snapshot.Recording?,
    filePath: Swift.String,
    function: Swift.String
) -> Swift.String? {
    // Resolve recording mode
    let mode = Test.Snapshot.Configuration.resolveRecording(explicit: recording)

    // Get counter for unnamed snapshots
    let counterKey = Test.Snapshot.Counter.key(filePath: filePath, function: function)
    let counter = Test.Snapshot.counter.next(for: counterKey)

    // Compute snapshot path
    let snapshotPath = Test.Snapshot.Storage.path(
        testFilePath: filePath,
        function: function,
        name: name,
        counter: name == nil ? counter : 0,
        pathExtension: strategy.pathExtension ?? ""
    )

    // Capture the snapshot synchronously
    let format = syncSnapshot(value)
    let actualBytes = strategy.diffing.toBytes(format)

    // Perform snapshot comparison/recording
    let result = performSnapshot(
        actualBytes: actualBytes,
        format: format,
        strategy: strategy,
        path: snapshotPath,
        mode: mode
    )

    return resultToFailureMessage(result)
}

/// Internal async verification.
private func _verifySnapshot<Value: Sendable, Format: Sendable>(
    of value: Value,
    strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String?,
    record recording: Test.Snapshot.Recording?,
    filePath: Swift.String,
    function: Swift.String
) async -> Swift.String? {
    // Resolve recording mode
    let mode = Test.Snapshot.Configuration.resolveRecording(explicit: recording)

    // Get counter for unnamed snapshots
    let counterKey = Test.Snapshot.Counter.key(filePath: filePath, function: function)
    let counter = Test.Snapshot.counter.next(for: counterKey)

    // Compute snapshot path
    let snapshotPath = Test.Snapshot.Storage.path(
        testFilePath: filePath,
        function: function,
        name: name,
        counter: name == nil ? counter : 0,
        pathExtension: strategy.pathExtension ?? ""
    )

    // Capture the snapshot asynchronously
    let format = await strategy.capture(value)
    let actualBytes = strategy.diffing.toBytes(format)

    // Perform snapshot comparison/recording
    let result = performSnapshot(
        actualBytes: actualBytes,
        format: format,
        strategy: strategy,
        path: snapshotPath,
        mode: mode
    )

    return resultToFailureMessage(result)
}

// MARK: - Core Logic

/// Performs the snapshot comparison/recording logic.
private func performSnapshot<Format: Sendable>(
    actualBytes: [UInt8],
    format: Format,
    strategy: Test.Snapshot.Strategy<some Any, Format>,
    path: File.Path,
    mode: Test.Snapshot.Recording
) -> Test.Snapshot.Result {
    let pathString = Swift.String("\(path)")

    // Check if reference exists
    let referenceBytes = Test.Snapshot.Storage.readReference(at: path)
    let referenceExists = referenceBytes != nil

    switch mode {
    case .all:
        // Always record
        do {
            try Test.Snapshot.Storage.write(bytes: actualBytes, to: path)
            return .recorded(path: pathString)
        } catch {
            return .failed(
                diff: Test.Snapshot.DiffResult(summary: "Failed to write snapshot: \(error)"),
                referencePath: pathString
            )
        }

    case .missing:
        if !referenceExists {
            // Record new snapshot
            do {
                try Test.Snapshot.Storage.write(bytes: actualBytes, to: path)
                return .recorded(path: pathString)
            } catch {
                return .failed(
                    diff: Test.Snapshot.DiffResult(summary: "Failed to write snapshot: \(error)"),
                    referencePath: pathString
                )
            }
        } else {
            // Compare against existing
            return compareSnapshot(
                referenceBytes: referenceBytes!,
                actualBytes: actualBytes,
                format: format,
                strategy: strategy,
                path: pathString
            )
        }

    case .never:
        if !referenceExists {
            return .missingReference(path: pathString)
        } else {
            return compareSnapshot(
                referenceBytes: referenceBytes!,
                actualBytes: actualBytes,
                format: format,
                strategy: strategy,
                path: pathString
            )
        }

    case .failed:
        if !referenceExists {
            // Record new snapshot
            do {
                try Test.Snapshot.Storage.write(bytes: actualBytes, to: path)
                return .recorded(path: pathString)
            } catch {
                return .failed(
                    diff: Test.Snapshot.DiffResult(summary: "Failed to write snapshot: \(error)"),
                    referencePath: pathString
                )
            }
        } else {
            // Compare, and record if different
            let comparisonResult = compareSnapshot(
                referenceBytes: referenceBytes!,
                actualBytes: actualBytes,
                format: format,
                strategy: strategy,
                path: pathString
            )

            if case .failed = comparisonResult {
                // Record the new snapshot but still report failure
                try? Test.Snapshot.Storage.write(bytes: actualBytes, to: path)
            }

            return comparisonResult
        }
    }
}

/// Compares actual snapshot against reference.
private func compareSnapshot<Format: Sendable>(
    referenceBytes: [UInt8],
    actualBytes: [UInt8],
    format: Format,
    strategy: Test.Snapshot.Strategy<some Any, Format>,
    path: Swift.String
) -> Test.Snapshot.Result {
    // Quick byte comparison first
    if referenceBytes == actualBytes {
        return .matched
    }

    // Deserialize reference and do semantic diff
    guard let referenceFormat = strategy.diffing.fromBytes(referenceBytes) else {
        return .failed(
            diff: Test.Snapshot.DiffResult(summary: "Failed to deserialize reference snapshot"),
            referencePath: path
        )
    }

    // Use the strategy's diff function
    if let diffResult = strategy.diffing.diff(referenceFormat, format) {
        return .failed(diff: diffResult, referencePath: path)
    }

    // Diff function returned nil (equal)
    return .matched
}

/// Converts a snapshot result to a failure message.
private func resultToFailureMessage(_ result: Test.Snapshot.Result) -> Swift.String? {
    switch result {
    case .matched:
        return nil
    case .recorded(let path):
        // Recording is considered success in default mode
        return nil
    case .failed(let diff, let referencePath):
        var message = "Snapshot does not match reference at: \(referencePath)\n"
        message += diff.summary
        if let unifiedDiff = diff.unifiedDiff {
            message += "\n\n\(unifiedDiff)"
        }
        return message
    case .missingReference(let path):
        return "No reference snapshot found at: \(path)\nRun with recording mode '.missing' or '.all' to create the reference snapshot."
    }
}

// MARK: - Expectation Creation

/// Creates a passing expectation.
private func makePassingExpectation(
    fileID: Swift.String,
    filePath: Swift.String,
    line: Int,
    column: Int
) -> Test.Expectation {
    let location = Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    let expressionID = Test.Expression.ID(__unchecked: (), nextSnapshotExpressionID())
    let expression = Test.Expression(
        id: expressionID,
        sourceCode: "assertSnapshot(of: ..., as: ...)",
        sourceLocation: location
    )

    let expectationID = Test.Expectation.ID(__unchecked: (), nextSnapshotExpectationID())

    return Test.Expectation(
        id: expectationID,
        expression: expression,
        isPassing: true
    )
}

/// Creates a failing expectation with a message.
private func makeFailingExpectation(
    message: Swift.String,
    fileID: Swift.String,
    filePath: Swift.String,
    line: Int,
    column: Int
) -> Test.Expectation {
    let location = Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    let expressionID = Test.Expression.ID(__unchecked: (), nextSnapshotExpressionID())
    let expression = Test.Expression(
        id: expressionID,
        sourceCode: "assertSnapshot(of: ..., as: ...)",
        sourceLocation: location
    )

    let expectationID = Test.Expectation.ID(__unchecked: (), nextSnapshotExpectationID())
    let failure = Test.Expectation.Failure(message: Test.Text(message))

    return Test.Expectation(
        id: expectationID,
        expression: expression,
        isPassing: false,
        failure: failure
    )
}

// MARK: - ID Counters

/// Atomic counter for snapshot expression IDs.
private let _snapshotExpressionCounter = Atomic<UInt64>(0)

private func nextSnapshotExpressionID() -> UInt64 {
    _snapshotExpressionCounter.wrappingAdd(1, ordering: .relaxed).newValue
}

/// Atomic counter for snapshot expectation IDs.
private let _snapshotExpectationCounter = Atomic<UInt64>(0)

private func nextSnapshotExpectationID() -> UInt64 {
    _snapshotExpectationCounter.wrappingAdd(1, ordering: .relaxed).newValue
}
