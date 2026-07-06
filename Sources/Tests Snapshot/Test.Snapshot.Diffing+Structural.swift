//
//  Test.Snapshot.Diffing+Structural.swift
//  swift-tests
//
//  Structural JSON diffing — tree-aware comparison.
//

import Byte_Primitives_Standard_Library_Integration
import JSON
public import Test_Primitives
internal import Tree_Keyed_Primitives

// MARK: - Structural JSON Diffing

extension Test.Snapshot.Diffing where Format == Swift.String {
    /// Structural JSON diff — parses to tree, compares by key, produces semantic output.
    ///
    /// Unlike ``lines`` which compares text line-by-line, structural diffing
    /// understands JSON semantics. It identifies exactly which keys changed,
    /// were added, or were removed — independent of formatting or key ordering.
    ///
    /// ## Example Output
    ///
    /// ```
    /// 3 structural changes:
    /// + email: "alice@example.com"
    /// ~ name: "Alice" → "Bob"
    /// - phone: "555-1234"
    /// ```
    public static var structuralJSON: Self {
        structuralJSON()
    }

    /// Structural JSON diff with formatting options.
    ///
    /// - Parameters:
    ///   - sortKeys: Whether to sort keys in serialized output. Default: `true`.
    ///   - pretty: Whether to pretty-print serialized output. Default: `true`.
    /// - Returns: A diffing strategy that performs structural JSON comparison.
    public static func structuralJSON(
        sortKeys: Bool = true,
        pretty: Bool = true
    ) -> Self {
        Self(
            toBytes: { $0.utf8.map(Byte.init) },
            fromBytes: { Swift.String(decoding: $0.underlying, as: UTF8.self) },
            diff: { old, new in
                let oldValue: RFC_8259.Value
                let newValue: RFC_8259.Value
                do throws(RFC_8259.Error) {
                    oldValue = try JSON.Decode.parse(old)
                    newValue = try JSON.Decode.parse(new)
                } catch {
                    // Not valid JSON — fall back to line diff
                    return Self.lines.diff(old, new)
                }

                let oldTree = _jsonToKeyedTree(oldValue)
                let newTree = _jsonToKeyedTree(newValue)
                let treeDiff = Tree<RFC_8259.Value>.Keyed<Swift.String>.diff(from: oldTree, to: newTree)

                guard !treeDiff.isEmpty else { return nil }

                // Build structural operations (format-agnostic)
                let structuralOps: [Test.Snapshot.Diff.Result.Operation] =
                    treeDiff.operations.compactMap { op in
                        switch op {
                        case .added(let path, let value):
                            guard !_jsonIsContainer(value) else { return nil }
                            return .added(
                                path: _jsonFormatPath(path),
                                value: _jsonDisplayValue(value)
                            )

                        case .removed(let path, let value):
                            guard !_jsonIsContainer(value) else { return nil }
                            return .removed(
                                path: _jsonFormatPath(path),
                                value: _jsonDisplayValue(value)
                            )

                        case .modified(let path, let old, let new):
                            return .modified(
                                path: _jsonFormatPath(path),
                                old: _jsonDisplayValue(old),
                                new: _jsonDisplayValue(new)
                            )
                        }
                    }

                // Build summary
                let lines: [Swift.String] = structuralOps.map { op in
                    switch op {
                    case .added(let path, let value):
                        "+ \(path): \(value)"

                    case .removed(let path, let value):
                        "- \(path): \(value)"

                    case .modified(let path, let old, let new):
                        "~ \(path): \(old) → \(new)"
                    }
                }

                let count = structuralOps.count
                let noun = count == 1 ? "change" : "changes"
                let summary = "\(count) structural \(noun):\n" + lines.joined(separator: "\n")

                return Test.Snapshot.Diff.Result(
                    summary: summary,
                    structuralOperations: structuralOps
                )
            }
        )
    }
}
