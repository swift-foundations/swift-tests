//
//  Tests.Baseline.Storage.Error.swift
//  swift-tests
//
//  Typed errors for baseline storage operations.
//

extension Tests.Baseline.Storage {
    /// Errors that can occur during baseline storage operations.
    public enum Error: Swift.Error, Sendable {
        /// Failed to read a baseline file.
        case readFailed(path: Swift.String, underlying: Swift.String)

        /// Failed to write a baseline file.
        case writeFailed(path: Swift.String, underlying: Swift.String)

        /// Failed to create the baseline directory.
        case directoryCreationFailed(path: Swift.String, underlying: Swift.String)

        /// No baseline exists and recording mode forbids creation.
        case baselineMissing(path: Swift.String)
    }
}

extension Tests.Baseline.Storage.Error: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .readFailed(let path, let underlying):
            return "Failed to read baseline at '\(path)': \(underlying)"
        case .writeFailed(let path, let underlying):
            return "Failed to write baseline to '\(path)': \(underlying)"
        case .directoryCreationFailed(let path, let underlying):
            return "Failed to create baseline directory '\(path)': \(underlying)"
        case .baselineMissing(let path):
            return "No baseline exists at '\(path)' and recording mode is 'never'"
        }
    }
}
