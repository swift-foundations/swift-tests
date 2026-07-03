//
//  Test.Expectation.Bridge.swift
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

    extension Test_Primitives.Test.Expectation {
        /// Bridges test expectation failures to Apple's Swift Testing framework.
        ///
        /// Call ``install()`` once before tests run to enable failure reporting
        /// under Apple's native runner.
        ///
        /// When the Institute's `Test.Runner` is active, ``Test/Expectation/Collector/current``
        /// is non-nil and the bridge is never invoked.
        public enum Bridge {
            /// Installs the failure handler that forwards to `Testing.Issue.record`.
            ///
            /// Safe to call multiple times — subsequent calls overwrite with the
            /// same handler. Must be called before test execution begins.
            public static func install() {
                unsafe (Test_Primitives.Test.Expectation.externalFailureHandler) = { message, location in
                    Testing.Issue.record(
                        Testing.Comment(rawValue: message),
                        sourceLocation: Testing.SourceLocation(
                            fileID: location.fileID,
                            filePath: location.filePath ?? location.fileID,
                            line: Swift.Int(location.line.underlying),
                            column: Swift.Int(location.column.underlying.rawValue)
                        )
                    )
                }
            }
        }
    }

    /// C-linkage entry point for auto-installation via symbol lookup.
    ///
    /// Tests Core resolves this symbol at runtime using `Loader.Symbol.lookup`.
    /// When the bridge module is linked, the symbol is found and the bridge
    /// installs automatically on first failure — no manual `Bridge.install()` needed.
    @c(_swift_tests_bridge_install)
    func _installBridge() {
        Test_Primitives.Test.Expectation.Bridge.install()
    }
#endif
