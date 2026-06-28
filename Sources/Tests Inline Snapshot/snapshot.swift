//
//  snapshot.swift
//  swift-tests
//
//  Unified snapshot assertion function.
//

public import Test_Primitives
import File_System

// MARK: - snapshot (String Format, Synchronous)

/// Asserts that a value matches its snapshot.
///
/// Configuration goes first, value as trailing closure, expected as
/// `matches:` additional trailing closure.
///
/// ## Inline Snapshot
///
/// ```swift
/// // First run — records and rewrites source:
/// snapshot(as: .html) {
///     VStack { div { "Hello" } }
/// }
///
/// // After recording, source becomes:
/// snapshot(as: .html) {
///     VStack { div { "Hello" } }
/// } matches: {
///     """
///     <div>Hello</div>
///     """
/// }
/// ```
///
/// ## File-Backed Snapshot
///
/// ```swift
/// snapshot(as: .json, named: "user-profile") {
///     user
/// }
/// ```
///
/// - Parameters:
///   - strategy: How to convert and compare the value (String format).
///   - name: File-backed storage name. When `nil`, uses inline storage.
///   - recording: Recording mode override.
///   - redactions: Redaction rules applied before comparison.
///   - value: Trailing closure producing the value to snapshot.
///   - expected: Additional trailing closure containing the expected value
///     (inline only).
///   - fileID: Source file ID (captured automatically).
///   - filePath: Source path (captured automatically).
///   - line: Source line (captured automatically).
///   - column: Source column (captured automatically).
///   - function: Test function name (captured automatically).
/// - Returns: The snapshot expectation result.
@discardableResult
public func snapshot<Value>(
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
    _ value: () -> Value,
    matches expected: (() -> Swift.String)? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) -> Test.Expectation {
    let effective = redactions.isEmpty ? strategy : strategy.redacting(redactions)
    let location = Source.Location(
        fileID: fileID, filePath: filePath, line: line, column: column
    )

    if name != nil && expected != nil {
        return .record(
            failing: "Cannot combine 'named:' (file-backed) with 'matches:' (inline). Remove one.",
            sourceCode: "snapshot(as: ...)",
            at: location
        )
    }

    guard let syncSnapshot = effective.syncSnapshot else {
        return .record(
            failing: "Strategy does not support synchronous capture. Use async snapshot.",
            sourceCode: "snapshot(as: ...)",
            at: location
        )
    }

    let actual = syncSnapshot(value())
    let mode = Test.Snapshot.Configuration.resolve(recording: recording)
    let config = Test.Snapshot.Configuration.current

    let failure: Swift.String?
    if let name {
        failure = Test.Snapshot.Storage.resolve(
            actual: actual, strategy: effective, name: name, mode: mode,
            filePath: filePath, function: function,
            snapshotDirectory: config?.snapshotDirectory,
            subdirectory: config?.subdirectory
        )
    } else {
        failure = Test.Snapshot.Inline.resolve(
            actual: actual, strategy: effective, expected: expected, mode: mode,
            filePath: filePath, line: line, column: column, function: function
        )
    }

    if let failure {
        return .record(failing: failure, sourceCode: "snapshot(as: ...)", at: location)
    }
    return .record(passing: "snapshot(as: ...)", at: location)
}

// MARK: - snapshot (String Format, Asynchronous)

