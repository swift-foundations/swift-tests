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

// MARK: - Test.Plan.Entry Factory

extension Tests_Core.Test.Plan.Entry {
    /// Creates a plan entry with sensible defaults.
    ///
    /// ```swift
    /// let entry = Test.Plan.Entry.stub("myTest")
    /// ```
    public static func stub(
        _ name: Swift.String,
        module: Swift.String = "TestModule",
        traits: [Tests_Core.Test.Trait] = [],
        body: Tests_Core.Test.Body = .sync {}
    ) -> Self {
        .init(
            id: .stub(name, module: module),
            traits: traits,
            body: body
        )
    }
}
