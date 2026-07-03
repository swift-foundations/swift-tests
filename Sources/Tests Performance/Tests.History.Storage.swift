//
//  Tests.History.Storage.swift
//  swift-tests
//
//  Append-only JSONL storage for run history.
//

import Environment
public import File_System
public import IO
import JSON
public import Thread_Pool

extension Tests.History {
    /// Handles history file I/O.
    ///
    /// History files are JSONL (one JSON object per line), stored alongside
    /// baselines with a `.jsonl` extension. Each `.timed()` run appends one
    /// line. Reading loads all records for trend analysis.
    public enum Storage {}
}

// MARK: - Path Generation

extension Tests.History.Storage {
    /// Computes the history file path from test identity and fingerprint.
    ///
    /// Uses the same directory structure as baselines, differing only
    /// in extension: `.json` for baselines, `.jsonl` for history.
    ///
    /// - Parameters:
    ///   - root: The benchmark root directory.
    ///   - testID: The test identifier.
    ///   - fingerprint: The environment fingerprint.
    /// - Returns: The history file path.
    public static func path(
        root: File.Path,
        testID: Test.ID,
        fingerprint: Swift.String
    ) -> File.Path {
        var result = root / "\(testID.module)"

        if let suite = testID.suite {
            for component in suite.split(separator: ".") {
                result = result / "\(component)"
            }
        }

        return result / "\(testID.name)" / "\(fingerprint).jsonl"
    }

}

// MARK: - Configuration

extension Tests.History.Storage {
    /// Whether history recording is enabled.
    ///
    /// Resolved from `SWIFT_BENCHMARK_HISTORY`:
    /// - unset or `"true"` → enabled (default)
    /// - `"false"` → disabled
    public static var isEnabled: Bool {
        guard let value = Environment.read("SWIFT_BENCHMARK_HISTORY") else {
            return true
        }
        return value.lowercased() != "false"
    }

    /// Maximum number of records to retain per history file.
    ///
    /// Resolved from `SWIFT_BENCHMARK_HISTORY_MAX`:
    /// - unset → `nil` (unlimited)
    /// - positive integer → that limit
    public static var maxRecords: Int? {
        guard let value = Environment.read("SWIFT_BENCHMARK_HISTORY_MAX"),
            let max = Int(value), max > 0
        else { return nil }
        return max
    }
}

// MARK: - Append

extension Tests.History.Storage {
    /// Appends a record to the history file.
    ///
    /// Creates parent directories as needed. Serializes the record
    /// as a single JSON line and appends it to the JSONL file.
    ///
    /// If `maxRecords` is set and the file exceeds that limit,
    /// the oldest records are pruned.
    ///
    /// - Parameters:
    ///   - record: The record to append.
    ///   - root: The benchmark root directory.
    public static func append(
        _ record: Tests.History.Record,
        root: File.Path
    ) throws(Error) {
        let filePath = path(
            root: root,
            testID: record.testID,
            fingerprint: record.environment.fingerprint
        )

        // Ensure parent directory exists
        if let parent = filePath.parent {
            try _ensureDirectory(at: parent)
        }

        // Serialize record to compact JSON line
        let json = Tests.History.Record.serialize(record)
        let bytes = json.serialize(pretty: false, as: [UInt8].self)
        let line = Swift.String(decoding: bytes, as: UTF8.self) + "\n"

        // Append to file
        do {
            try File(filePath).write.append(line)
        } catch {
            throw .writeFailed(
                path: filePath,
                underlying: Swift.String(describing: error)
            )
        }

        // Prune if max records configured
        if let max = maxRecords {
            _pruneIfNeeded(at: filePath, max: max)
        }
    }

    private static func _ensureDirectory(
        at path: File.Path
    ) throws(Error) {
        let dir = File.Directory(path)
        if dir.stat.exists { return }

        do {
            try dir.create.recursive()
        } catch {
            throw .directoryCreationFailed(
                path: path,
                underlying: Swift.String(describing: error)
            )
        }
    }

