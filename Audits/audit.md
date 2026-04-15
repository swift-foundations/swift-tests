# Audit: swift-tests

## Legacy — Consolidated 2026-04-08

### From: naming-implementation-audit-swift-tests-swift-testing.md (2026-03-26)

**Package**: swift-tests (Layer 3)
**Scope**: Naming + implementation audit against `/naming` and `/implementation` skills
**Violations**: 46 total (9 compound types, 23 compound methods/properties, 14 implementation)

#### Priority 1 -- Active Defects & Dead Code

| ID | File | Line | Finding |
|----|------|------|---------|
| I9 | `Tests Inline Snapshot/Test.Snapshot.Inline.Rewriter.swift` | 112 | Dead binding `nodeColumn` — extracted but never used; comment says "Column is not checked". Remove. |

#### Priority 2 -- Public Compound Type Names [API-NAME-001]

| ID | File | Line | Current | Fix |
|----|------|------|---------|-----|
| N1 | `Tests Apple Testing Bridge/Test.Expectation.AppleBridge.swift` | 24 | `AppleTestingBridge` | Rename to nested type. Consider `Apple.Bridge` or restructure as extension with static `install()` |
| N2 | `Tests Apple Testing Bridge/Test.Snapshot.RecordingTrait.swift` | 28 | `SnapshotRecordingTrait` | `Snapshot.Recording.Trait` or nest under `Test.Snapshot.Recording` |
| N3 | `Tests Snapshot/Test.Snapshot.Counter.swift` | 66 | `CounterKey` | Move into `extension Test.Snapshot.Counter { enum Key: Dependency.Key }` |
| N4 | `Tests Inline Snapshot/Test.Snapshot.Inline.Rewriter.swift` | 89 | `InlineSnapshotSyntaxRewriter` (private) | Rename to nested form even though private |
| N5 | `Tests Performance/Tests.Error.swift` | 21-30 | `AllocationStats`, `AllocationTracker`, `LeakDetector`, `PeakTracker` | Compound typealiases of already-nested types. Remove or re-export properly |

#### Priority 3 -- Deprecated Typealiases to Delete

| ID | File | Line | Identifier | Points to |
|----|------|------|-----------|-----------|
| N6 | `Tests Core/Test.Exclusion.Controller.swift` | 81 | `ExclusionController` | `Test.Exclusion.Controller` |
| N7 | `Tests Snapshot/Test.Snapshot.Storage.swift` | 213 | `StorageError` | `Test.Snapshot.Storage.Error` |
| N8 | `Tests Performance/Tests.Suite.swift` | 82 | `PerformanceSuite` | `Tests.Suite` |
| N9 | `Tests Performance/Tests.Comparison.swift` | 79 | `PerformanceComparison` | `Tests.Comparison` |

#### Priority 4 -- Public Compound Methods/Properties [API-NAME-002]

| ID | File | Line | Current | Suggested |
|----|------|------|---------|-----------|
| N10 | `Tests Core/Test.Reporter.swift` | 56 | `makeSink()` | `sink()` |
| N11 | `Tests Core/Test.Manifest.swift` | 41 | `getFactoryNames()` | Computed property `factoryNames` or `names()` |
| N12 | `Tests Snapshot/Test.Snapshot.Configuration.swift` | 90 | `resolveRecording(explicit:)` | `resolve(recording:)` |
| N13 | `Tests Snapshot/Test.Snapshot.Storage.swift` | 107 | `readReference(at:)` | `reference(at:)` |
| N14 | `Tests Snapshot/Test.Snapshot.Storage.swift` | 164 | `ensureDirectory(at:)` | `ensure(directory:)` |
| N15 | `Tests Performance/Assertions.swift` | 24, 55 | `expectPerformance(lessThan:...)` | Restructure under `Tests.Performance` or `expect(lessThan:...)` |
| N16 | `Tests Performance/Assertions.swift` | 98 | `expectNoRegression(...)` | `expect(noRegression:...)` |
| N17 | `Tests Performance/Reporting.swift` | 25 | `printPerformance(...)` | Restructure |
| N18 | `Tests Performance/Reporting.swift` | 117 | `printComparisonReport(_:)` | `print(comparisons:)` |
| N19 | `Tests Performance/Tests.Suite.swift` | 55 | `printReport(metric:)` | `print(metric:)` |
| N20 | `Tests Performance/Tests.Baseline.Recording.swift` | 33 | `fromEnvironment()` | Static property `.current` or `init()` |
| N21 | `Tests Performance/Test.Runner.swift` | 526, 531 | `hasFailures`, `allPassed` | Restructure |