/// Asserts that a value matches its snapshot (async variant).
@discardableResult
public func snapshot<Value>(
    as strategy: Test.Snapshot.Strategy<Value, Swift.String>,
    named name: Swift.String? = nil,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Swift.String>] = [],
    _ value: () -> Value,
    matches expected: (() -> Swift.String)? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) async -> Test.Expectation {
    let effective = redactions.isEmpty ? strategy : strategy.redacting(redactions)
    let location = Source.Location(
        fileID: fileID, filePath: filePath, line: line, column: column
    )

    if name != nil && expected != nil {
        return .record(
            failing: "Cannot combine 'named:' (file-backed) with 'matches:' (inline). Remove one.",
            sourceCode: "snapshot(as: ...)",
            at: location
        )
    }

    let actual = await effective.capture(value())
    let mode = Test.Snapshot.Configuration.resolve(recording: recording)
    let config = Test.Snapshot.Configuration.current

    let failure: Swift.String?
    if let name {
        failure = Test.Snapshot.Storage.resolve(
            actual: actual, strategy: effective, name: name, mode: mode,
            filePath: filePath, function: function,
            snapshotDirectory: config?.snapshotDirectory,
            subdirectory: config?.subdirectory
        )
    } else {
        failure = Test.Snapshot.Inline.resolve(
            actual: actual, strategy: effective, expected: expected, mode: mode,
            filePath: filePath, line: line, column: column, function: function
        )
    }

    if let failure {
        return .record(failing: failure, sourceCode: "snapshot(as: ...)", at: location)
    }
    return .record(passing: "snapshot(as: ...)", at: location)
}

// MARK: - snapshot (Generic Format, Synchronous)

/// Asserts that a value matches its file-backed snapshot.
///
/// Use this overload for non-String formats (binary, image, etc.).
@discardableResult
public func snapshot<Value, Format: Sendable>(
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Format>] = [],
    _ value: () -> Value,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) -> Test.Expectation {
    let effective = redactions.isEmpty ? strategy : strategy.redacting(redactions)
    let location = Source.Location(
        fileID: fileID, filePath: filePath, line: line, column: column
    )

    guard let syncSnapshot = effective.syncSnapshot else {
        return .record(
            failing: "Strategy does not support synchronous capture. Use async snapshot.",
            sourceCode: "snapshot(as: ..., named: ...)",
            at: location
        )
    }

    let actual = syncSnapshot(value())
    let mode = Test.Snapshot.Configuration.resolve(recording: recording)
    let snapshotDir = Test.Snapshot.Configuration.current?.snapshotDirectory

    let failure = Test.Snapshot.Storage.resolve(
        actual: actual, strategy: effective, name: name, mode: mode,
        filePath: filePath, function: function,
        snapshotDirectory: snapshotDir
    )

    if let failure {
        return .record(
            failing: failure, sourceCode: "snapshot(as: ..., named: ...)", at: location
        )
    }
    return .record(passing: "snapshot(as: ..., named: ...)", at: location)
}

// MARK: - snapshot (Generic Format, Asynchronous)

/// Asserts that a value matches its file-backed snapshot (async variant).
@discardableResult
public func snapshot<Value, Format: Sendable>(
    as strategy: Test.Snapshot.Strategy<Value, Format>,
    named name: Swift.String,
    record recording: Test.Snapshot.Recording? = nil,
    redacting redactions: [Test.Snapshot.Redaction<Format>] = [],
    _ value: () -> Value,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column,
    function: Swift.String = #function
) async -> Test.Expectation {
    let effective = redactions.isEmpty ? strategy : strategy.redacting(redactions)
    let location = Source.Location(
        fileID: fileID, filePath: filePath, line: line, column: column
    )

    let actual = await effective.capture(value())
    let mode = Test.Snapshot.Configuration.resolve(recording: recording)
    let snapshotDir = Test.Snapshot.Configuration.current?.snapshotDirectory

    let failure = Test.Snapshot.Storage.resolve(
        actual: actual, strategy: effective, name: name, mode: mode,
        filePath: filePath, function: function,
        snapshotDirectory: snapshotDir
    )

    if let failure {
        return .record(
            failing: failure, sourceCode: "snapshot(as: ..., named: ...)", at: location
        )
    }
    return .record(passing: "snapshot(as: ..., named: ...)", at: location)
}

// MARK: - Inline Resolution

