// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-tests open source project
//
// Copyright (c) 2024-2025 Coen ten Thije Boonkkamp and the swift-tests project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

/**
 Pending: Replace with swift-json when available.

 Current implementation is intentionally minimal and does not fully
 implement string escaping semantics.
 */

import Test_Primitives
import Kernel
import Synchronization

extension Test.Reporter {
    /// Creates a JSON reporter.
    ///
    /// - Parameter path: File path for output, or nil for stdout.
    /// - Returns: A reporter that outputs JSON.
    public static func json(to path: Swift.String? = nil) -> Test.Reporter {
        Test.Reporter {
            Sink(JSONSink(outputPath: path))
        }
    }
}

// MARK: - JSONSink

extension Test.Reporter {
    /// A test reporter sink that outputs JSON with thread-safe event collection.
    ///
    /// Produces JSON without Foundation by manually constructing UTF-8 bytes.
    private final class JSONSink: Sink.Implementation, @unchecked Sendable {
        let outputPath: Swift.String?
        private let _events = Mutex<[Test.Event]>([])

        init(outputPath: Swift.String?) {
            self.outputPath = outputPath
        }

        func send(_ event: Test.Event) async {
            _events.withLock { $0.append(event) }
        }

        func finish() async {
            let events = _events.withLock { $0 }
            let json = self.json(from: events)
            let bytes = Array(json.utf8)

            if let path = outputPath {
                write(to: path, bytes: bytes)
            } else {
                write(stdout: bytes)
            }
        }

        private func json(from events: [Test.Event]) -> Swift.String {
            var json = "{\n"
            json += "  \"events\": [\n"

            for (index, event) in events.enumerated() {
                json += "    "
                json += self.json(from: event)
                if index < events.count - 1 {
                    json += ","
                }
                json += "\n"
            }

            json += "  ]\n"
            json += "}\n"

            return json
        }

        private func json(from event: Test.Event) -> Swift.String {
            var json = "{"
            json += "\"kind\": \"\(event.kind.rawValue)\""

            if let id = event.id {
                json += ", \"test_id\": \"\(id.fullyQualifiedName)\""
            }

            if let result = event.result {
                json += ", \"result\": \"\(result)\""
            }

            if let duration = event.elapsed {
                let nanoseconds = duration.components.attoseconds / 1_000_000_000
                json += ", \"elapsed_ns\": \(nanoseconds)"
            }

            json += "}"
            return json
        }

        private func write(to path: Swift.String, bytes: [UInt8]) {
            do {
                let descriptor = try Kernel.Path.scope(path) { pathView in
                    try Kernel.File.Open.open(
                        path: pathView,
                        mode: .write,
                        options: [.create, .truncate],
                        permissions: .standard
                    )
                }
                defer { try? Kernel.Close.close(descriptor) }

                var remaining = bytes[...]
                while !remaining.isEmpty {
                    let written = try unsafe remaining.withUnsafeBytes { buffer in
                        try unsafe Kernel.IO.Write.write(descriptor, from: buffer)
                    }
                    remaining = remaining.dropFirst(written)
                }
            } catch {
                // Failed to write — silent failure
            }
        }

        private func write(stdout bytes: [UInt8]) {
            print(Swift.String(decoding: bytes, as: UTF8.self), terminator: "")
        }
    }
}
