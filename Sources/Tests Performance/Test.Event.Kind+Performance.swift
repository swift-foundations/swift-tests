//
//  Test.Event.Kind+Performance.swift
//  swift-tests
//
//  L3 event kinds for structured test data.
//

import Test_Primitives

extension Tagged where Tag == Test.Event, RawValue == Swift.String {

    // MARK: - Run Metadata

    /// Structured plan record with git, environment, and test list.
    public static let planRecord = Self(__unchecked: (), "planRecord")

    /// Structured summary record with counts and failures.
    public static let summaryRecord = Self(__unchecked: (), "summaryRecord")

    // MARK: - Performance Diagnostics

    /// A single performance diagnostic from a `.timed()` test.
    public static let performanceDiagnostic = Self(__unchecked: (), "performanceDiagnostic")

    /// A complexity analysis diagnostic.
    public static let complexityDiagnostic = Self(__unchecked: (), "complexityDiagnostic")

    /// Summary table across all performance tests in the run.
    public static let performanceSummary = Self(__unchecked: (), "performanceSummary")
}
