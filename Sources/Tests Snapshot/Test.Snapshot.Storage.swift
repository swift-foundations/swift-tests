//
//  Test.Snapshot.Storage.swift
//  swift-tests
//
//  Snapshot file storage using swift-file-system.
//

public import File_System
public import Test_Primitives

extension Test.Snapshot {
    /// Handles snapshot file I/O.
    ///
    /// Storage provides methods for reading, writing, and locating snapshot files.
    /// Uses `swift-file-system` for Foundation-free file operations.
    ///
    /// ## Path Convention
    ///
    /// Snapshots are stored flat relative to the test file:
    /// ```
    /// <testDir>/.snapshots/<name>.<ext>
    /// ```
    ///
    /// When no `name` is provided, the function name and counter are used:
    /// ```
    /// <testDir>/.snapshots/<function>.<counter>.<ext>
    /// ```
    ///
    /// An optional ``Test.Snapshot.Configuration/subdirectory`` adds grouping:
    /// ```
    /// <testDir>/.snapshots/<subdirectory>/<name>.<ext>
    /// ```
    ///
    /// The base directory defaults to `.snapshots` but can be overridden
    /// via ``Test.Snapshot.Configuration/snapshotDirectory``.
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
    ///   - snapshotDirectory: Custom snapshot directory. When `nil`, defaults to `.snapshots`.
    ///   - subdirectory: Optional subdirectory within the snapshot directory.
    /// - Returns: The computed snapshot file path.
    public static func path(
        testFilePath: Swift.String,
        function: Swift.String,
        name: Swift.String?,
        counter: Int,
        pathExtension: Swift.String,
        snapshotDirectory: File.Path? = nil,
        subdirectory: File.Path.Component? = nil
    ) -> File.Path {
        let testPath: File.Path = File.Path(stringLiteral: testFilePath)
        let testDir = testPath.parent ?? testPath

        var snapshotDir = snapshotDirectory ?? (testDir / ".snapshots")
        if let subdirectory {
            // No `/=` overload for File.Path; `/` is a heterogeneous path-append (Path / Path.Component).
            // swiftlint:disable:next shorthand_operator
            snapshotDir = snapshotDir / subdirectory
        }

        if let name {
            return snapshotDir / "\(name).\(pathExtension)"
        } else {
            let cleanFunction = functionName(function)
            return snapshotDir / "\(cleanFunction).\(counter).\(pathExtension)"
        }
    }

    /// Extracts the function name without parentheses and parameters.
    ///
    /// `testFoo(bar:)` → `testFoo`
    private static func functionName(_ function: Swift.String) -> Swift.String {
        if let parenIndex = function.firstIndex(of: "(") {
            return Swift.String(function[..<parenIndex])
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
    public static func reference(at path: File.Path) -> [Byte]? {
        let file = File(path)
        guard file.stat.exists else { return nil }

        do {
            return try file.read.full { span in
                span.withUnsafeBufferPointer { unsafe Array($0) }
            }
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
    /// - Throws: `Storage.Error` on failure.
    public static func write(
        bytes: [Byte],
        to path: File.Path
    ) throws(Self.Error) {
        // Ensure parent directory exists
        if let parent = path.parent {
            try ensure(directory: parent)
        }

        // Write atomically
        do {
            try File(path).write.atomic(contentsOf: bytes)
        } catch {
            throw Self.Error.writeFailed(
                path: path,
                underlying: Swift.String(describing: error)
            )
        }
    }

    /// Ensures a directory exists, creating it if needed.
    ///
    /// - Parameter directory: The directory path.
    /// - Throws: `Storage.Error` on failure.
    public static func ensure(directory path: File.Path) throws(Self.Error) {
        let dir = File.Directory(path)

        // If already exists, we're done
        if dir.stat.exists {
            return
        }

        // Create recursively (creates parent directories too)
        do {
            try dir.create.recursive()
        } catch {
            throw Self.Error.directoryCreationFailed(
                path: path,
                underlying: Swift.String(describing: error)
            )
        }
    }
}

// MARK: - Errors

extension Test.Snapshot.Storage {
    /// Errors that can occur during snapshot storage operations.
    public enum Error: Swift.Error, Sendable {
        /// Failed to read a snapshot file.
        case readFailed(path: File.Path, underlying: Swift.String)

        /// Failed to write a snapshot file.
        case writeFailed(path: File.Path, underlying: Swift.String)

        /// Failed to create the snapshot directory.
        case directoryCreationFailed(path: File.Path, underlying: Swift.String)
    }
}

extension Test.Snapshot.Storage.Error: CustomStringConvertible {
    public var description: Swift.String {
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
