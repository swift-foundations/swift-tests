# swift-tests

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Test infrastructure for Swift: expectations, file-backed and inline snapshots, timed benchmarks with baseline regression detection, and algorithmic-complexity assertions — usable with Apple's Swift Testing runner.

---

## Key Features

- **Inline snapshots** — `snapshot(as:) { value } matches: { ... }` records the produced value on first run by rewriting the `matches:` block in your test source
- **File-backed snapshots** — named reference snapshots with JSON strategies, structural diffing, and redaction rules for volatile fields
- **Timed benchmarks** — a `.timed(iterations:warmup:threshold:)` trait with optional allocation tracking, automatic baseline comparison, and JSONL run history
- **Complexity assertions** — `Tests.Complexity.analyze` measures a workload across input sizes, fits a growth curve, and classifies the asymptotic behavior
- **Deterministic async** — `withSerialExecutor` routes spawned tasks through the main executor so async tests execute in a predictable order
- **Typed throws end-to-end** — every throwing surface declares its error type; complexity analysis is generic over the workload's own error
- **Swift Testing bridge** — a `.snapshots(record:)` suite trait applies snapshot recording modes natively under Apple's Swift Testing runner

---

## Quick Start

### Inline snapshots

An inline snapshot asserts against an expected value embedded in the test source. On first run (or when re-recording), the library rewrites the `matches:` block with the actual output — no hand-transcription of expected strings:

```swift
import Testing
import Tests_Inline_Snapshot

@Test
func receiptRendering() {
    snapshot(as: .lines) {
        Receipt(subtotal: 40, tax: 2).rendered
    } matches: {
        """
        Subtotal: 40
        Tax:       2
        Total:    42
        """
    }
}
```

Passing `named:` instead of `matches:` stores the reference in a snapshot file next to the test instead of inline.

### Complexity assertions

Assert the asymptotic behavior of an algorithm, not just a single timing. The analyzer runs the workload across the given sizes, fits a growth exponent, and reports a classification with confidence:

```swift
import Testing
import Tests

@Test
func `array sort is no worse than quadratic`() throws {
    let diagnostic = try Tests.Complexity.analyze(
        sizes: [500, 1_000, 2_000, 5_000, 10_000, 20_000, 50_000],
        warmup: 1,
        iterations: 3
    ) { n in
        var array = (0..<n).map { _ in Int.random(in: 0..<n) }
        array.sort()
    }

    let result = diagnostic.result
    #expect(result.confidence != .inconclusive)
    #expect(result.isNoWorseThan(.quadratic))
}
```

### Deterministic async tests

Async tests are normally subject to the runtime's scheduling. `withSerialExecutor` redirects global task enqueues to the main actor for the duration of the operation, making task interleaving deterministic:

```swift
import Tests

@MainActor
@Test
func ordersProcessInSubmissionOrder() async {
    await withSerialExecutor {
        // All tasks spawned here run serially, in a predictable order.
    }
}
```

On platforms where the runtime hook is unavailable, the operation runs normally without serial enforcement.

---

## Installation

Add swift-tests to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/swift-foundations/swift-tests.git", branch: "main")
]
```

Add the umbrella product to your test target:

```swift
.testTarget(
    name: "YourTests",
    dependencies: [
        .product(name: "Tests", package: "swift-tests")
    ]
)
```

### Requirements

- Swift 6.3+
- macOS 26.0+, iOS 26.0+, tvOS 26.0+, watchOS 26.0+, visionOS 26.0+

---

## Architecture

The package splits into focused products so consumers pay only for what they use:

| Product | When to import |
|---------|----------------|
| `Tests` | Umbrella — expectations, snapshots, benchmarks, and reporters in one import; the default for test targets |
| `Tests Core` | Expectations (`expect`, `require`), traits, test plans, and discovery without snapshot or benchmark machinery |
| `Tests Snapshot` | File-backed snapshot strategies (JSON, structural diffing, redaction) |
| `Tests Inline Snapshot` | Inline `matches:` snapshots with source rewriting (adds a swift-syntax dependency) |
| `Tests Performance` | `.timed()` benchmarks, baselines, run history, and complexity analysis |
| `Tests Reporter` | Console, JSON, structured, and tee reporters for test results |
| `Tests Apple Testing Bridge` | The `.snapshots(record:)` trait for suites running under Apple's Swift Testing |
| `Tests Test Support` | Helpers for packages that test infrastructure built on swift-tests |

---

## Error Handling

All throwing surfaces use typed throws. The benchmark pipeline's error shape:

```
Tests.Error
├── .benchmarkFailed(Test.Benchmark.Error)   // Measurement or threshold failure
├── .allocationLimitExceeded(test:limit:actual:)
├── .memoryLeakDetected(test:netAllocations:netBytes:)
└── .peakMemoryExceeded(test:limit:actual:)
```

Snapshot storage, baseline storage, and inline-snapshot rewriting each declare their own flat error enums (`Tests.Baseline.Storage.Error`, `Tests.History.Storage.Error`, `Test.Snapshot.Inline.Rewriter.Error`), documented inline. Workload errors are never erased: `Tests.Complexity.analyze` rethrows the operation's own error type.

---

## Community

<!-- BEGIN: discussion -->
*Discussion thread will be created at the first public release.*
<!-- END: discussion -->

---

## License

Apache 2.0. See [LICENSE](LICENSE.md).
