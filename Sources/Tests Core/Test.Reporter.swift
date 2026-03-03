//
//  Test.Reporter.swift
//  swift-tests
//
//  Reporter factory type.
//

public import Test_Primitives

extension Test {
    /// A factory for creating test event sinks.
    ///
    /// `Reporter` is a concrete type (not a protocol) that creates
    /// ``Test/Reporter/Sink`` instances for receiving test events.
    /// This design enables dynamic reporter selection without generics.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Use the built-in console reporter
    /// let reporter = Test.Reporter.console
    ///
    /// // Or create a custom reporter
    /// let custom = Test.Reporter {
    ///     Test.Reporter.Sink(MyCustomSink())
    /// }
    ///
    /// // Dynamic selection
    /// let reporter = isCI ? .console : .custom(...)
    /// ```
    ///
    /// ## Design Rationale
    ///
    /// Using a concrete type instead of a protocol avoids:
    /// - Generic `Test.Runner<R: Reporter>` (awkward ergonomics)
    /// - Type erasure complexity with ~Copyable
    ///
    /// The closure-based factory enables polymorphism while keeping
    /// `Test.Runner` non-generic.
    public struct Reporter: Sendable {
        /// The factory closure that creates sinks.
        private let _makeSink: @Sendable () -> Sink

        /// Creates a reporter with a sink factory.
        ///
        /// - Parameter makeSink: A closure that creates a new sink.
        public init(_ makeSink: @escaping @Sendable () -> Sink) {
            self._makeSink = makeSink
        }

        /// Creates a new sink for receiving events.
        ///
        /// Each call creates a fresh sink instance.
        ///
        /// - Returns: A new sink ready to receive events.
        public func sink() -> Sink {
            _makeSink()
        }
    }
}
