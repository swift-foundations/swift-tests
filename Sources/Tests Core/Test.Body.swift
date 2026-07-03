//
//  Test.Body.swift
//  swift-tests
//
//  Test body wrapper.
//

public import Test_Primitives

extension Test {
    /// A wrapper for test body closures.
    ///
    /// `Body` encapsulates either a synchronous or asynchronous test body,
    /// providing a uniform interface for the test runner.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Synchronous body
    /// let syncBody = Test.Body.sync {
    ///     #expect(1 + 1 == 2)
    /// }
    ///
    /// // Asynchronous body
    /// let asyncBody = Test.Body.async {
    ///     let result = await fetchData()
    ///     #expect(result.isValid)
    /// }
    /// ```
    public struct Body: Sendable {
        /// The kind of body (sync or async).
        private let kind: Kind

        /// Creates a synchronous test body.
        ///
        /// Wraps the user closure, converting any thrown error to ``Error``.
        ///
        /// - Parameter body: The synchronous closure to execute.
        /// - Returns: A test body wrapping the closure.
        public static func sync<E: Swift.Error>(
            _ body: @escaping @Sendable () throws(E) -> Void
        ) -> Self {
            Self(
                kind: .sync({ () throws(Error) in
                    do {
                        try body()
                    } catch {
                        if error is Test.Requirement.Failed {
                            throw Error.requirementFailed
                        }
                        throw Error.caught(
                            type: Swift.String(describing: type(of: error)),
                            description: Swift.String(describing: error)
                        )
                    }
                })
            )
        }

        /// Creates an asynchronous test body.
        ///
        /// Wraps the user closure, converting any thrown error to ``Error``.
        ///
        /// - Parameter body: The asynchronous closure to execute.
        /// - Returns: A test body wrapping the closure.
        public static func `async`<E: Swift.Error>(
            _ body: @escaping @Sendable () async throws(E) -> Void
        ) -> Self {
            Self(
                kind: .async({ () async throws(Error) in
                    do {
                        try await body()
                    } catch {
                        if error is Test.Requirement.Failed {
                            throw Error.requirementFailed
                        }
                        throw Error.caught(
                            type: Swift.String(describing: type(of: error)),
                            description: Swift.String(describing: error)
                        )
                    }
                })
            )
        }

        private init(kind: Kind) {
            self.kind = kind
        }

        /// Executes the test body.
        ///
        /// For synchronous bodies, this executes immediately.
        /// For asynchronous bodies, this suspends until completion.
        ///
        /// - Throws: ``Error`` wrapping any error thrown by the test body.
        public func run() async throws(Error) {
            switch kind {
            case .sync(let body):
                try body()

            case .async(let body):
                try await body()
            }
        }

        /// Whether this is a synchronous body.
        public var isSync: Bool {
            if case .sync = kind { return true }
            return false
        }

        /// Whether this is an asynchronous body.
        public var isAsync: Bool {
            if case .async = kind { return true }
            return false
        }
    }
}

// MARK: - Kind

extension Test.Body {
    /// The kind of test body.
    private enum Kind: Sendable {
        case sync(@Sendable () throws(Test.Body.Error) -> Void)
        case `async`(@Sendable () async throws(Test.Body.Error) -> Void)
    }
}

// MARK: - Error

extension Test.Body {
    /// Error wrapping any error thrown by user test code.
    public enum Error: Swift.Error, Sendable {
        /// A user test error was caught and wrapped.
        case caught(type: Swift.String, description: Swift.String)

        /// A requirement failed and was already recorded as an expectation.
        ///
        /// The runner should not emit an additional `.errorCaught` issue
        /// because the collector already contains the structured expectation.
        case requirementFailed
    }
}
