//
//  Test.expect.swift
//  swift-tests
//
//  Expectation API for test assertions.
//

public import Test_Primitives

// MARK: - Expect Functions

/// Evaluates an expectation and records the result.
///
/// Use `expect` when a failing condition should be recorded but should
/// not stop test execution. Multiple expectations can fail in a single test.
///
/// ## Example
///
/// ```swift
/// @Test
/// func testUserValidation() {
///     let user = User(name: "", age: -1)
///
///     expect(!user.name.isEmpty, "Name should not be empty")
///     expect(user.age >= 0, "Age should be non-negative")
///     // Both failures are recorded; test continues
/// }
/// ```
///
/// - Parameters:
///   - condition: The condition to evaluate.
///   - comment: Optional comment explaining the expectation.
///   - fileID: The file ID (captured automatically).
///   - filePath: The file path (captured automatically).
///   - line: The line number (captured automatically).
///   - column: The column number (captured automatically).
/// - Returns: The evaluated expectation.
@discardableResult
public func expect(
    _ condition: Bool,
    _ comment: Test.Text? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column
) -> Test.Expectation {
    let location = Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    let expression = Test.Expression(
        id: _nextExpressionID(),
        sourceCode: "\(condition)",
        sourceLocation: location
    )

    let expectationID = _nextExpectationID()

    let expectation: Test.Expectation

    if condition {
        expectation = Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: true
        )
    } else {
        let failure = Test.Expectation.Failure(
            message: "Expectation failed",
            comment: comment
        )
        expectation = Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: false,
            failure: failure
        )
    }

    Test.Expectation.Collector.current?.record(expectation)
    if !expectation.isPassing {
        Test.Expectation._reportExternalFailure(
            comment.map { "Expectation failed: \($0)" } ?? "Expectation failed",
            at: location
        )
    }
    return expectation
}

/// Evaluates an equality expectation.
///
/// - Parameters:
///   - lhs: The actual value.
///   - rhs: The expected value.
///   - comment: Optional comment.
///   - fileID: The file ID.
///   - filePath: The file path.
///   - line: The line number.
///   - column: The column number.
/// - Returns: The evaluated expectation.
@discardableResult
public func expect<T: Equatable>(
    _ lhs: T,
    equals rhs: T,
    _ comment: Test.Text? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column
) -> Test.Expectation {
    let location = Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    let expression = Test.Expression(
        id: _nextExpressionID(),
        sourceCode: "lhs == rhs",
        sourceLocation: location,
        values: [
            .init(capturing: lhs, label: "lhs"),
            .init(capturing: rhs, label: "rhs"),
        ]
    )

    let expectationID = _nextExpectationID()
    let isPassing = lhs == rhs

    let expectation: Test.Expectation

    if isPassing {
        expectation = Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: true
        )
    } else {
        let failure = Test.Expectation.Failure(
            message: "Values are not equal",
            expected: .init(capturing: rhs, label: "expected"),
            actual: .init(capturing: lhs, label: "actual"),
            comment: comment
        )
        expectation = Test.Expectation(
            id: expectationID,
            expression: expression,
            isPassing: false,
            failure: failure
        )
    }

    Test.Expectation.Collector.current?.record(expectation)
    if !expectation.isPassing {
        Test.Expectation._reportExternalFailure(
            comment.map { "Values are not equal: \($0)" }
                ?? "Values are not equal: expected \(rhs), got \(lhs)",
            at: location
        )
    }
    return expectation
}
