//
//  Test.Reporter.Sink.swift
//  swift-tests
//
//  ~Copyable event sink with witness-based storage.
//

public import Test_Primitives

extension Test.Reporter {
    /// A sink that receives test events.
    ///
    /// `Sink` is a ~Copyable type that enforces exactly-once finish semantics.
    /// Events are sent via ``send(_:)`` and the sink is finalized with ``finish()``.
    ///
    /// ## Storage
    ///
    /// Sink stores captured closures (witnesses), not protocol existentials.
    /// The `some Implementation` in ``init(_:)`` opens the concrete type at
    /// the capture site — no `any` boxing occurs.
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
        private let _send: @Sendable (Test.Event) async -> Void
        private let _finish: @Sendable () async -> Void

        /// Creates a sink from an implementation.
        ///
        /// The concrete type behind `some Implementation` is captured directly
        /// in closures — no existential boxing.
        ///
        /// - Parameter impl: The sink implementation.
        public init(_ impl: some Implementation) {
            self._send = { event in await impl.send(event) }
            self._finish = { await impl.finish() }
        }

        /// Creates a sink from witness closures.
        ///
        /// Used by ``tee(_:_:)`` for closure composition.
        private init(
            send: @escaping @Sendable (Test.Event) async -> Void,
            finish: @escaping @Sendable () async -> Void
        ) {
            self._send = send
            self._finish = finish
        }

        /// Sends an event to the sink.
        ///
        /// - Parameter event: The event to send.
        public func send(_ event: Test.Event) async {
            await _send(event)
        }

        /// Finishes the sink, performing any cleanup.
        ///
        /// This consumes the sink - it cannot be used after calling this method.
        public consuming func finish() async {
            await _finish()
        }

        // MARK: - Composition

        /// Creates a compound sink that forwards to two sinks.
        ///
        /// Both input sinks are consumed. The returned sink sends events
        /// to both and finishes both when it finishes.
        ///
        /// - Parameters:
        ///   - first: The first sink (consumed).
        ///   - second: The second sink (consumed).
        /// - Returns: A compound sink.
        public static func tee(
            _ first: consuming Self,
            _ second: consuming Self
        ) -> Self {
            let sendA = first._send
            let sendB = second._send
            let finishA = first._finish
            let finishB = second._finish
            return Self(
                send: { event in
                    await sendA(event)
                    await sendB(event)
                },
                finish: {
                    await finishA()
                    await finishB()
                }
            )
        }

        // MARK: - Sender Projection

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
            Sender(_send: _send)
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
            private let _send: @Sendable (Test.Event) async -> Void

            fileprivate init(_send: @escaping @Sendable (Test.Event) async -> Void) {
                self._send = _send
            }

            /// Sends an event through the underlying sink.
            ///
            /// - Parameter event: The event to send.
            public func send(_ event: Test.Event) async {
                await _send(event)
            }
        }
    }
}
