//
//  Tests.History.Storage.Error.swift
//  swift-tests
//
//  Errors from history file operations.
//

extension Tests.History.Storage {
    /// Errors from history storage operations.
    public enum Error: Swift.Error, Sendable {
        /// Failed to write to the history file.
        case writeFailed(path: Swift.String, underlying: Swift.String)

        /// Failed to create the parent directory.
        case directoryCreationFailed(path: Swift.String, underlying: Swift.String)
    }
}
