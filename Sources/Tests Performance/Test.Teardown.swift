//
//  Test.Teardown.swift
//  swift-tests
//
//  Global teardown registry for static test fixtures.
//

public import Test_Primitives

extension Test {
    /// Global teardown actions executed after all tests complete.
    ///
    /// Static fixtures that hold resources (thread pools, channels, file handles)
    /// register cleanup closures here. The test runner drains these in
    /// `postRunActions` after all tests finish but before the process exits.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// static let shared: MyFixture = {
    ///     let fixture = MyFixture()
    ///     Test.Teardown.register { await fixture.shutdown() }
    ///     return fixture
    /// }()
    /// ```
    ///
    /// ## Thread Safety
    ///
    /// Registration happens during `static let` initialization, which is
    /// `dispatch_once`-guarded. Concurrent registration from multiple
    /// initializers is safe but not expected in practice.
    public enum Teardown {
        nonisolated(unsafe) static var actions: [@Sendable () async -> Void] = []

        /// Registers an action to run after all tests complete.
        public static func register(_ action: @Sendable @escaping () async -> Void) {
            unsafe actions.append(action)
        }

        /// Executes and removes all registered teardown actions.
        public static func drain() async {
            for action in unsafe actions { await action() }
            unsafe actions.removeAll()
        }
    }
}
