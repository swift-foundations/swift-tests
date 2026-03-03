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
    /// When no collector is installed (i.e., tests run under Apple's Swift Testing
    /// runner instead of the custom `Test.Runner`), the failure is bridged to
    /// `Testing.Issue.record` so it is not silently dropped.
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
        #if canImport(Testing)
        if Collector.current == nil {
            _bridgeFailureToSwiftTesting(message, at: location)
        }
        #endif
        return result
    }
}

// MARK: - Swift Testing Bridge

#if canImport(Testing)
import Testing

/// Bridges a failure to Apple's Swift Testing when no collector is installed.
///
/// This is the fallback path for tests running under Swift Testing's native
/// runner, where `Collector.current` is `nil` because `Test.Runner` was never
/// instantiated. Without this bridge, failures from `assertInlineSnapshot`,
/// `assertSnapshot`, and all other assertions built on `record(failing:...)`
/// would be silently discarded.
private func _bridgeFailureToSwiftTesting(
    _ message: Swift.String,
    at location: Source.Location
) {
    Testing.Issue.record(
        Testing.Comment(rawValue: message),
        sourceLocation: Testing.SourceLocation(
            fileID: location.fileID,
            filePath: location.filePath ?? location.fileID,
            line: location.line,
            column: location.column
        )
    )
}
#endif
