//
//  Test.Expectation.AppleBridge.swift
//  swift-tests
//
//  Installs the Apple Testing failure bridge.
//
//  When tests run under Apple's Swift Testing runner (without the
//  Institute's Test.Runner), Collector.current is nil and failures
//  would be silently dropped. This bridge forwards them to
//  Testing.Issue.record so they surface in test output.
//

#if canImport(Testing)
import Tests_Core
import Testing

/// Bridges test expectation failures to Apple's Swift Testing framework.
///
/// Call ``install()`` once before tests run to enable failure reporting
/// under Apple's native runner.
///
/// When the Institute's `Test.Runner` is active, ``Test/Expectation/Collector/current``
/// is non-nil and the bridge is never invoked.
public enum AppleTestingBridge {
    /// Installs the failure handler that forwards to `Testing.Issue.record`.
    ///
    /// Safe to call multiple times — subsequent calls overwrite with the
    /// same handler. Must be called before test execution begins.
    public static func install() {
        Test_Primitives.Test.Expectation.externalFailureHandler = { message, location in
            Testing.Issue.record(
                Testing.Comment(rawValue: message),
                sourceLocation: Testing.SourceLocation(
                    fileID: location.fileID,
                    filePath: location.filePath ?? location.fileID,
                    line: location.line,
                    column: location.column
                )
            )
        }
    }
}
#endif
