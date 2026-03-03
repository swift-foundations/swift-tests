//
//  Test.Trait.Collection.Modifier.builtins.swift
//  swift-tests
//
//  Modifier factories for all Layer 1 trait types.
//

extension Test.Trait.Collection.Modifier {
    /// Sets a time limit for test execution.
    ///
    /// - Parameter duration: The maximum duration for the test.
    public static func timeLimit(_ duration: Duration) -> Self {
        Self { $0[Test.Trait.TimeLimit.self] = duration }
    }

    /// Adds a tag for filtering and categorization.
    ///
    /// - Parameter name: The tag name.
    public static func tag(_ name: Swift.String) -> Self {
        Self { collection in
            var tags = collection[Test.Trait.Tag.self]
            tags.insert(name)
            collection[Test.Trait.Tag.self] = tags
        }
    }

    /// Sets an enabled condition.
    ///
    /// - Parameters:
    ///   - condition: Whether the test should run.
    ///   - comment: Explanation for why the test is disabled.
    public static func enabled(if condition: Bool, _ comment: Test.Text? = nil) -> Self {
        Self { $0[Test.Trait.Enabled.self] = .init(isEnabled: condition, comment: comment) }
    }

    /// Disables the test.
    ///
    /// - Parameter comment: Explanation for why the test is disabled.
    public static func disabled(_ comment: Test.Text? = nil) -> Self {
        Self { $0[Test.Trait.Enabled.self] = .init(isEnabled: false, comment: comment) }
    }

    /// Adds a bug reference.
    ///
    /// - Parameters:
    ///   - id: The bug identifier.
    ///   - comment: Additional context.
    public static func bug(_ id: Swift.String, _ comment: Test.Text? = nil) -> Self {
        Self { $0[Test.Trait.Bug.self] = .init(id: id, comment: comment) }
    }

    /// Marks the test for serial execution (not in parallel).
    public static var serialized: Self {
        Self { $0[Test.Trait.Serialized.self] = true }
    }

    /// Marks the test for mutual exclusion within the global group.
    public static var exclusive: Self {
        exclusive(group: Test.Trait.Exclusive.globalGroup)
    }

    /// Marks the test for mutual exclusion within a specific group.
    ///
    /// - Parameter group: The exclusion group name.
    public static func exclusive(group: Swift.String) -> Self {
        Self { $0[Test.Trait.Exclusive.self] = .init(group: group) }
    }

    /// Configures timed benchmark execution.
    ///
    /// - Parameters:
    ///   - iterations: Number of measurement runs (default: 10).
    ///   - warmup: Number of untimed warmup runs (default: 0).
    ///   - threshold: Optional performance budget.
    ///   - metric: Metric to check against threshold (default: .median).
    ///   - trackAllocations: Whether to track memory allocations per iteration (default: false).
    public static func timed(
        iterations: Int = 10,
        warmup: Int = 0,
        threshold: Duration? = nil,
        metric: Test.Benchmark.Metric = .median,
        trackAllocations: Bool = false
    ) -> Self {
        Self {
            $0[Test.Trait.Timed.self] = .init(
                iterations: iterations,
                warmup: warmup,
                printResults: true,
                threshold: threshold,
                metric: metric,
                trackAllocations: trackAllocations
            )
        }
    }
}
