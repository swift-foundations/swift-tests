import Synchronization
public import Test_Primitives
public import Tests

// MARK: - Test.Benchmark.Measurement Factory

extension Test_Primitives.Test.Benchmark.Measurement {
    /// Creates a measurement from millisecond integer values.
    ///
    /// Simplifies test data construction:
    /// ```swift
    /// let measurement = Test.Benchmark.Measurement.with([10, 20, 30, 40, 50])
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
        modifiers: [Tests_Core.Test.Trait.Collection.Modifier] = [],
        body: Tests_Core.Test.Body = .sync {}
    ) -> Self {
        .init(
            id: .stub(name, module: module),
            modifiers: modifiers,
            body: body
        )
    }
}

// MARK: - Spy Sink

/// A sink that captures all events for test assertions.
public final class SpySink: Tests_Core.Test.Reporter.Sink.Implementation, @unchecked Sendable {
    private let _events = Mutex<[Test_Primitives.Test.Event]>([])

    public init() {}

    public var events: [Test_Primitives.Test.Event] {
        _events.withLock { $0 }
    }

    public func send(_ event: Test_Primitives.Test.Event) async {
        _events.withLock { $0.append(event) }
    }

    public func finish() async {}
}

// MARK: - Spy Reporter

/// Creates a reporter + spy pair for test assertions.
public enum SpyReporter {
    public static func make() -> (Tests_Core.Test.Reporter, SpySink) {
        let spy = SpySink()
        let reporter = Tests_Core.Test.Reporter {
            Tests_Core.Test.Reporter.Sink(spy)
        }
        return (reporter, spy)
    }
}
