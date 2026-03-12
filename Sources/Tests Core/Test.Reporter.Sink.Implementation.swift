//
//  Test.Reporter.Sink.Implementation.swift
//  swift-tests
//
//  Protocol for sink implementations.
//

extension Test.Reporter.Sink {
    /// Protocol for sink implementations.
    ///
    /// Implement this protocol to create custom event sinks.
    /// Implementations must be `Sendable` for use in concurrent contexts.
    ///
    /// ## Example
    ///
    /// ```swift
    /// final class JSONFileSink: Test.Reporter.Sink.Implementation, @unchecked Sendable {
    ///     private let fileHandle: FileHandle
    ///
    ///     init(path: Swift.String) throws {
    ///         self.fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
    ///     }
    ///
    ///     func send(_ event: Test.Event) async {
    ///         let data = try! JSONEncoder().encode(event)
    ///         fileHandle.write(data)
    ///         fileHandle.write("\n".data(using: .utf8)!)
    ///     }
    ///
    ///     func finish() async {
    ///         fileHandle.closeFile()
    ///     }
    /// }
    /// ```
    public protocol Implementation: Sendable {
        /// Receives an event.
        ///
        /// - Parameter event: The event to process.
        func send(_ event: Test.Event) async

        /// Finishes the sink, performing any cleanup.
        func finish() async
    }
}
