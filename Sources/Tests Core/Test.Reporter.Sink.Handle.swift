//
//  Test.Reporter.Sink.Handle.swift
//  swift-tests
//
//  Copyable handle for concurrent event emission.
//

public import Test_Primitives

extension Test.Reporter.Sink {
    /// A copyable, sendable handle for concurrent event emission.
    ///
    /// Since ``Test/Reporter/Sink`` is `~Copyable` (to enforce exactly-once
    /// `finish()` semantics), it cannot be captured in multiple task group
    /// closures. `Handle` shares the underlying `SinkImplementation` reference
    /// and can be freely copied across concurrent tasks.
    ///
    /// Obtain a handle from a sink before starting concurrent work:
    ///
    /// ```swift
    /// let sink = reporter.makeSink()
    /// let handle = sink.handle
    /// // ... pass handle to concurrent tasks ...
    /// await sink.finish()
    /// ```
    public struct Handle: Sendable {
        @usableFromInline
        let _impl: any Test.Reporter.SinkImplementation

        @usableFromInline
        init(_impl: any Test.Reporter.SinkImplementation) {
            self._impl = _impl
        }

        /// Sends an event through the underlying sink.
        ///
        /// - Parameter event: The event to send.
        @inlinable
        public func send(_ event: Test.Event) async {
            await _impl.send(event)
        }
    }

    /// Returns a copyable handle for concurrent event emission.
    ///
    /// The handle shares this sink's underlying implementation. Events
    /// sent through the handle are equivalent to calling ``send(_:)``
    /// on the sink directly.
    @inlinable
    public var handle: Handle {
        Handle(_impl: _impl)
    }
}