    /// Prunes the history file to the most recent N records.
    private static func _pruneIfNeeded(at path: File.Path, max: Int) {
        let records = load(at: path)
        guard records.count > max else { return }

        let sorted = records.sorted { $0.timestamp < $1.timestamp }
        let kept = [Tests.History.Record](sorted.suffix(max))

        // Rewrite the file with only the kept records
        var lines: [Swift.String] = []
        for record in kept {
            let json = Tests.History.Record.serialize(record)
            let bytes = json.serialize(pretty: false, as: [UInt8].self)
            lines.append(Swift.String(decoding: bytes, as: UTF8.self))
        }
        let content = lines.joined(separator: "\n") + "\n"
        try? File(path).write.atomic(content)
    }
}

// MARK: - Append (Async)

extension Tests.History.Storage {
    /// Appends a record to the history file.
    ///
    /// Async variant - runs blocking I/O on a dedicated thread pool.
    ///
    /// - Parameters:
    ///   - record: The record to append.
    ///   - root: The benchmark root directory.
    public static func append(
        _ record: Tests.History.Record,
        root: File.Path
    ) async throws(Either<Kernel.Thread.Pool.Error, Error>) {
        let record = record
        let root = root
        try await Kernel.Thread.Pool.shared.run { () throws(Error) in
            try append(record, root: root)
        }
    }
}

// MARK: - Load

extension Tests.History.Storage {
    /// Loads all history records from a JSONL file.
    ///
    /// - Parameter path: Path to the history JSONL file.
    /// - Returns: All successfully parsed records, in file order.
    public static func load(at path: File.Path) -> [Tests.History.Record] {
        let file = File(path)
        guard file.stat.exists else { return [] }

        do {
            return try file.read.full { span in
                let content = unsafe span.withUnsafeBufferPointer {
                    unsafe Swift.String(decoding: $0, as: UTF8.self)
                }
                return _parseJSONL(content)
            }
        } catch {
            return []
        }
    }

    /// Loads history records for a specific test and environment.
    ///
    /// - Parameters:
    ///   - root: The benchmark root directory.
    ///   - testID: The test identifier.
    ///   - fingerprint: The environment fingerprint.
    /// - Returns: All history records.
    public static func load(
        root: File.Path,
        testID: Test.ID,
        fingerprint: Swift.String
    ) -> [Tests.History.Record] {
        load(at: path(root: root, testID: testID, fingerprint: fingerprint))
    }

    /// Parses JSONL content into records, skipping malformed lines.
    private static func _parseJSONL(_ content: Swift.String) -> [Tests.History.Record] {
        var records: [Tests.History.Record] = []
        for line in content.split(separator: "\n", omittingEmptySubsequences: true) {
            guard let json = try? JSON.parse(Swift.String(line)),
                let record = try? Tests.History.Record.deserialize(json)
            else { continue }
            records.append(record)
        }
        return records
    }
}

// MARK: - Load (Async)

extension Tests.History.Storage {
    /// Loads all history records from a JSONL file.
    ///
    /// Async variant - runs blocking I/O on a dedicated thread pool.
    ///
    /// - Parameter path: Path to the history JSONL file.
    /// - Returns: All successfully parsed records, in file order.
    public static func load(
        at path: File.Path
    ) async throws(Kernel.Thread.Pool.Error) -> [Tests.History.Record] {
        let path = path
        return try await Kernel.Thread.Pool.shared.run { () -> [Tests.History.Record] in
            load(at: path)
        }
    }

    /// Loads history records for a specific test and environment.
    ///
    /// Async variant - runs blocking I/O on a dedicated thread pool.
    ///
    /// - Parameters:
    ///   - root: The benchmark root directory.
    ///   - testID: The test identifier.
    ///   - fingerprint: The environment fingerprint.
    /// - Returns: All history records.
    public static func load(
        root: File.Path,
        testID: Test.ID,
        fingerprint: Swift.String
    ) async throws(Kernel.Thread.Pool.Error) -> [Tests.History.Record] {
        let filePath = path(root: root, testID: testID, fingerprint: fingerprint)
        return try await Kernel.Thread.Pool.shared.run { () -> [Tests.History.Record] in
            load(at: filePath)
        }
    }
}
