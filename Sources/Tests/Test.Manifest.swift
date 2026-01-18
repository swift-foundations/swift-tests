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

import Synchronization

extension Test {
    /// Manifest of test factory symbol names for manual registration.
    ///
    /// This is the canonical API for registering tests without macros.
    /// Users can register test factory symbol names which will be discovered
    /// via dlsym at runtime.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// // Register factory names manually
    /// Test.Manifest.register("__test_myTest")
    ///
    /// // Or register multiple at once
    /// Test.Manifest.register([
    ///     "__test_addition",
    ///     "__test_subtraction",
    /// ])
    /// ```
    ///
    /// In the full implementation, this would be generated at compile time
    /// by collecting all @Test macro expansions.
    public enum Manifest {
        /// Thread-safe storage for factory names.
        private static let _factoryNames = Mutex<[String]>([])

        /// Gets the current list of factory names.
        @inlinable
        public static func getFactoryNames() -> [String] {
            _factoryNames.withLock { $0 }
        }

        /// Registers a factory name at runtime.
        ///
        /// This is a fallback for when compile-time collection is not available.
        @inlinable
        public static func register(_ name: String) {
            _factoryNames.withLock { names in
                names.append(name)
            }
        }

        /// Registers multiple factory names at runtime.
        @inlinable
        public static func register(_ names: [String]) {
            _factoryNames.withLock { existing in
                existing.append(contentsOf: names)
            }
        }
    }
}