extension Test.Snapshot.Inline {
    /// Resolves an inline snapshot against the closure-provided expected value.
    ///
    /// Returns a failure message, or `nil` when the snapshot matches.
    static func resolve<Value>(
        actual: Swift.String,
        strategy: Test.Snapshot.Strategy<Value, Swift.String>,
        expected: (() -> Swift.String)?,
        mode: Test.Snapshot.Recording,
        filePath: Swift.String,
        line: Int,
        column: Int,
        function: Swift.String
    ) -> Swift.String? {
        let expectedValue = expected?()

        func register() {
            state.register(.init(
                expected: expectedValue, actual: actual, wasRecording: true,
                filePath: filePath, function: function, line: line, column: column
            ))
        }

        switch mode {
        case .all:
            register()
            return "Recorded inline snapshot. Re-run to assert."

        case .missing where expectedValue == nil:
            register()
            return "Recorded inline snapshot. Re-run to assert."

        case .missing, .never:
            guard let expectedValue else {
                return mode == .never
                    ? "No inline snapshot found. Run with record mode '.missing' or '.all'."
                    : nil
            }
            if let diff = strategy.diffing.diff(expectedValue, actual) {
                return diff.message(prefix: "Inline snapshot does not match.")
            }
            return nil

        case .failed:
            guard let expectedValue else {
                register()
                return "Recorded inline snapshot. Re-run to assert."
            }
            if let diff = strategy.diffing.diff(expectedValue, actual) {
                register()
                return diff.message(
                    prefix: "Inline snapshot mismatch. Updated recorded. Re-run to assert."
                )
            }
            return nil
        }
    }
}

// MARK: - File Resolution

extension Test.Snapshot.Storage {
    /// Resolves a file-backed snapshot against the filesystem reference.
    ///
    /// Returns a failure message, or `nil` when the snapshot matches.
    static func resolve<Value, Format: Sendable>(
        actual: Format,
        strategy: Test.Snapshot.Strategy<Value, Format>,
        name: Swift.String,
        mode: Test.Snapshot.Recording,
        filePath: Swift.String,
        function: Swift.String,
        snapshotDirectory: File.Path? = nil,
        subdirectory: File.Path.Component? = nil
    ) -> Swift.String? {
        let snapshotPath = path(
            testFilePath: filePath,
            function: function,
            name: name,
            counter: 0,
            pathExtension: strategy.pathExtension ?? "",
            snapshotDirectory: snapshotDirectory,
            subdirectory: subdirectory
        )
        let actualBytes = strategy.diffing.toBytes(actual)
        let referenceBytes = reference(at: snapshotPath)
        let pathString = Swift.String("\(snapshotPath)")

        func write() -> Swift.String? {
            do {
                try Self.write(bytes: actualBytes, to: snapshotPath)
                return nil
            } catch {
                return "Failed to write snapshot: \(error)"
            }
        }

        func compare(_ reference: [Byte]) -> Swift.String? {
            if reference == actualBytes { return nil }

            guard let referenceFormat = strategy.diffing.fromBytes(reference) else {
                return "Failed to deserialize reference snapshot at: \(pathString)"
            }

            if let diff = strategy.diffing.diff(referenceFormat, actual) {
                Test.Attachment.collector.record(
                    .init(
                        name: "actual.\(strategy.pathExtension ?? "bin")",
                        bytes: actualBytes
                    )
                )
                Test.Attachment.collector.record(
                    .init(name: "snapshot-diff.txt", string: diff.description)
                )
                return diff.message(
                    prefix: "Snapshot does not match reference at: \(pathString)"
                )
            }
            return nil
        }

        switch mode {
        case .all:
            return write()

        case .missing:
            if let referenceBytes { return compare(referenceBytes) }
            return write()

        case .never:
            if let referenceBytes { return compare(referenceBytes) }
            return "No reference snapshot at: \(pathString). "
                + "Use record mode '.missing' or '.all'."

        case .failed:
            if let referenceBytes {
                let failure = compare(referenceBytes)
                if failure != nil { _ = write() }
                return failure
            }
            return write()
        }
    }
}

// MARK: - Diff Formatting

extension Test.Snapshot.Diff.Result {
    /// Formats this diff result with a prefix message.
    fileprivate func message(prefix: Swift.String) -> Swift.String {
        var result = prefix + "\n" + summary
        if let unifiedDiff {
            result += "\n\n\(unifiedDiff)"
        }
        return result
    }
}
