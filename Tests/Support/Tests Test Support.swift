public import Tests
public import Test_Primitives

// MARK: - Tests.Measurement Factory

extension Tests.Measurement {
    /// Creates a measurement from millisecond integer values.
    ///
    /// Simplifies test data construction:
    /// ```swift
    /// let measurement = Tests.Measurement.with([10, 20, 30, 40, 50])
    /// #expect(measurement.median == .milliseconds(30))
    /// ```
    public static func with(_ milliseconds: [Int]) -> Self {
        Self(durations: milliseconds.map { .milliseconds($0) })
    }
}

// MARK: - Test.Benchmark.Measurement Factory

extension Test_Primitives.Test.Benchmark.Measurement {
    /// Creates a benchmark measurement from millisecond integer values.
    ///
    /// ```swift
    /// let m = Test_Primitives.Test.Benchmark.Measurement.with([10, 20, 30])
    /// ```
    public static func with(_ milliseconds: [Int]) -> Self {
        Self(durations: milliseconds.map { .milliseconds($0) })
    }
}

// MARK: - Test.Plan.Entry Factory

extension Test_Primitives.Test.Plan.Entry {
    /// Creates a plan entry with sensible defaults.
    ///
    /// ```swift
    /// let entry = Test_Primitives.Test.Plan.Entry.stub("myTest")
    /// ```
    public static func stub(
        _ name: Swift.String,
        module: Swift.String = "TestModule",
        traits: [Test_Primitives.Test.Trait] = [],
        body: Test_Primitives.Test.Body = .sync {}
    ) -> Self {
        .init(
            id: .stub(name, module: module),
            traits: traits,
            body: body
        )
    }
}
