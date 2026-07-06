//
//  SerialExecutor.swift
//  swift-tests
//
//  Provides deterministic async testing by routing tasks through a serial executor.
//  Based on the approach from pointfreeco/swift-concurrency-extras.
//

internal import Loader

/// Performs an operation with all spawned tasks running serially on the main executor.
///
/// This function makes async tests deterministic by ensuring tasks execute in a
/// predictable order rather than being subject to the Swift runtime's scheduling.
///
/// On platforms where the Swift runtime hook is unavailable, the operation
/// runs normally without serial enforcement.
///
/// ```swift
/// await withSerialExecutor {
///     // All async work here runs serially and deterministically
/// }
/// ```
///
/// - Warning: Only use this in tests. Do not use in production code.
/// - Parameter operation: The async operation to perform serially.
@MainActor
public func withSerialExecutor<E: Swift.Error>(
    @_implicitSelfCapture operation: @isolated(any) () async throws(E) -> Void
) async throws(E) {
    let previous = _useSerialExecutor
    defer { _useSerialExecutor = previous }
    _useSerialExecutor = true
    try await operation()
}

/// Performs a synchronous operation with serial executor enabled.
///
/// Useful for wrapping entire test methods.
///
/// - Warning: Only use this in tests. Do not use in production code.
/// - Parameter operation: The operation to perform.
public func withSerialExecutor<E: Swift.Error>(
    operation: () throws(E) -> Void
) throws(E) {
    let previous = _useSerialExecutor
    defer { _useSerialExecutor = previous }
    _useSerialExecutor = true
    try operation()
}

/// Controls whether the serial executor is active.
///
/// When `true`, all global task enqueues are redirected to the main actor,
/// making task execution serial and deterministic.
///
/// On platforms where the Swift runtime hook is unavailable, setting this
/// to `true` has no effect and reading always returns `false`.
///
/// - Warning: Only use this in tests. Do not use in production code.
public var _useSerialExecutor: Bool {
    get {
        guard let pointer = unsafe _taskEnqueueHookPointer else { return false }
        return unsafe pointer.pointee != nil
    }
    set {
        guard let pointer = unsafe _taskEnqueueHookPointer else { return }
        unsafe pointer.pointee =
            newValue
            ? { job, _ in MainActor.shared.enqueue(job) }
            : nil
    }
}

// MARK: - Private Implementation

private typealias OriginalHook = @convention(thin) (UnownedJob) -> Void
private typealias TaskEnqueueHook = @convention(thin) (UnownedJob, OriginalHook) -> Void

nonisolated(unsafe)
    private let _taskEnqueueHookPointer: UnsafeMutablePointer<TaskEnqueueHook?>? = {
        let symbol: UnsafeRawPointer
        do throws(Loader.Error) {
            symbol = try unsafe Loader.Symbol.lookup(
                name: "swift_task_enqueueGlobal_hook",
                in: .default
            )
        } catch {
            return nil
        }
        return unsafe UnsafeMutablePointer(
            mutating: symbol.assumingMemoryBound(to: TaskEnqueueHook?.self)
        )
    }()
