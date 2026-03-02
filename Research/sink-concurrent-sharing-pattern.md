# Sink Concurrent Sharing Pattern

<!--
---
version: 1.0.0
last_updated: 2026-03-02
status: DECISION
---
-->

## Context

`Test.Reporter.Sink` is a `~Copyable` type with consuming `finish()` semantics.
The tree-walking test runner needs to share event emission across concurrent task
group closures. A proposed `Sink.Handle` wrapper was created, but the existing
ownership-primitives and reference-primitives packages already provide
infrastructure for sharing `~Copyable` values.

**Trigger**: Implementation of hierarchical test execution engine requires
concurrent event emission from multiple task group children to a single sink.

## Question

What is the theoretically correct ownership pattern for sharing a `~Copyable`
sink's event emission capability across concurrent tasks?

## Analysis

### Type-Theoretic Structure

The Sink presents a **split capability** problem. It bundles two distinct
capabilities in one type:

1. **Send capability**: `send(_ event:) async` — non-consuming, idempotent,
   safe for concurrent use. Semantically a **shared reference** to a channel.
2. **Finish capability**: `finish() consuming async` — consuming, exactly-once,
   must outlive all senders. Semantically a **unique (linear) capability**.

The `~Copyable` constraint on Sink conflates both capabilities. The underlying
`_impl: any SinkImplementation` is a protocol existential that is already
`Copyable` and `Sendable` — it provides both capabilities but with no
ownership discipline.

The theoretical ideal: separate the send capability (shared, copyable) from
the finish capability (unique, consuming).

### Option A: Bespoke `Sink.Handle` Type

Create a new `Sink.Handle` struct wrapping `any SinkImplementation`.

```swift
extension Test.Reporter.Sink {
    public struct Handle: Sendable {
        let _impl: any Test.Reporter.SinkImplementation
        public func send(_ event: Test.Event) async { ... }
    }
    public var handle: Handle { Handle(_impl: _impl) }
}
```

**Advantages:**
- Type-safe: Handle only exposes `send`, not `finish`
- The abstraction boundary communicates intent (send-only capability)
- Simple to understand

**Disadvantages:**
- Bespoke type when primitives already provide sharing patterns
- Requires widening `_impl` from `private` to `@usableFromInline`
- Introduces a new concept (Handle) that doesn't exist in the primitives vocabulary
- The type doesn't compose — it's a one-off wrapper specific to Sink

### Option B: `Ownership.Shared` Wrapping the Impl

Pass `Ownership.Shared(impl)` through the tree walk.

```swift
let sink = reporter.makeSink()
let shared = Ownership.Shared(sink._impl) // shares the impl reference
// ... tasks call shared.value.send(event) ...
await sink.finish()
```

**Advantages:**
- Uses existing primitives infrastructure
- No new types needed
- `Ownership.Shared` is well-understood in the ecosystem

**Disadvantages:**
- `any SinkImplementation` is already Copyable — wrapping a Copyable value
  in `Ownership.Shared` (designed for `~Copyable` values) is semantically wrong.
  Shared adds ARC overhead on top of an existential that already has ARC.
- Still exposes `finish()` via `SinkImplementation` protocol — no capability
  restriction
- Requires `_impl` visibility widening

### Option C: Pass `any SinkImplementation` Directly

Extract the impl from the Sink and pass the existential through the tree walk.

```swift
let sink = reporter.makeSink()
let impl = sink._impl // already Copyable + Sendable
// ... tasks call impl.send(event) ...
await sink.finish()
```

**Advantages:**
- No wrapper type needed
- No double-indirection or redundant ARC
- Uses the natural reference semantics of protocol existentials
- Simplest implementation

**Disadvantages:**
- Exposes `finish()` to tasks that should only send
- Requires `_impl` visibility widening to at least `@usableFromInline`
- No abstraction boundary — callers must discipline themselves to not call `finish()`

### Option D: Sink Provides a Send-Only Projection

The Sink itself provides a method or property that returns a send-only
capability, using the natural structure of the type.

```swift
extension Test.Reporter.Sink {
    /// A send-only capability extracted from this sink.
    ///
    /// The returned closure is Copyable and Sendable — it can be freely
    /// captured in task group closures. The Sink retains ownership of
    /// the finish capability.
    public var sender: @Sendable (Test.Event) async -> Void {
        { [_impl] event in await _impl.send(event) }
    }
}
```

