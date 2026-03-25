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

public import Test_Primitives
import Time_Primitives
internal import Console
import Synchronization

extension Test.Reporter {
    /// Creates a console reporter with ANSI terminal styling.
    ///
    /// The console reporter formats events for terminal output with
    /// human-readable messages, colored symbols, structured diffs,
    /// and source locations for failures.
    ///
    /// - Returns: A reporter that outputs to the console.
    public static var console: Test.Reporter {
        Test.Reporter {
            Sink(Terminal())
        }
    }
}

// MARK: - Terminal

extension Test.Reporter {
    /// Console sink implementation with thread-safe counters.
    private final class Terminal: Sink.Implementation, @unchecked Sendable {
        private let capability: Console.Capability
        private let _counts = Mutex((passed: 0, failed: 0, skipped: 0, issues: 0))

        init() {
            self.capability = Console.Capability.detect(stream: .stdout)
        }

        func send(_ event: Test.Event) async {
            switch event.kind {
            case .runStarted:
                print("Test run started")

            case .testStarted:
                if let id = event.id {
                    print("  ▶ \(id.fullyQualifiedName)")
                }

            case .testEnded:
                if let id = event.id {
                    let symbol: Swift.String
                    let style: Console.Style
                    switch event.result {
                    case .passed:
                        symbol = "✓"
                        style = .success
                        _counts.withLock { $0.passed += 1 }
                    case .failed:
                        symbol = "✗"
                        style = .error
                        _counts.withLock { $0.failed += 1 }
                    case .skipped:
                        symbol = "○"
                        style = .dim
                        _counts.withLock { $0.skipped += 1 }
                    case nil:
                        symbol = "?"
                        style = .dim
                    }

                    var message = "  \(style.apply(to: symbol, capability: capability)) \(id.name)"
                    if let elapsed = event.elapsed {
                        message += dimmed(" (\(elapsed.formatted(.duration)))")
                    }
                    print(message)
                }

            case .testSkipped:
                _counts.withLock { $0.skipped += 1 }
                if let id = event.id {
                    var message = "  \(dimmed("○")) \(id.name)\(dimmed(" (skipped)"))"
                    if let reason = event.reason {
                        message += dimmed(": \(render(reason))")
                    }
                    print(message)
                }

            case .issueRecorded:
                _counts.withLock { $0.issues += 1 }
                if let issue = event.issue {
                    print("    \(Console.Style.warning.apply(to: "⚠", capability: capability)) \(issue.kind)")
                    if let context = issue.context {
                        indented(render(context), indent: "      ")
                    }
                }

            case .expectationChecked:
                if let expectation = event.expectation, expectation.isFailing {
                    print("    \(Console.Style.error.apply(to: "✗", capability: capability)) \(expectation.expression.sourceCode)")

                    // Source location
                    let loc = expectation.expression.sourceLocation
                    print("      \(dimmed("at \(loc.fileID):\(loc.line):\(loc.column)"))")

                    if let failure = expectation.failure {
                        // Failure message
                        indented(render(failure.message), indent: "      ")

                        // Expected vs actual
                        if let expected = failure.expected, let actual = failure.actual {
                            let expectedLabel = Console.Style.success.apply(
                                to: "expected", capability: capability
                            )
                            let actualLabel = Console.Style.error.apply(
                                to: "actual", capability: capability
                            )
                            print("      \(expectedLabel): \(expected.stringValue)")
                            print("      \(actualLabel):   \(actual.stringValue)")
                        }

                        // Structured diff
                        if let difference = failure.difference {
                            print("")
                            indented(render(difference), indent: "      ")
                        }

                        // User comment
                        if let comment = failure.comment {
                            print("      \(dimmed("—")) \(render(comment))")
                        }
                    }
                }

            case .runEnded:
                let counts = _counts.withLock { $0 }
                print("")
                print("Test run complete:")
                print(Console.Style.success.apply(
                    to: "  Passed:  \(counts.passed)", capability: capability
                ))
                if counts.failed > 0 {
                    print(Console.Style.error.apply(
                        to: "  Failed:  \(counts.failed)", capability: capability
                    ))
                }
                if counts.skipped > 0 {
                    print(dimmed("  Skipped: \(counts.skipped)"))
                }
                if counts.issues > 0 {
                    print(Console.Style.warning.apply(
                        to: "  Issues:  \(counts.issues)", capability: capability
                    ))
                }

            case .planCreated, .caseStarted, .caseEnded:
                break

            default:
                // L3 performance kinds (.performanceDiagnostic, .performanceSummary)
                // and any future extensible kinds are handled by the runner or
                // higher-layer reporters.
                break
            }

            // Flush stdout so progress is visible immediately when piped
            // (SwiftPM's test harness makes stdout fully buffered)
            Console.Output.flush()
        }

        func finish() async {}

        // MARK: - Rendering Helpers

        private func render(_ text: Test.Text) -> Swift.String {
            text.segments.map { segment in
                style(for: segment.style)
                    .apply(to: segment.content, capability: capability)
            }.joined()
        }

        private func dimmed(_ text: Swift.String) -> Swift.String {
            Console.Style.dim.apply(to: text, capability: capability)
        }

        private func indented(_ text: Swift.String, indent: Swift.String) {
            for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
                print("\(indent)\(line)")
            }
        }

        private func style(
            for style: Test.Text.Segment.Style
        ) -> Console.Style {
            switch style {
            case .plain:        .plain
            case .identifier:   Console.Style(foreground: .palette(.cyan))
            case .value:        Console.Style(foreground: .palette(.yellow))
            case .keyword:      Console.Style(foreground: .palette(.magenta))
            case .punctuation:  .plain
            case .emphasis:     .bold
            case .secondary:    .dim
            case .success:      .success
            case .failure:      .error
            case .warning:      .warning
            case .diffAdded:    Console.Style(foreground: .palette(.green))
            case .diffRemoved:  Console.Style(foreground: .palette(.red))
            case .diffContext:  .dim
            }
        }
    }
}
