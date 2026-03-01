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

extension Test.Suite {
    /// A suite registration record created by @Suite macro expansion.
    ///
    /// Suites provide trait inheritance to their contained tests.
    /// Discovery reads suites first, then applies trait inheritance to tests.
    public struct Registration: Sendable {
        /// Unique identifier for this suite.
        public let id: Test.ID

        /// Modifiers that configure this suite's trait collection.
        public let modifiers: [Test.Trait.Collection.Modifier]

        /// Creates a suite registration.
        ///
        /// - Parameters:
        ///   - id: Suite identifier.
        ///   - modifiers: Modifiers for the trait collection.
        public init(
            id: Test.ID,
            modifiers: [Test.Trait.Collection.Modifier] = []
        ) {
            self.id = id
            self.modifiers = modifiers
        }
    }
}
