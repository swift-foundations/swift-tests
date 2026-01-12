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

// MARK: - Synchronous Assertion

/// Asserts that a value matches its snapshot.
///
/// On first run (or in record mode), records the snapshot.
/// On subsequent runs, compares against the stored reference.
///
/// ## Example
///
/// ```swift
/// @Test
/// func testUserJSON() {
///     let user = User(name: "Alice", age: 30)
///     expectSnapshot(of: user.description, as: .lines)
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
///   - recording: Recording mode (uses configuration default if nil).
///   - fileID: Source file ID (captured automatically).
///   - filePath: Source path (captured automatically).
///   - line: Source line (captured automatically).
///   - column: Source column (captured automatically).
///   - function: Test function name (captured automatically).
/// - Returns: The snapshot expectation result.
@discardableResult
public func expectSnapshot<Value, Format>(
    of value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: String? = nil,
    recording: Test.Snapshot.Recording? = nil,
    fileID: String = #fileID,
    filePath: String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: String = #function
) -> Test.Expectation {
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
        pathExtension: strategy.pathExtension
    )

    // Capture the snapshot
    guard let snapshot = strategy.snapshot else {
        return makeFailingExpectation(
            message: "Strategy does not support synchronous capture. Use async expectSnapshot.",
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )
    }

    let format = snapshot(value)
    let actualBytes = strategy.diffing.toBytes(format)

    // Perform snapshot comparison/recording
    let result = performSnapshot(
        actualBytes: actualBytes,
        format: format,
        strategy: strategy,
        path: snapshotPath,
        mode: mode
    )

    // Convert result to expectation
    return makeExpectation(
        result: result,
        snapshotPath: snapshotPath,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

// MARK: - Asynchronous Assertion

/// Asserts that a value matches its snapshot (async variant).
///
/// Supports strategies with async snapshot capture.
///
/// - Parameters:
///   - value: The value to snapshot.
///   - strategy: How to convert and compare the value.
///   - name: Optional snapshot name.
///   - recording: Recording mode.
///   - fileID: Source file ID.
///   - filePath: Source path.
///   - line: Source line.
///   - column: Source column.
///   - function: Test function name.
/// - Returns: The snapshot expectation result.
@discardableResult
public func expectSnapshot<Value, Format>(
    of value: Value,
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: String? = nil,
    recording: Test.Snapshot.Recording? = nil,
    fileID: String = #fileID,
    filePath: String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: String = #function
) async -> Test.Expectation {
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
        pathExtension: strategy.pathExtension
    )

    // Capture the snapshot (async)
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

    // Convert result to expectation
    return makeExpectation(
        result: result,
        snapshotPath: snapshotPath,
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

// MARK: - Core Logic

/// Performs the snapshot comparison/recording logic.
private func performSnapshot<Format>(
    actualBytes: [UInt8],
    format: Format,
    strategy: Test.Snapshot.Strategy<some Any, Format>,
    path: File.Path,
    mode: Test.Snapshot.Recording
) -> Test.Snapshot.Result {
    let pathString = String(path)

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
private func compareSnapshot<Format>(
    referenceBytes: [UInt8],
    actualBytes: [UInt8],
    format: Format,
    strategy: Test.Snapshot.Strategy<some Any, Format>,
    path: String
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

// MARK: - Expectation Creation

/// Creates a Test.Expectation from a snapshot result.
private func makeExpectation(
    result: Test.Snapshot.Result,
    snapshotPath: File.Path,
    fileID: String,
    filePath: String,
    line: Int,
    column: Int
) -> Test.Expectation {
    let location = Test.Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    let expressionID = Test.Expression.ID(nextSnapshotExpressionID())
    let expression = Test.Expression(
        id: expressionID,
        sourceCode: "expectSnapshot(of: ..., as: ...)",
        sourceLocation: location
    )

    let expectationID = Test.Expectation.ID(nextSnapshotExpectationID())

    switch result {
    case .matched:
        return Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: true
        )

    case .recorded(let path):
        // Recording is considered passing (new snapshot created)
        return Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: true,
            failure: nil
        )

    case .failed(let diff, let referencePath):
        let failure = Test.Expectation.Failure(
            message: "Snapshot does not match reference",
            expected: .init(
                label: "reference",
                stringValue: referencePath,
                typeDescription: "Snapshot",
                isNil: false
            ),
            actual: .init(
                label: "actual",
                stringValue: "(computed)",
                typeDescription: "Snapshot",
                isNil: false
            ),
            difference: diff.unifiedDiff
        )
        return Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: false,
            failure: failure
        )

    case .missingReference(let path):
        let failure = Test.Expectation.Failure(
            message: "No reference snapshot found at: \(path)",
            comment: "Run with recording mode '.missing' or '.all' to create the reference snapshot."
        )
        return Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: false,
            failure: failure
        )
    }
}

/// Creates a failing expectation with a message.
private func makeFailingExpectation(
    message: String,
    fileID: String,
    filePath: String,
    line: Int,
    column: Int
) -> Test.Expectation {
    let location = Test.Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    let expressionID = Test.Expression.ID(nextSnapshotExpressionID())
    let expression = Test.Expression(
        id: expressionID,
        sourceCode: "expectSnapshot(of: ..., as: ...)",
        sourceLocation: location
    )

    let expectationID = Test.Expectation.ID(nextSnapshotExpectationID())
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
