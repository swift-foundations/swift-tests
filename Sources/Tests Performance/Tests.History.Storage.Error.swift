//
//  Tests.History.Storage.Error.swift
//  swift-tests
//
//  Errors from history file operations.
//

public import File_System_Primitives

extension Tests.History.Storage {
    /// Errors from history storage operations.
    public enum Error: Swift.Error, Sendable {
        /// Failed to write to the history file.
        case writeFailed(path: File.Path, underlying: Swift.String)

        /// Failed to create the parent directory.
        case directoryCreationFailed(path: File.Path, underlying: Swift.String)
    }
}
