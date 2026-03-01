//
//  Test.Snapshot.Inline.Rewriter.Error.swift
//  swift-tests
//
//  Errors from inline snapshot source rewriting.
//

public import Test_Primitives

extension Test.Snapshot.Inline.Rewriter {
    /// Errors that occur during inline snapshot source file rewriting.
    public enum Error: Swift.Error, Sendable {
        /// Failed to read the source file.
        ///
        /// - Parameters:
        ///   - path: The file path that could not be read.
        ///   - underlying: Description of the underlying error.
        case readFailed(path: Swift.String, underlying: Swift.String)

        /// Failed to write the modified source file.
        ///
        /// - Parameters:
        ///   - path: The file path that could not be written.
        ///   - underlying: Description of the underlying error.
        case writeFailed(path: Swift.String, underlying: Swift.String)

        /// The call site could not be found at the expected location.
        ///
        /// - Parameters:
        ///   - path: The source file path.
        ///   - line: The expected line number.
        ///   - column: The expected column number.
        case callSiteNotFound(path: Swift.String, line: Int, column: Int)
    }
}
