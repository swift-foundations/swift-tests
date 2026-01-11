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
        /// - Parameter body: The synchronous closure to execute.
        /// - Returns: A test body wrapping the closure.
        public static func sync(
            _ body: @escaping @Sendable () throws -> Void
        ) -> Body {
            Body(kind: .sync(body))
        }

        /// Creates an asynchronous test body.
        ///
        /// - Parameter body: The asynchronous closure to execute.
        /// - Returns: A test body wrapping the closure.
        public static func `async`(
            _ body: @escaping @Sendable () async throws -> Void
        ) -> Body {
            Body(kind: .async(body))
        }

        private init(kind: Kind) {
            self.kind = kind
        }

        /// Executes the test body.
        ///
        /// For synchronous bodies, this executes immediately.
        /// For asynchronous bodies, this suspends until completion.
        ///
        /// - Throws: Any error thrown by the test body.
        public func run() async throws {
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
        case sync(@Sendable () throws -> Void)
        case `async`(@Sendable () async throws -> Void)
    }
}
