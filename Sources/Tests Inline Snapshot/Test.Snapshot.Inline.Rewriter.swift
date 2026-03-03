//
//  Test.Snapshot.Inline.Rewriter.swift
//  swift-tests
//
//  SwiftSyntax-based source file rewriter for inline snapshots.
//

public import Test_Primitives
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
internal import Foundation

extension Test.Snapshot.Inline {
    /// SwiftSyntax-based source file rewriter for inline snapshots.
    ///
    /// Processes accumulated ``State/Entry`` values by parsing each source
    /// file, locating the call sites by line/column, and inserting or
    /// replacing trailing closures containing the snapshot value.
    public enum Rewriter {
        /// Writes all pending inline snapshots to their source files.
        ///
        /// For each source file with pending entries:
        /// 1. Reads the source
        /// 2. Parses with SwiftParser
        /// 3. Rewrites call sites using a `SyntaxRewriter`
        /// 4. Writes the modified source atomically
        ///
        /// - Parameter entries: Entries grouped by source file path.
        /// - Throws: ``Error`` if reading, parsing, or writing fails.
        public static func writeAll(
            from entries: [Swift.String: [State.Entry]]
        ) throws(Error) {
            for (filePath, fileEntries) in entries {
                try rewriteFile(at: filePath, entries: fileEntries)
            }
        }
    }
}

// MARK: - File Rewriting

extension Test.Snapshot.Inline.Rewriter {
    /// Rewrites a single source file with the given entries.
    private static func rewriteFile(
        at filePath: Swift.String,
        entries: [Test.Snapshot.Inline.State.Entry]
    ) throws(Error) {
        // Read source
        let source: Swift.String
        do {
            source = try Swift.String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            throw .readFailed(path: filePath, underlying: Swift.String(describing: error))
        }

        // Parse
        let sourceFile = Parser.parse(source: source)
        let locationConverter = SourceLocationConverter(
            fileName: filePath,
            tree: sourceFile
        )

        // Sort entries by line ascending to match SyntaxRewriter's
        // top-to-bottom traversal order.
        let sorted = entries.sorted { $0.line < $1.line }

        // Apply rewrites
        let rewriter = InlineSnapshotSyntaxRewriter(
            entries: sorted,
            locationConverter: locationConverter
        )
        let rewritten = rewriter.visit(sourceFile)

        // Write result
        let output = rewritten.description
        do {
            try output.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            throw .writeFailed(path: filePath, underlying: Swift.String(describing: error))
        }
    }
}

// MARK: - Syntax Rewriter

/// Visits function call expressions and rewrites matching call sites
/// with trailing closures containing the inline snapshot value.
private final class InlineSnapshotSyntaxRewriter: SyntaxRewriter {
    let entries: [Test.Snapshot.Inline.State.Entry]
    let locationConverter: SourceLocationConverter
    private var entryIndex = 0

    init(
        entries: [Test.Snapshot.Inline.State.Entry],
        locationConverter: SourceLocationConverter
    ) {
        self.entries = entries
        self.locationConverter = locationConverter
    }

    override func visit(_ node: FunctionCallExprSyntax) -> ExprSyntax {
        guard entryIndex < entries.count else {
            return super.visit(node)
        }

        let entry = entries[entryIndex]

        // Get source location of this call
        let location = node.startLocation(converter: locationConverter)
        let nodeLine = location.line
        let nodeColumn = location.column

        // Match by line number. Column is not checked because #column
        // reports the opening parenthesis position while SwiftSyntax's
        // startLocation reports the callee expression start — they never match.
        guard nodeLine == entry.line else {
            return super.visit(node)
        }

        // Check that this looks like an inline snapshot call
        guard isInlineSnapshotCall(node) else {
            return super.visit(node)
        }

        entryIndex += 1

        // Build the replacement node
        let updated = applyInlineSnapshot(to: node, value: entry.actual)
        return super.visit(updated)
    }
}

// MARK: - Call Site Detection

