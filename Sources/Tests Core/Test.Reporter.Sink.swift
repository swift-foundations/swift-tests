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
    /// var sink = reporter.sink()
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
        private let _impl: any Implementation

        /// Creates a sink from an implementation.
        ///
        /// - Parameter impl: The sink implementation.
        public init(_ impl: consuming some Implementation) {
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

        /// Projects the send-only capability.
        ///
        /// `Sender` is the Copyable, Sendable projection of this ~Copyable
        /// sink. It exposes only ``Sender/send(_:)`` — the type system
        /// prevents calling ``finish()`` through a Sender.
        ///
        /// This follows the ~Copyable capability projection pattern: the
        /// affine owner (Sink) retains the consuming operation while
        /// projecting the unrestricted operation as a separate Copyable type.
        ///
        /// Non-consuming: the Sink retains ownership and can still be finished.
        public var sender: Sender {
            Sender(_impl: _impl)
        }

        /// The Copyable, Sendable send-only projection of a ~Copyable Sink.
        ///
        /// Multiple concurrent tasks can hold references to the same `Sender`.
        /// The type system enforces the capability split — `Sender` has
        /// ``send(_:)`` but no `finish()`. Incorrect code does not compile.
        ///
        /// Obtain a sender before starting concurrent work:
        ///
        /// ```swift
        /// let sink = reporter.sink()
        /// let sender = sink.sender
        /// // ... pass sender to concurrent tasks ...
        /// await sink.finish()
        /// ```
        public struct Sender: Sendable {
            private let _impl: any Implementation

            fileprivate init(_impl: any Implementation) {
                self._impl = _impl
            }

            /// Sends an event through the underlying sink.
            ///
            /// - Parameter event: The event to send.
            public func send(_ event: Test.Event) async {
                await _impl.send(event)
            }
        }
    }
}

