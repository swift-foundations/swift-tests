//
//  Test.Snapshot.Inline.Configuration.swift
//  swift-tests
//
//  Global state for inline snapshot collection.
//

public import Test_Primitives

extension Test.Snapshot.Inline {
    /// Global state accumulator for the current test run.
    ///
    /// Entries are registered during test execution via ``assertInlineSnapshot``
    /// and drained by the runner's post-run write-back hook. The ``State``
    /// class uses a `Mutex` internally for concurrent safety.
    ///
    /// Process-global singleton is appropriate here — inline snapshot collection
    /// spans the entire test run and must survive across individual test scopes.
    public static let state = State()
}
