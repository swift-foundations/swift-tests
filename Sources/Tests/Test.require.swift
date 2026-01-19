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
/// - Throws: `RequirementFailed` if the condition is false.
public func require(
    _ condition: Bool,
    _ comment: Test.Text? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column
) throws(RequirementFailed) {
    let location = Test.Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    if !condition {
        throw RequirementFailed(
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
/// - Throws: `RequirementFailed` if the optional is nil.
public func require<T>(
    _ optional: T?,
    _ comment: Test.Text? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column
) throws(RequirementFailed) -> T {
    let location = Test.Source.Location(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )

    guard let value = optional else {
        throw RequirementFailed(
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
/// - Throws: `RequirementFailed` if values are not equal.
public func require<T: Equatable>(
    _ lhs: T,
    equals rhs: T,
    _ comment: Test.Text? = nil,
    fileID: Swift.String = #fileID,
    filePath: Swift.String = #filePath,
    line: Int = #line,
    column: Int = #column
) throws(RequirementFailed) {
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

        throw RequirementFailed(
            message: message,
            sourceLocation: location
        )
    }
}

// MARK: - RequirementFailed Error

/// Error thrown when a requirement fails.
///
/// This error type uses typed throws for precise error handling.
/// It contains information about what failed and where.
public struct RequirementFailed: Error, Sendable {
    /// A message describing the failure.
    public let message: Test.Text

    /// The source location where the requirement failed.
    public let sourceLocation: Test.Source.Location

    /// Creates a requirement failure.
    ///
    /// - Parameters:
    ///   - message: The failure message.
    ///   - sourceLocation: Where the failure occurred.
    public init(message: Test.Text, sourceLocation: Test.Source.Location) {
        self.message = message
        self.sourceLocation = sourceLocation
    }
}

// MARK: - CustomStringConvertible

extension RequirementFailed: CustomStringConvertible {
    public var description: Swift.String {
        "\(message.plainText) at \(sourceLocation)"
    }
}