**Scoping methods -- `with*` pattern** (discussion needed):

These use the standard Swift `with*` scoping idiom. Technically compound under [API-NAME-002] but the `with` prefix is a language-level convention for scope-based execution.

| ID | File | Line | Current |
|----|------|------|---------|
| N22 | `Tests Snapshot/Test.Snapshot.Configuration.swift` | 123, 136 | `withConfiguration(_:operation:)` |
| N23 | `Tests Snapshot/Test.Snapshot.Counter.swift` | 109, 122 | `withCounter(_:operation:)` |
| N24 | `Tests Core/Test.Exclusion.Controller.swift` | 38 | `withExclusiveAccess(group:_:)` |
| N25 | `Tests Core/SerialExecutor.swift` | 28, 43 | `withSerialExecutor(operation:)` |

#### Priority 5 -- Private Compound Methods [API-NAME-002]

Not exempted by [IMPL-024] (which only covers `private static`). Lower priority since non-public.

| ID | File | Line | Current |
|----|------|------|---------|
| N26 | `Tests Snapshot/Test.Snapshot.assert.swift` | 714 | `resultToFailureMessage(_:)` |
| N27 | `Tests Snapshot/Test.Snapshot.assert.swift` | 742, 754 | `makePassingExpectation(...)`, `makeFailingExpectation(...)` |
| N28 | `Tests Inline Snapshot/Test.Snapshot.Inline.assert.swift` | 560, 572 | `makeInlinePassingExpectation(...)`, `makeInlineFailingExpectation(...)` |
| N29 | `Tests Performance/Test.Runner.swift` | 403 | `disabledReason(_:)` |
| N30 | `Tests Performance/Test.Runner.swift` | 422 | `runWithTraits(_:traits:)` |
| N31 | `Tests Performance/Tests.Suite.swift` | 74 | `padRight(_:toLength:)` |
| N32 | `Tests Performance/Reporting.swift` | 103 | `centerText(_:width:)` |

#### Priority 6 -- Implementation Violations [IMPL-*]

**`.rawValue` at call sites [PATTERN-017]**:

| ID | File | Line | Violation |
|----|------|------|-----------|
| I2 | `Tests Performance/Test.Environment+Capture.swift` | 24 | `optimization.rawValue` -- type has `.description` |
| I3 | `Tests Performance/Test.Environment+JSON.swift` | 29 | `value.optimization.rawValue` |
| I4 | `Tests Performance/Tests.Diagnostic+Format.swift` | 111, 180, 190 | `.rawValue` on `Optimization` and `Trend.Interpretation` |

**`Int(...)` / raw conversions at call sites [IMPL-010] / [IMPL-002]**:

| ID | File | Line | Violation |
|----|------|------|-----------|
| I5 | `Tests Performance/Test.Environment+Capture.swift` | 9-11 | `Int(Kernel.System.Processor.Physical.count)`, `UInt64(Kernel.System.Memory.total)` |
| I6 | `Tests Performance/Test.Environment+JSON.swift` | 26, 66 | `Int(value.memoryBytes)` / `UInt64(memoryBytes)` |
| I7 | `Tests Performance/Tests.Diagnostic+Format.swift` | 108-109 | `Double(environment.memoryBytes) / (1024*1024*1024)` then `Int(memGB.rounded())` |
| I8 | `Tests Core/Test.__TestContentKind.swift` | 34 | FourCC `UInt32(a) << 24 \| ...` |
| I14 | `Tests Performance/Tests.Trend+MannKendall.swift` | 39-49 | `Double(n * (n-1) * (2*n+5))` integer-first then convert |

**Unnecessary intermediate bindings [IMPL-EXPR-001] / [IMPL-030]**:

| ID | File | Line | Violation |
|----|------|------|-----------|
| I10 | `Tests Performance/Reporting.swift` | 103-110 | `let padding`, `let leftPad`, `let rightPad` -- single-use |
| I11 | `Tests Performance/Reporting.swift` | 43-45 | `let minAlloc`, `let maxAlloc`, `let avgAlloc` -- single-use |
| I12 | `Tests Performance/Tests.Diagnostic+Format.swift` | 8 | `let m = measurement` -- pure rename |

**Other**:

