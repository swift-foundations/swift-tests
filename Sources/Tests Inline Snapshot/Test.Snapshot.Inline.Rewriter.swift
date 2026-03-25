//
//  Test.Snapshot.Inline.Rewriter.swift
//  swift-tests
//
//  SwiftSyntax-based source file rewriter for inline snapshots.
//

public import Test_Primitives
import File_System
import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder

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
            source = try File(File.Path(stringLiteral: filePath)).read.full { span in
                unsafe span.withUnsafeBufferPointer { buffer in
                    unsafe Swift.String(decoding: buffer, as: UTF8.self)
                }
            }
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
        let rewriter = Syntax(
            entries: sorted,
            locationConverter: locationConverter
        )
        let rewritten = rewriter.visit(sourceFile)

        // Write result
        let output = rewritten.description
        do {
            try File(File.Path(stringLiteral: filePath)).write.atomic(output)
        } catch {
            throw .writeFailed(path: filePath, underlying: Swift.String(describing: error))
        }
    }
}

// MARK: - Syntax Rewriter

extension Test.Snapshot.Inline.Rewriter {
    /// Visits call sites and rewrites matching snapshot calls with the
    /// recorded expected value.
    private final class Syntax: SyntaxRewriter {
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
            let location = node.startLocation(converter: locationConverter)

            guard location.line == entry.line else {
                return super.visit(node)
            }

            guard isSnapshotCall(node) else {
                return super.visit(node)
            }

            entryIndex += 1

            let updated = applySnapshotFunction(to: node, value: entry.actual)
            return super.visit(updated)
        }

}
}

// MARK: - Call Site Detection

/// Checks whether a function call is a `snapshot(as:)` call.
private func isSnapshotCall(_ node: FunctionCallExprSyntax) -> Bool {
    node.calledExpression.trimmedDescription == "snapshot"
}

// MARK: - Snapshot Application

/// Applies the inline snapshot value to a `snapshot(as:)` function call site.
///
/// For `snapshot(as:) { value } matches: { expected }`, the expected value
/// goes in a `matches:` additional trailing closure. The first trailing
/// closure (value) is preserved.
private func applySnapshotFunction(
    to node: FunctionCallExprSyntax,
    value: Swift.String
) -> FunctionCallExprSyntax {
    let indent = extractIndentation(from: node)
    let closureExpr = buildSnapshotClosure(value: value, indent: indent)

    var updated = node

    // Remove existing `matches:` additional trailing closure if present.
    let filtered = updated.additionalTrailingClosures.filter {
        $0.label.text != "matches"
    }
    updated = updated.with(
        \.additionalTrailingClosures,
        filtered
    )

    // Build the `matches:` additional trailing closure element.
    let matchesElement = MultipleTrailingClosureElementSyntax(
        leadingTrivia: .space,
        label: .identifier("matches"),
        colon: .colonToken(trailingTrivia: .space),
        closure: closureExpr.with(\.leadingTrivia, [])
    )

    // Append to additional trailing closures.
    updated = updated.with(
        \.additionalTrailingClosures,
        MultipleTrailingClosureElementListSyntax(updated.additionalTrailingClosures + [matchesElement])
    )

    return updated
}

// MARK: - Closure Builder

/// Builds a `ClosureExprSyntax` containing a multiline string literal
/// with the snapshot value.
private func buildSnapshotClosure(
    value: Swift.String,
    indent: Swift.String
) -> ClosureExprSyntax {
    let innerIndent = indent + "    "

    let hashes = hashCount(for: value)
    let hashString = Swift.String(repeating: "#", count: hashes)

    let closureBody: Swift.String
    if value.isEmpty {
        closureBody = """
        \(hashString)\"\"\"
        \(innerIndent)\(hashString)\"\"\"
        """
    } else {
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

    return ClosureExprSyntax(
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

/// Computes the minimum number of `#` delimiters needed for a multiline
/// extended string literal that contains the given value.
///
/// For a `"""..."""` literal, the problematic sequences are:
/// - `"""` (three+ consecutive quotes) closes the literal prematurely
/// - `\(` starts string interpolation
///
/// For a `#"""...#"""` literal:
/// - `"""#` closes the literal prematurely
/// - `\#(` starts interpolation
///
/// This function returns the minimum hash count that avoids all conflicts.
func hashCount(for value: Swift.String) -> Int {
    var needed = 0

    // Track consecutive quotes to detect """ sequences
    var consecutiveQuotes = 0
    // Track consecutive hashes after a """ sequence
    var hashesAfterTripleQuote = 0
    // Whether we've seen 3+ consecutive quotes in current run
    var inTripleQuote = false

    // Track \#...# sequences for escape/interpolation prevention.
    // -1 means not after a backslash; >= 0 counts consecutive #'s.
    var hashesAfterBackslash = -1

    for character in value {
        // When tracking a \#...# sequence, accumulate hashes.
        if hashesAfterBackslash >= 0 {
            if character == "#" {
                hashesAfterBackslash += 1
                // \#^N in an N-hash literal is an escape prefix → need N+1
                needed = max(needed, hashesAfterBackslash + 1)
                consecutiveQuotes = 0
                inTripleQuote = false
                hashesAfterTripleQuote = 0
                continue
            } else {
                // Sequence ended; fall through to normal processing.
                hashesAfterBackslash = -1
            }
        }

        switch character {
        case "\"":
            consecutiveQuotes += 1
            if consecutiveQuotes >= 3 {
                inTripleQuote = true
                hashesAfterTripleQuote = 0
                // At minimum we need 1 hash to distinguish from closing """
                needed = max(needed, 1)
            }
        case "#" where inTripleQuote:
            hashesAfterTripleQuote += 1
            // """#...# with N hashes means we need N+1 hashes in our delimiter
            needed = max(needed, hashesAfterTripleQuote + 1)
        case "\\":
            // Any backslash needs at least 1 hash so \n, \t, \(, etc.
            // are not interpreted as escape sequences.
            hashesAfterBackslash = 0
            needed = max(needed, 1)
            consecutiveQuotes = 0
            inTripleQuote = false
            hashesAfterTripleQuote = 0
        default:
            consecutiveQuotes = 0
            inTripleQuote = false
            hashesAfterTripleQuote = 0
        }
    }

    return needed
}
