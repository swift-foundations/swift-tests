//
//  Test.Expectation+Factory.swift
//  swift-tests
//
//  Convenience factories for creating and recording expectations.
//

public import Test_Primitives
import Loader
import Synchronization

// MARK: - ID Counters

private let _expressionCounter = Atomic<UInt64>(0)
private let _expectationCounter = Atomic<UInt64>(0)

func _nextExpressionID() -> Test.Expression.ID {
    Test.Expression.ID(
        _unchecked: _expressionCounter.wrappingAdd(1, ordering: .relaxed).newValue
    )
}

func _nextExpectationID() -> Test.Expectation.ID {
    Test.Expectation.ID(
        _unchecked: _expectationCounter.wrappingAdd(1, ordering: .relaxed).newValue
    )
}

// MARK: - External Failure Handler

extension Test.Expectation {
    /// External failure handler for bridging to test frameworks.
    ///
    /// When no ``Collector`` is installed (i.e., tests run without the
    /// Institute's `Test.Runner`), this handler is called for each failure.
    /// It can be set by a bridge module (e.g., `Tests Apple Testing Bridge`)
    /// to forward failures to the active test runner.
    ///
    /// Set once before tests run; read during test execution.
    /// When the Institute's runner is active, ``Collector/current`` is
    /// non-nil and this handler is never invoked.
    public nonisolated(unsafe) static var externalFailureHandler:
        (@Sendable (_ message: Swift.String, _ location: Source.Location) -> Void)?
}

// MARK: - External Bridge Resolution

extension Test.Expectation {
    /// Lazily resolves and installs the external failure bridge.
    ///
    /// Uses symbol lookup to find `_swift_tests_bridge_install` at runtime.
    /// If the bridge module is linked, its installer is called. If not
    /// linked, the symbol is not found and no action is taken.
    ///
    /// Thread-safe: `static let` guarantees exactly-once initialization.
    private static let _resolveBridge: Void = {
        guard unsafe externalFailureHandler == nil else { return }
        guard let symbol = try? unsafe Loader.Symbol.lookup(
            name: "_swift_tests_bridge_install",
            in: .default
        ) else { return }
        unsafe unsafeBitCast(symbol, to: (@convention(c) () -> Void).self)()
    }()

    /// Reports a failure to the external bridge when no collector is active.
    ///
    /// Called by `expect()` and `require()` to ensure failures surface
    /// under Apple's Swift Testing runner (where ``Collector/current`` is nil).
    ///
    /// On first call, lazily resolves the bridge via symbol lookup.
    ///
    /// - Parameters:
    ///   - message: Description of the failure.
    ///   - location: Source location of the failing assertion.
    static func _reportExternalFailure(
        _ message: Swift.String,
        at location: Source.Location
    ) {
        guard Collector.current == nil else { return }
        _ = _resolveBridge
        unsafe externalFailureHandler?(message, location)
    }
}

// MARK: - Factories

extension Test.Expectation {
    /// Creates a passing expectation.
    ///
    /// - Parameters:
    ///   - sourceCode: Source code representation of the assertion.
    ///   - location: Source location of the assertion.
    /// - Returns: A passing expectation with auto-generated IDs.
    public static func passing(
        sourceCode: Swift.String,
        at location: Source.Location
    ) -> Self {
        let expression = Test.Expression(
            id: _nextExpressionID(),
            sourceCode: sourceCode,
            sourceLocation: location
        )
        return Self(
            id: _nextExpectationID(),
            expression: expression,
            isPassing: true
        )
    }

    /// Creates a failing expectation.
    ///
    /// - Parameters:
    ///   - message: Description of the failure.
    ///   - sourceCode: Source code representation of the assertion.
    ///   - location: Source location of the assertion.
    /// - Returns: A failing expectation with auto-generated IDs.
    public static func failing(
        _ message: Swift.String,
        sourceCode: Swift.String,
        at location: Source.Location
    ) -> Self {
        let expression = Test.Expression(
            id: _nextExpressionID(),
            sourceCode: sourceCode,
            sourceLocation: location
        )
        return Self(
            id: _nextExpectationID(),
            expression: expression,
            isPassing: false,
            failure: Failure(message: Test.Text(message))
        )
    }

    // MARK: - Create + Record

    /// Creates a passing expectation and records it with the current collector.
    ///
    /// - Parameters:
    ///   - sourceCode: Source code representation of the assertion.
    ///   - location: Source location of the assertion.
    /// - Returns: The recorded passing expectation.
    @discardableResult
    public static func record(
        passing sourceCode: Swift.String,
        at location: Source.Location
    ) -> Self {
        let result = passing(sourceCode: sourceCode, at: location)
        Collector.current?.record(result)
        return result
    }

    /// Creates a failing expectation and records it with the current collector.
    ///
    /// When no collector is installed, the failure is forwarded to
    /// ``externalFailureHandler`` if one has been installed by a bridge
    /// module (e.g., `Tests Apple Testing Bridge`).
    ///
    /// - Parameters:
    ///   - message: Description of the failure.
    ///   - sourceCode: Source code representation of the assertion.
    ///   - location: Source location of the assertion.
    /// - Returns: The recorded failing expectation.
    @discardableResult
    public static func record(
        failing message: Swift.String,
        sourceCode: Swift.String,
        at location: Source.Location
    ) -> Self {
        let result = failing(message, sourceCode: sourceCode, at: location)
        Collector.current?.record(result)
        _reportExternalFailure(message, at: location)
        return result
    }
}
