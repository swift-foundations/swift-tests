//
//  Test.Expectation+Factory.swift
//  swift-tests
//
//  Convenience factories for creating and recording expectations.
//

public import Test_Primitives
import Synchronization

// MARK: - ID Counters

private let _expressionCounter = Atomic<UInt64>(0)
private let _expectationCounter = Atomic<UInt64>(0)

private func _nextExpressionID() -> Test.Expression.ID {
    Test.Expression.ID(
        __unchecked: (),
        _expressionCounter.wrappingAdd(1, ordering: .relaxed).newValue
    )
}

private func _nextExpectationID() -> Test.Expectation.ID {
    Test.Expectation.ID(
        __unchecked: (),
        _expectationCounter.wrappingAdd(1, ordering: .relaxed).newValue
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
        if Collector.current == nil {
            Self.externalFailureHandler?(message, location)
        }
        return result
    }
}
