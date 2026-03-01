// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-tests open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-tests project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

public import Test_Primitives

extension Test {
    /// A test registration record created by @Test macro expansion.
    ///
    /// Each @Test macro expands to a factory function that creates and returns
    /// a boxed `Registration`. Discovery collects these at runtime via `dlsym`.
    public struct Registration: Sendable {
        /// The test identifier.
        public let id: Test.ID

        /// Modifiers that configure this test's trait collection.
        public let modifiers: [Test.Trait.Collection.Modifier]

        /// The test body to execute.
        public let body: Test.Body

        /// Optional suite ID if this test belongs to a suite.
        public let suiteID: Swift.String?

        /// Creates a test registration.
        ///
        /// - Parameters:
        ///   - id: The test identifier.
        ///   - modifiers: Modifiers for the trait collection.
        ///   - body: The test body.
        ///   - suiteID: Optional suite identifier.
        public init(
            id: Test.ID,
            modifiers: [Test.Trait.Collection.Modifier] = [],
            body: Test.Body,
            suiteID: Swift.String? = nil
        ) {
            self.id = id
            self.modifiers = modifiers
            self.body = body
            self.suiteID = suiteID
        }
    }
}