Or using the existing primitives vocabulary:

```swift
extension Test.Reporter {
    /// Protocol for send-only event sinks.
    ///
    /// This is the shared capability extracted from a ~Copyable Sink.
    /// Multiple concurrent tasks can hold references to the same sender.
    public protocol SinkSender: Sendable {
        func send(_ event: Test.Event) async
    }
}
```

With `SinkImplementation` already conforming to `SinkSender` (it has `send`).

**Advantages:**
- Clean capability split: Sink retains finish, sender is send-only
- No visibility widening of `_impl` needed
- No new wrapper struct
- The closure/protocol captures exactly the right capability
- Composable — works with any Sink implementation

**Disadvantages:**
- Closure variant: loses type identity, harder to debug
- Protocol variant: adds a protocol to the type hierarchy

### Comparison

| Criterion | A: Handle | B: Shared | C: Impl Direct | D: Projection |
|-----------|-----------|-----------|-----------------|---------------|
| Uses existing infra | No | Yes | Partial | Partial |
| Capability restriction | Yes (send-only) | No | No | Yes (send-only) |
| _impl visibility change | Yes | Yes | Yes | No |
| New types introduced | 1 (Handle) | 0 | 0 | 0 or 1 |
| Double indirection | No | Yes (redundant) | No | No |
| Type-theoretic correctness | Medium | Wrong (Copyable in Shared) | Low | High |
| Composability | Low | High | Medium | High |

### Theoretical Analysis

The problem is a **substructural capability split**. In linear/affine type theory:

- `Sink` has affine semantics (use at most once for `finish`, many times for `send`)
- The `send` capability is **unrestricted** (copyable, shareable)
- The `finish` capability is **affine** (at most once)

The theoretically perfect decomposition separates these two substructural
profiles. The Sink type should project its unrestricted capability without
exposing the affine one.

Option D achieves this most precisely:
- The `sender` projection extracts the unrestricted (send) capability
- The Sink retains the affine (finish) capability
- No implementation details are exposed
- No new types duplicate existing infrastructure

The closure form `@Sendable (Test.Event) async -> Void` is the simplest
encoding, but lacks a name. A dedicated protocol (`SinkSender`) gives the
capability a name in the type system without creating a wrapper struct.

However, looking at the actual Runner code: the sender is only used within
the Runner's private methods. It never escapes the module. Given this, the
simplest correct approach is to just pass `any SinkImplementation` directly
within the Runner (Option C) — the capability restriction (not calling `finish`)
is enforced by the Runner's own code structure, not the type system.

## Outcome

**Status**: DECISION

**The `_impl` approach (Option C) for the private Runner internals, with the
design space for a public send-only projection (Option D) noted for future API.**

Rationale:
1. `any SinkImplementation` is already `Copyable + Sendable`. Wrapping it in
   `Handle` or `Ownership.Shared` adds indirection for no structural benefit.
2. The capability restriction (send-only) is enforced by the Runner's code
   structure — the `_impl` never escapes the Runner's private methods.
3. No new types are introduced. No `_impl` visibility change beyond
   `@usableFromInline` (which is the minimum for the `handle` property in
   Option A anyway).
4. If a public send-only API is needed in the future, Option D (projection)
   is the correct approach — it keeps `_impl` private and projects only the
   send capability.

**Action**: Remove `Sink.Handle`, revert `_impl` to `private`. The Runner
passes `any SinkImplementation` obtained once at `run()` entry through its
private tree-walking methods. Since `SinkImplementation` is a public protocol
and the Runner is in a different module (`Tests Performance`), the Sink needs
a way to expose the impl. The cleanest approach: add a `@usableFromInline`
internal computed property `var sender: any SinkImplementation { _impl }` that
communicates the send-only intent through naming, or just keep `_impl` as
`@usableFromInline` since the accessor is module-crossing but within our
controlled codebase.

## References

- Ownership Primitives: `Ownership.Shared`, `Ownership.Mutable`, `Ownership.Slot`
- Walker & Watkins, "A Concurrent Logical Framework: The Propositional Fragment"
  (substructural capability types)
- Wadler, "Linear Types Can Change the World!" (affine/linear decomposition)
