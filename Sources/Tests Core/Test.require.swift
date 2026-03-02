//
//  Test.require.swift
//  swift-tests
//
//  Requirement API for test assertions with typed throws.
//

public import Test_Primitives
import Synchronization

// MARK: - Require Functions

/// Evaluates a requirement and throws if it fails.
///
/// Use `require` when a failing condition should stop test execution.
/// Unlike `expect`, a failing requirement throws immediately.
///
/// ## Example
///
/// ```swift
/// @Test
/// func testFileProcessing() throws {
///     let file = try require(loadFile("data.json"))
///     // Test stops here if file is nil
///
///     let parsed = try require(parseJSON(file))
///     // Test stops here if parsing fails
///
///     expect(parsed.count > 0)
/// }
/// ```
///
/// - Parameters:
///   - condition: The condition to evaluate.
///   - comment: Optional comment explaining the requirement.
///   - fileID: The file ID (captured automatically).
///   - filePath: The file path (captured automatically).
///   - line: The line number (captured automatically).
///   - column: The column number (captured automatically).
/// - Throws: `Test.Requirement.Failed` if the condition is false.
public func require(
    _ condition: Bool,
    _ comment: Test.Text? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column
) throws(Test.Requirement.Failed) {
    let location = Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    let expressionID = Test.Expression.ID(__unchecked: (), nextRequireExpressionID())
    let expression = Test.Expression(
        id: expressionID,
        sourceCode: "\(condition)",
        sourceLocation: location
    )
    let expectationID = Test.Expectation.ID(__unchecked: (), nextRequireExpectationID())

    if condition {
        let expectation = Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: true
        )
        Test.Expectation.Collector.current?.record(expectation)
    } else {
        let failure = Test.Expectation.Failure(
            message: "Requirement failed",
            comment: comment
        )
        let expectation = Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: false,
            failure: failure
        )
        Test.Expectation.Collector.current?.record(expectation)
        throw Test.Requirement.Failed(
            message: comment ?? "Requirement failed",
            sourceLocation: location
        )
    }
}

/// Unwraps an optional value, throwing if nil.
///
/// - Parameters:
///   - optional: The optional value to unwrap.
///   - comment: Optional comment.
///   - fileID: The file ID.
///   - filePath: The file path.
///   - line: The line number.
///   - column: The column number.
/// - Returns: The unwrapped value.
/// - Throws: `Test.Requirement.Failed` if the optional is nil.
public func require<T>(
    _ optional: T?,
    _ comment: Test.Text? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column
) throws(Test.Requirement.Failed) -> T {
    let location = Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    let expressionID = Test.Expression.ID(__unchecked: (), nextRequireExpressionID())
    let expression = Test.Expression(
        id: expressionID,
        sourceCode: "require(\(T.self)?)",
        sourceLocation: location
    )
    let expectationID = Test.Expectation.ID(__unchecked: (), nextRequireExpectationID())

    guard let value = optional else {
        let failure = Test.Expectation.Failure(
            message: "Required value was nil",
            comment: comment
        )
        let expectation = Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: false,
            failure: failure
        )
        Test.Expectation.Collector.current?.record(expectation)
        throw Test.Requirement.Failed(
            message: comment ?? "Required value was nil",
            sourceLocation: location
        )
    }

    let expectation = Test.Expectation(
        id: expectationID,
        expression: expression,
        isPassing: true
    )
    Test.Expectation.Collector.current?.record(expectation)
    return value
}

/// Evaluates an equality requirement.
///
/// - Parameters:
///   - lhs: The actual value.
///   - rhs: The expected value.
///   - comment: Optional comment.
///   - fileID: The file ID.
///   - filePath: The file path.
///   - line: The line number.
///   - column: The column number.
/// - Throws: `Test.Requirement.Failed` if values are not equal.
public func require<T: Equatable>(
    _ lhs: T,
    equals rhs: T,
    _ comment: Test.Text? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column
) throws(Test.Requirement.Failed) {
    let location = Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    let expressionID = Test.Expression.ID(__unchecked: (), nextRequireExpressionID())
    let expression = Test.Expression(
        id: expressionID,
        sourceCode: "lhs == rhs",
        sourceLocation: location,
        values: [
            .init(capturing: lhs, label: "lhs"),
            .init(capturing: rhs, label: "rhs"),
        ]
    )
    let expectationID = Test.Expectation.ID(__unchecked: (), nextRequireExpectationID())

    if lhs == rhs {
        let expectation = Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: true
        )
        Test.Expectation.Collector.current?.record(expectation)
    } else {
        let message = comment ?? Test.Text([
            .init("Expected ", style: .plain),
            .init(String(describing: rhs), style: .value),
            .init(" but got ", style: .plain),
            .init(String(describing: lhs), style: .value),
        ])

        let failure = Test.Expectation.Failure(
            message: "Values are not equal",
            expected: .init(capturing: rhs, label: "expected"),
            actual: .init(capturing: lhs, label: "actual"),
            comment: comment
        )
        let expectation = Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: false,
            failure: failure
        )
        Test.Expectation.Collector.current?.record(expectation)
        throw Test.Requirement.Failed(
            message: message,
            sourceLocation: location
        )
    }
}

// MARK: - ID Counters

private let _requireExpressionCounter = Atomic<UInt64>(0)

private func nextRequireExpressionID() -> UInt64 {
    _requireExpressionCounter.wrappingAdd(1, ordering: .relaxed).newValue
}

private let _requireExpectationCounter = Atomic<UInt64>(0)

private func nextRequireExpectationID() -> UInt64 {
    _requireExpectationCounter.wrappingAdd(1, ordering: .relaxed).newValue
}

// MARK: - Deprecated Alias

@available(*, deprecated, renamed: "Test.Requirement.Failed")
public typealias RequirementFailed = Test.Requirement.Failed
