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

extension Test {
    /// Test content kind values.
    ///
    /// - Warning: This type is used by the `@Test` macro. Do not use directly.
    public enum __TestContentKind: UInt32 {
        /// A test declaration.
        case test = 0x74657374  // 'test' in ASCII

        /// A suite declaration.
        case suite = 0x73756974  // 'suit' in ASCII

        /// An exit test.
        case exitTest = 0x65786974  // 'exit' in ASCII
    }
}
