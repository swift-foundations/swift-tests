//
//  Test.Reporter.Structured.swift
//  swift-tests
//
//  JSONL reporter that writes one JSON record per line.
//

import Test_Primitives
import JSON
import Kernel
import Synchronization

extension Test.Reporter {
    /// Creates a structured JSONL reporter.
    ///
    /// Writes one JSON object per line to the given file path.
    /// Each record has the envelope: `{"version": 1, "kind": "<kind>", ...}`
    ///
    /// - Parameter path: File path for JSONL output.
    /// - Returns: A reporter that writes structured JSONL.
    public static func structured(to path: Swift.String) -> Test.Reporter {
        Test.Reporter {
            Sink(StructuredSink(path: path))
        }
    }
}

// MARK: - StructuredSink

extension Test.Reporter {
    /// Sink that accumulates JSON records and writes JSONL on finish.
    private final class StructuredSink: Sink.Implementation, @unchecked Sendable {
        private let _path: Swift.String
        private let _records = Mutex<[JSON]>([])

        init(path: Swift.String) {
            self._path = path
        }

        func send(_ event: Test.Event) async {
            guard let record = Self.record(for: event) else { return }
            _records.withLock { $0.append(record) }
        }

        func finish() async {
            let records = _records.withLock { $0 }
            guard !records.isEmpty else { return }

            var lines: [UInt8] = []
            for record in records {
                lines.append(contentsOf: record.serialize().utf8)
                lines.append(0x0A) // newline
            }

            do {
                let descriptor = try Kernel.Path.scope(_path) { pathView in
                    try Kernel.File.Open.open(
                        path: pathView,
                        mode: .write,
                        options: [.create, .truncate],
                        permissions: .standard
                    )
                }
                defer { try? Kernel.Close.close(descriptor) }

                var remaining = lines[...]
                while !remaining.isEmpty {
                    let written = try unsafe remaining.withUnsafeBytes { buffer in
                        try unsafe Kernel.IO.Write.write(descriptor, from: buffer)
                    }
                    remaining = remaining.dropFirst(written)
                }
            } catch {
                // Silent failure — structured output is best-effort.
            }
        }

        // MARK: - Event → JSON

        private static func record(for event: Test.Event) -> JSON? {
            switch event.kind {
            case .runStarted:
                return envelope("runStarted")

            case .testStarted:
                return envelope("testStarted", payload: .object(
                    testFields(event)
                ))

            case .testEnded:
                var fields = testFields(event)
                if let result = event.result {
                    fields.append(("result", .string("\(result)")))
                }
                if let elapsed = event.elapsed {
                    fields.append(("elapsed_seconds", .number(elapsed.inSeconds)))
                }
                return envelope("testEnded", payload: .object(fields))

            case .testSkipped:
                var fields = testFields(event)
                if let reason = event.reason {
                    fields.append(("reason", .string(reason.plainText)))
                }
                return envelope("testSkipped", payload: .object(fields))

            case .expectationChecked:
                guard let expectation = event.expectation, expectation.isFailing else {
                    return nil // Only record failures
                }
                var fields = testFields(event)
                fields.append(("expression", .string(expectation.expression.sourceCode)))
                let loc = expectation.expression.sourceLocation
                fields.append(("source_location", .object([
                    ("fileID", .string(loc.fileID)),
                    ("line", .number(loc.line)),
                    ("column", .number(loc.column)),
                ])))
                if let failure = expectation.failure {
                    fields.append(("message", .string(failure.message.plainText)))
                    if let expected = failure.expected {
                        fields.append(("expected", .string(expected.stringValue)))
                    }
                    if let actual = failure.actual {
                        fields.append(("actual", .string(actual.stringValue)))
                    }
                }
                return envelope("expectationFailed", payload: .object(fields))

            case .issueRecorded:
                guard let issue = event.issue else { return nil }
                var fields = testFields(event)
                fields.append(("issue_kind", .string("\(issue.kind)")))
                if let loc = issue.sourceLocation {
                    fields.append(("source_location", .object([
                        ("fileID", .string(loc.fileID)),
                        ("line", .number(loc.line)),
                        ("column", .number(loc.column)),
                    ])))
                }
                return envelope("issueRecorded", payload: .object(fields))

            case .runEnded:
                var fields: [(Swift.String, JSON)] = []
                if let elapsed = event.elapsed {
                    fields.append(("elapsed_seconds", .number(elapsed.inSeconds)))
                }
                return envelope("runEnded", payload: .object(fields))

            default:
                // Extensible kinds (e.g., performanceDiagnostic) with payload
                if let payload = event.payload {
                    let parsed = (try? JSON.parse(payload)) ?? .string(payload)
                    return envelope(event.kind.rawValue, payload: parsed)
                }
                return nil
            }
        }

        private static func envelope(_ kind: Swift.String, payload: JSON = .null) -> JSON {
            if payload.isNull {
                return .object([
                    ("version", .number(1)),
                    ("kind", .string(kind)),
                ])
            }
            return .object([
                ("version", .number(1)),
                ("kind", .string(kind)),
                ("payload", payload),
            ])
        }

        private static func testFields(_ event: Test.Event) -> [(Swift.String, JSON)] {
            var fields: [(Swift.String, JSON)] = []
            if let id = event.id {
                fields.append(("test_id", .string(id.fullyQualifiedName)))
            }
            return fields
        }
    }
}