/// Checks whether a function call is an inline snapshot macro or function call.
private func isInlineSnapshotCall(_ node: FunctionCallExprSyntax) -> Bool {
    let callee = node.calledExpression.description.trimmingCharacters(in: .whitespaces)

    // Macro expansion: #expectInlineSnapshot
    if callee.contains("expectInlineSnapshot") || callee.contains("assertInlineSnapshot") {
        return true
    }

    // Bridge function: Testing.__expectInlineSnapshot
    if callee.contains("__expectInlineSnapshot") {
        return true
    }

    return false
}

// MARK: - Snapshot Application

/// Applies the inline snapshot value to a call site, inserting or replacing
/// the trailing closure.
private func applyInlineSnapshot(
    to node: FunctionCallExprSyntax,
    value: Swift.String
) -> FunctionCallExprSyntax {
    // Determine indentation from the node's leading trivia
    let indent = extractIndentation(from: node)
    let innerIndent = indent + "    "

    // Determine the number of # delimiters needed for extended string literals
    let hashes = hashCount(for: value)
    let hashString = Swift.String(repeating: "#", count: hashes)

    // Build the multiline string literal
    let closureBody: Swift.String
    if value.isEmpty {
        closureBody = """
        \(hashString)\"\"\"
        \(innerIndent)\(hashString)\"\"\"
        """
    } else {
        // Indent each line of the value
        let indentedValue = value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line in
                line.isEmpty ? Swift.String(line) : "\(innerIndent)\(line)"
            }
            .joined(separator: "\n")

        closureBody = """
        \(hashString)\"\"\"
        \(indentedValue)
        \(innerIndent)\(hashString)\"\"\"
        """
    }

    // Build the trailing closure
    let closureSource = " {\n\(innerIndent)\(closureBody)\n\(indent)}"

    // Remove existing trailing closure if present, then append new one
    var updated = node
    if node.trailingClosure != nil {
        updated = updated.with(\.trailingClosure, nil)
    }

    // Remove the right paren's trailing trivia to attach closure cleanly
    if let rightParen = updated.rightParen {
        updated = updated.with(\.rightParen, rightParen.with(\.trailingTrivia, []))
    }

    // Parse the new trailing closure and attach it
    let closureExpr = ClosureExprSyntax(
        leadingTrivia: .space,
        leftBrace: .leftBraceToken(),
        statements: CodeBlockItemListSyntax([
            CodeBlockItemSyntax(
                leadingTrivia: .newline + .spaces(innerIndent.count),
                item: .expr(ExprSyntax(stringLiteral: "\(closureBody)"))
            )
        ]),
        rightBrace: .rightBraceToken(
            leadingTrivia: .newline + .spaces(indent.count)
        )
    )

    updated = updated.with(\.trailingClosure, closureExpr)
    return updated
}

// MARK: - Indentation

/// Extracts the leading indentation from a syntax node.
private func extractIndentation(from node: some SyntaxProtocol) -> Swift.String {
    var indent = ""
    for piece in node.leadingTrivia.pieces {
        switch piece {
        case .spaces(let count):
            indent = Swift.String(repeating: " ", count: count)
        case .tabs(let count):
            indent = Swift.String(repeating: "\t", count: count)
        default:
            break
        }
    }
    return indent
}

// MARK: - Hash Count

/// Computes the minimum number of `#` delimiters needed for an extended
/// string literal that contains the given value.
///
/// Ported from Point-Free's `swift-snapshot-testing`.
private func hashCount(for value: Swift.String) -> Int {
    var count = 0
    var current = 0
    for character in value {
        switch character {
        case "#":
            current += 1
        case "\"":
            // The sequence `"""#...#` requires us to use more hashes
            count = max(count, current + 1)
            current = 0
        case "\\":
            // A backslash followed by hashes: `\#...#(`
            count = max(count, current + 1)
            current = 0
        default:
            current = 0
        }
    }
    return count
}
