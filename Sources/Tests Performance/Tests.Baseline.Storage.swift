//
//  Tests.Baseline.Storage.swift
//  swift-tests
//
//  File-backed baseline storage using swift-file-system and swift-json.
//

public import File_System
public import JSON
import Environment

extension Tests.Baseline {
    /// Handles baseline file I/O.
    ///
    /// Baselines are stored as JSON files in a configurable root directory
    /// (default `.benchmarks/`), organized by test identity and environment
    /// fingerprint.
    ///
    /// ## Directory Convention
    ///
    /// ```
    /// .benchmarks/
    ///   {module}/
    ///     {suite}/                    ← omitted if no suite
    ///       {test-name}/
    ///         {fingerprint}.json      ← e.g., arm64-10c-debug-nnbd-sms.json
    /// ```
    public enum Storage {}
}

// MARK: - Root Directory

extension Tests.Baseline.Storage {
    /// Resolves the baseline root directory.
    ///
    /// Uses the `SWIFT_BENCHMARK_DIR` environment variable if set,
    /// otherwise defaults to `.benchmarks` relative to the current
    /// working directory.
    public static func root() -> File.Path {
        if let value = Environment.read("SWIFT_BENCHMARK_DIR"), !value.isEmpty {
            return File.Path(stringLiteral: value)
        }
        return File.Path(stringLiteral: ".benchmarks")
    }
}

// MARK: - Path Generation

extension Tests.Baseline.Storage {
    /// Computes the baseline file path from test identity and fingerprint.
    ///
    /// - Parameters:
    ///   - root: The baseline root directory.
    ///   - testID: The test identifier providing module, suite, and name.
    ///   - fingerprint: The environment fingerprint for the filename.
    /// - Returns: The computed baseline file path.
    public static func path(
        root: File.Path,
        testID: Test.ID,
        fingerprint: Swift.String
    ) -> File.Path {
        var result = root

        // module
        result = result / sanitize(testID.module)

        // suite (if present)
        if let suite = testID.suite {
            for component in suite.split(separator: ".") {
                result = result / sanitize(Swift.String(component))
            }
        }

        // test name
        result = result / sanitize(testID.name)

        return result / "\(fingerprint).json"
    }

    private static func sanitize(_ component: Swift.String) -> Swift.String {
        var result = ""
        result.reserveCapacity(component.count)
        for char in component {
            if char.isLetter || char.isNumber || char == "_" || char == "-" {
                result.append(char)
            } else {
                result.append("-")
            }
        }
        return result
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
    }
}

// MARK: - Read Operations

extension Tests.Baseline.Storage {
    /// Loads a stored baseline measurement, or `nil` if no baseline exists.
    ///
    /// - Parameter path: Path to the baseline JSON file.
    /// - Returns: The deserialized measurement, or `nil` if the file does not exist.
    public static func load(at path: File.Path) -> Tests.Measurement? {
        let file = File(path)
        guard file.stat.exists else { return nil }

        do {
            return try file.read.full { span in
                let bytes: [UInt8] = span.withUnsafeBufferPointer { .init($0) }
                let json = try JSON.parse(bytes)
                return try Tests.Measurement(json: json)
            }
        } catch {
            return nil
        }
    }
}

// MARK: - Write Operations

extension Tests.Baseline.Storage {
    /// Saves a measurement as a baseline.
    ///
    /// Creates parent directories as needed. Writes atomically.
    ///
    /// - Parameters:
    ///   - measurement: The measurement to store.
    ///   - path: The destination path.
    /// - Throws: `Storage.Error` on failure.
    public static func save(
        _ measurement: Tests.Measurement,
        to path: File.Path
    ) throws(Tests.Baseline.Storage.Error) {
        // Ensure parent directory exists
        if let parent = path.parent {
            try ensureDirectory(at: parent)
        }

        // Serialize and write atomically
        let bytes = measurement.jsonBytes(pretty: true)
        do {
            try File(path).write.atomic(contentsOf: bytes)
        } catch {
            throw Tests.Baseline.Storage.Error.writeFailed(
                path: Swift.String(describing: path),
                underlying: Swift.String(describing: error)
            )
        }
    }

    /// Ensures a directory exists, creating it recursively if needed.
    private static func ensureDirectory(
        at path: File.Path
    ) throws(Tests.Baseline.Storage.Error) {
        let dir = File.Directory(path)
        if dir.stat.exists { return }

        do {
            try dir.create.recursive()
        } catch {
            throw Tests.Baseline.Storage.Error.directoryCreationFailed(
                path: Swift.String(describing: path),
                underlying: Swift.String(describing: error)
            )
        }
    }
}
