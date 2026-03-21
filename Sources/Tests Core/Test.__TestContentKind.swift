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

internal import ASCII_Primitives

extension Test {
    /// FourCC record kind values for test content records.
    ///
    /// Each kind is a big-endian FourCC code built from ASCII character values.
    ///
    /// - Warning: This type is used by the `@Test` macro. Do not use directly.
    public struct __TestContentKind: RawRepresentable, Equatable, Sendable {
        public let rawValue: UInt32

        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
    }
}

extension Test.__TestContentKind {
    /// Constructs a FourCC value from four ASCII bytes (big-endian).
    private static func fourCC(
        _ a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8
    ) -> Self {
        Self(rawValue: UInt32(a) << 24 | UInt32(b) << 16 | UInt32(c) << 8 | UInt32(d))
    }

    /// A test declaration ('test').
    public static let test = fourCC(
        ASCII.Character.Graphic.t,
        ASCII.Character.Graphic.e,
        ASCII.Character.Graphic.s,
        ASCII.Character.Graphic.t
    )

    /// A suite declaration ('suit').
    public static let suite = fourCC(
        ASCII.Character.Graphic.s,
        ASCII.Character.Graphic.u,
        ASCII.Character.Graphic.i,
        ASCII.Character.Graphic.t
    )

    /// An exit test declaration ('exit').
    public static let exitTest = fourCC(
        ASCII.Character.Graphic.e,
        ASCII.Character.Graphic.x,
        ASCII.Character.Graphic.i,
        ASCII.Character.Graphic.t
    )
}