| ID | File | Line | Rule | Violation |
|----|------|------|------|-----------|
| I1 | `Tests Inline Snapshot/Test.Snapshot.Inline.Rewriter.swift` | 12 | [PATTERN-009] | `import Foundation` -- rest of package uses `File_System` |
| I13 | `Tests Snapshot/RFC_8259.Value+TreeKeyed.swift` | 107-112 | [IMPL-INTENT] | Redundant bounds check; two branches with identical effect |

#### Summary

| Category | Count |
|----------|:-----:|
| [API-NAME-001] compound types | 9 |
| [API-NAME-002] compound methods/properties | 23 |
| [IMPL-*] implementation | 14 |
| **Total** | **46** |

---

### From: swift-institute/Research/modularization-audit-foundations-batch-A.md (2026-03-20)

**Modularization compliance — MOD-001 through MOD-014**

**Targets**: Tests Core (44), Tests Snapshot (12), Tests Inline Snapshot (9), Tests Performance (45), Tests Reporter (5), Tests (1 -- umbrella), Tests Apple Testing Bridge (4), Tests Test Support (2)

| Rule | Verdict | Notes |
|------|---------|-------|
| MOD-001 Core | PASS | `Tests Core` (44 files) is the Core target. All other targets depend on it. |
| MOD-002 Ext Dep Central | **FAIL** | Tests Core re-exports some deps (Test Primitives, Set Primitives, etc.), but variants declare many external deps directly: Tests Snapshot adds File System, JSON, Kernel, Dependency Primitives; Tests Performance adds Sample Primitives, Time Primitives, Console, Kernel, Memory, Binary Primitives, Formatting Primitives, Dependency Primitives, Clocks, File System, JSON, Environment (10+ external deps). |
| MOD-003 Variant Decomp | PASS | Variants (Snapshot, Performance, Reporter) are independent. Tests Apple Testing Bridge depends on Tests Snapshot (documented: bridges Apple Testing <-> snapshot). |
| MOD-004 Constraint Iso | N/A | No ~Copyable types. |
| MOD-005 Umbrella | PASS | `Tests` target has only `exports.swift` (1 file). Re-exports Core + Reporter + Snapshot + Performance. |
| MOD-006 Dep Min | PASS | Each variant declares only what it needs. |
| MOD-007 Graph Shape | PASS | Max depth = 3 (Tests Core -> Tests Snapshot -> Tests Inline Snapshot -> Tests Apple Testing Bridge). |
| MOD-008 Split Decision | **FAIL** | Tests Core (44 files) and Tests Performance (45 files) are both large. Tests Performance may benefit from splitting (e.g., benchmark infrastructure vs. statistical analysis). |
| MOD-009 Inline Variant | N/A | No inline variants. |
| MOD-010 StdLib Integration | PASS | No stdlib extensions mixed into Core. |
| MOD-011 Test Support | PASS | `Tests Test Support` published as library product, depends on umbrella `Tests`, re-exports upstream test supports (Test Primitives Test Support, Kernel Test Support, File System Test Support). Path: `Tests/Support`. |
| MOD-012 Naming | PASS | All names follow `Tests {Variant}` pattern. `Tests Core`, `Tests Snapshot`, etc. are correct for L3. |
| MOD-013 MARK | PASS | Has semantic `// MARK:` comments: Core, Snapshot, Inline Snapshot, Performance, Reporter, Umbrella, Apple Testing Bridge, Test Support, Tests. |
| MOD-014 Cross-Pkg Traits | PASS | No cross-package optional integrations identified. |

**Detailed Findings**:

1. **F-TESTS-001** (MOD-002): Tests Performance declares 10+ external dependencies that are not re-exported through Tests Core. This is defensible since Performance has a genuinely different dependency profile (time, memory, sampling, file I/O for benchmark persistence), but it violates the centralization principle. Consider whether the common deps (Kernel, Dependency Primitives, File System, JSON) should be re-exported through Core.
2. **F-TESTS-002** (MOD-008): Tests Core (44 files) and Tests Performance (45 files) are both above the 20-25 file guideline. Tests Core may be irreducible (foundational test types), but Tests Performance is a candidate for splitting along concern (benchmark runner vs. statistical reporters vs. benchmark fixtures).
3. **F-TESTS-003** (MOD-005): The umbrella `Tests` re-exports Core + Reporter + Snapshot + Performance but not Tests Inline Snapshot or Tests Apple Testing Bridge. This is likely intentional (inline snapshots require swift-syntax, bridge is Apple-specific), but should be documented.
