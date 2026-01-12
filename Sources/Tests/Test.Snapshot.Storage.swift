//
//  Test.Snapshot.Storage.swift
//  swift-tests
//
//  Snapshot file storage using swift-file-system.
//

public import Test_Primitives
public import File_System

extension Test.Snapshot {
    /// Handles snapshot file I/O.
    ///
    /// Storage provides methods for reading, writing, and locating snapshot files.
    /// Uses `swift-file-system` for Foundation-free file operations.
    ///
    /// ## Path Convention
    ///
    /// Snapshots are stored relative to the test file:
    /// ```
    /// <testDir>/__Snapshots__/<TestFile>/<function>.<counter|name>.<ext>
    /// ```
    ///
    /// Example: `Tests/__Snapshots__/UserTests/testUserJSON.1.json`
    public enum Storage {}
}

// MARK: - Path Generation

extension Test.Snapshot.Storage {
    /// Computes the snapshot file path.
    ///
    /// - Parameters:
    ///   - testFilePath: Full path to the test file (from `#filePath`).
    ///   - function: Test function name (from `#function`).
    ///   - name: Optional custom snapshot name.
    ///   - counter: Counter for unnamed snapshots in the same test.
    ///   - pathExtension: File extension for the snapshot.
    /// - Returns: The computed snapshot file path.
    public static func path(
        testFilePath: String,
        function: String,
        name: String?,
        counter: Int,
        pathExtension: String
    ) -> File.Path {
        // Parse test file path to get directory and filename
        let testPath: File.Path = File.Path(stringLiteral: testFilePath)
        let testDir = testPath.parent ?? testPath
        let testFileName = testPath.stem ?? "Unknown"

        // Build snapshot directory: <testDir>/__Snapshots__/<TestFile>/
        let snapshotDir = testDir / "__Snapshots__" / testFileName

        // Build filename: <function>.<counter|name>.<ext>
        let identifier: String
        if let name = name {
            identifier = sanitizePathComponent(name)
        } else {
            identifier = String(counter)
        }

        // Clean function name (remove parentheses and parameters)
        let cleanFunction = sanitizeFunctionName(function)

        let filename = "\(cleanFunction).\(identifier).\(pathExtension)"
        return snapshotDir / filename
    }

    /// Sanitizes a string for use as a path component.
    ///
    /// Replaces non-alphanumeric characters with hyphens.
    private static func sanitizePathComponent(_ string: String) -> String {
        var result = ""
        result.reserveCapacity(string.count)
        for char in string {
            if char.isLetter || char.isNumber || char == "_" || char == "-" {
                result.append(char)
            } else {
                result.append("-")
            }
        }
        // Remove leading/trailing hyphens and collapse multiple hyphens
        return result
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
    }

    /// Cleans a function name for use in filenames.
    ///
    /// Removes parentheses and parameters: `testFoo(bar:)` → `testFoo`
    private static func sanitizeFunctionName(_ function: String) -> String {
        if let parenIndex = function.firstIndex(of: "(") {
            return String(function[..<parenIndex])
        }
        return function
    }
}

// MARK: - Read Operations

extension Test.Snapshot.Storage {
    /// Reads a reference snapshot from disk.
    ///
    /// - Parameter path: Path to the snapshot file.
    /// - Returns: The file contents, or `nil` if the file doesn't exist.
    public static func readReference(at path: File.Path) -> [UInt8]? {
        let file = File(path)
        guard file.stat.exists else { return nil }

        do {
            return try file.read.full()
        } catch {
            return nil
        }
    }

    /// Checks if a reference snapshot exists.
    ///
    /// - Parameter path: Path to check.
    /// - Returns: `true` if the snapshot file exists.
    public static func exists(at path: File.Path) -> Bool {
        File(path).stat.exists
    }
}

// MARK: - Write Operations

extension Test.Snapshot.Storage {
    /// Writes a snapshot to disk.
    ///
    /// Creates parent directories as needed.
    ///
    /// - Parameters:
    ///   - bytes: The snapshot content.
    ///   - path: The destination path.
    /// - Throws: `StorageError` on failure.
    public static func write(
        bytes: [UInt8],
        to path: File.Path
    ) throws(Test.Snapshot.StorageError) {
        // Ensure parent directory exists
        if let parent = path.parent {
            try ensureDirectory(at: parent)
        }

        // Write atomically
        do {
            try File(path).write.atomic(bytes)
        } catch {
            throw Test.Snapshot.StorageError.writeFailed(
                path: String(path),
                underlying: String(describing: error)
            )
        }
    }

    /// Ensures a directory exists, creating it if needed.
    ///
    /// - Parameter path: The directory path.
    /// - Throws: `StorageError` on failure.
    public static func ensureDirectory(at path: File.Path) throws(Test.Snapshot.StorageError) {
        let dir = File.Directory(path)

        // If already exists, we're done
        if dir.stat.exists {
            return
        }

        // Create recursively (creates parent directories too)
        do {
            try dir.create.recursive()
        } catch {
            throw Test.Snapshot.StorageError.directoryCreationFailed(
                path: String(path),
                underlying: String(describing: error)
            )
        }
    }
}

// MARK: - Errors

extension Test.Snapshot {
    /// Errors that can occur during snapshot storage operations.
    public enum StorageError: Error, Sendable {
        /// Failed to read a snapshot file.
        case readFailed(path: String, underlying: String)

        /// Failed to write a snapshot file.
        case writeFailed(path: String, underlying: String)

        /// Failed to create the snapshot directory.
        case directoryCreationFailed(path: String, underlying: String)
    }
}

extension Test.Snapshot.StorageError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .readFailed(let path, let underlying):
            return "Failed to read snapshot at '\(path)': \(underlying)"
        case .writeFailed(let path, let underlying):
            return "Failed to write snapshot to '\(path)': \(underlying)"
        case .directoryCreationFailed(let path, let underlying):
            return "Failed to create snapshot directory '\(path)': \(underlying)"
        }
    }
}
