//
//  Test.require.swift
//  swift-tests
//
//  Requirement API for test assertions with typed throws.
//

public import Test_Primitives

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
    let location = Test.Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    if !condition {
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
    let location = Test.Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    guard let value = optional else {
        throw Test.Requirement.Failed(
            message: comment ?? "Required value was nil",
            sourceLocation: location
        )
    }

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
    let location = Test.Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    if lhs != rhs {
        let message = comment ?? Test.Text([
            .init("Expected ", style: .plain),
            .init(String(describing: rhs), style: .value),
            .init(" but got ", style: .plain),
            .init(String(describing: lhs), style: .value),
        ])

        throw Test.Requirement.Failed(
            message: message,
            sourceLocation: location
        )
    }
}

// MARK: - Deprecated Alias

@available(*, deprecated, renamed: "Test.Requirement.Failed")
public typealias RequirementFailed = Test.Requirement.Failed
