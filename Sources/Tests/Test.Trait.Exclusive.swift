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

// MARK: - Exclusive Trait

extension Test.Trait {
    /// The trait name for exclusive execution.
    internal static let exclusiveTraitName = "__exclusive__"

    /// The default group for global exclusion.
    public static let globalExclusionGroup = "__global__"

    /// Creates a trait for mutual exclusion between suites.
    ///
    /// When applied to sibling suites, only one suite executes at a time.
    /// Tests within each suite still run in parallel (unless `.serialized` is also applied).
    ///
    /// **Important**: This provides mutual exclusion, not ordering. The order in which
    /// suites run is determined by the test runner, not by this trait.
    /// The guarantee is that they will not overlap, not that they run in a specific sequence.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @Suite enum Test {
    ///     @Suite(.exclusive) struct Unit {}
    ///     @Suite(.exclusive) struct EdgeCase {}
    ///     @Suite(.exclusive, .serialized) struct Performance {}
    /// }
    /// ```
    ///
    /// Execution:
    /// - One of Unit/EdgeCase/Performance acquires the lock and runs (tests in parallel)
    /// - When it completes, another acquires the lock
    /// - Performance tests run serially due to `.serialized`
    public static var exclusive: Self {
        exclusive(group: globalExclusionGroup)
    }

    /// Creates a trait for mutual exclusion within a specific group.
    ///
    /// Suites with the same group are mutually exclusive with each other.
    /// Suites in different groups can run in parallel.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // These are mutually exclusive with each other
    /// @Suite(.exclusive(group: "TypeA")) struct Unit {}
    /// @Suite(.exclusive(group: "TypeA")) struct EdgeCase {}
    ///
    /// // This can run in parallel with TypeA suites
    /// @Suite(.exclusive(group: "TypeB")) struct Other {}
    /// ```
    ///
    /// - Parameter group: A string identifier for the exclusion group.
    ///   Use a fully-qualified name (e.g., "ModuleName.TypeName") to avoid collisions.
    /// - Returns: An exclusive trait for the specified group.
    public static func exclusive(group: String) -> Self {
        .custom(exclusiveTraitName, value: group)
    }
}

// MARK: - Trait Inspection

extension Test.Trait {
    /// Extracts the exclusion group from a trait, if present.
    ///
    /// - Returns: The exclusion group if this is an exclusive trait, nil otherwise.
    public var exclusionGroup: String? {
        guard case .custom(let name, let value) = kind,
              name == Self.exclusiveTraitName else {
            return nil
        }
        return value ?? Self.globalExclusionGroup
    }
}

extension Collection where Element == Test.Trait {
    /// Finds the exclusion group from a collection of traits.
    ///
    /// - Returns: The exclusion group if present.
    public var exclusionGroup: String? {
        for trait in self {
            if let group = trait.exclusionGroup {
                return group
            }
        }
        return nil
    }
}

// Note: ExclusionController is defined in Test.Runner.swift
// and is used by the test runner to handle .exclusive() traits.
