//
//  Test.Reporter.Sink.swift
//  swift-tests
//
//  ~Copyable event sink.
//

public import Test_Primitives

extension Test.Reporter {
    /// A sink that receives test events.
    ///
    /// `Sink` is a ~Copyable type that enforces exactly-once finish semantics.
    /// Events are sent via ``send(_:)`` and the sink is finalized with ``finish()``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// var sink = reporter.makeSink()
    /// await sink.send(Test.Event(kind: .runStarted))
    /// await sink.send(Test.Event(id: testID, kind: .testStarted))
    /// // ... more events ...
    /// await sink.finish()
    /// // sink is consumed - cannot be used again
    /// ```
    ///
    /// ## Ownership
    ///
    /// The ~Copyable constraint ensures:
    /// - Each sink is finished exactly once
    /// - Events cannot be sent after finish
    /// - No accidental sink duplication
    public struct Sink: ~Copyable, Sendable {
        /// The underlying implementation.
        private let _impl: any SinkImplementation

        /// Creates a sink from an implementation.
        ///
        /// - Parameter impl: The sink implementation.
        public init(_ impl: consuming some SinkImplementation) {
            self._impl = impl
        }

        /// Sends an event to the sink.
        ///
        /// - Parameter event: The event to send.
        public func send(_ event: Test.Event) async {
            await _impl.send(event)
        }

        /// Finishes the sink, performing any cleanup.
        ///
        /// This consumes the sink - it cannot be used after calling this method.
        public consuming func finish() async {
            await _impl.finish()
        }
    }
}

// MARK: - SinkImplementation Protocol

extension Test.Reporter {
    /// Protocol for sink implementations.
    ///
    /// Implement this protocol to create custom event sinks.
    /// Implementations must be `Sendable` for use in concurrent contexts.
    ///
    /// ## Example
    ///
    /// ```swift
    /// final class JSONFileSink: Test.Reporter.SinkImplementation, @unchecked Sendable {
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
    public protocol SinkImplementation: Sendable {
        /// Receives an event.
        ///
        /// - Parameter event: The event to process.
        func send(_ event: Test.Event) async

        /// Finishes the sink, performing any cleanup.
        func finish() async
    }
}
