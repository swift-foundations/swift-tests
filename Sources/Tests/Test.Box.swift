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

public import Reference_Primitives

extension Test {
    /// Typealias to Reference.Box for API compatibility.
    ///
    /// Used by @Test macro expansion to box registrations for transfer
    /// via C-compatible function signatures.
    ///
    /// - SeeAlso: `Reference.Box` from swift-reference-primitives
    public typealias Box<T: Sendable> = Reference.Box<T>
}
