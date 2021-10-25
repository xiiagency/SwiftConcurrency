import Foundation

// Number of nanoseconds per second (1M).
private let NANOSECONDS_PER_SECOND: Double = 1_000_000_000

extension Task where Failure == Error {
  /**
   Creates a task with an optional priority that executes the given operation after an initial delay.
   */
  @discardableResult
  public init(
    delaySeconds: Double,
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Success
  ) {
    self.init(priority: priority) {
      try await Task<Never, Never>.sleep(seconds: delaySeconds)
      return try await operation()
    }
  }
}

extension Task where Failure == Never {
  /**
   Creates a task with an optional priority that executes the given operation after an initial delay.
   */
  @discardableResult
  public init(
    delaySeconds: Double,
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async -> Success
  ) {
    self.init(priority: priority) {
      try? await Task<Never, Never>.sleep(seconds: delaySeconds)
      return await operation()
    }
  }
}

extension Task where Success == Never, Failure == Never {
  /**
   Suspends the current task for _at least_ the given duration in seconds, unless the task is cancelled.
   If the task is cancelled, throws `CancellationError` without waiting for the duration.
   
   This function does _not_ block the underlying thread.
   */
  public static func sleep(seconds duration: Double) async throws {
    let nanoseconds = (duration * NANOSECONDS_PER_SECOND).rounded(.up)
    try await sleep(nanoseconds: UInt64(nanoseconds))
  }
  
  /**
   Performs a polling action at a specific interval, timing out if the action does not return `true` within the timeout interval.
   Returns `true` if the polling action succeeds and `false` if the task has timed out or has been cancelled.
   */
  public static func poll(
    intervalSeconds: Double,
    timeoutSeconds: Double,
    action: @escaping () async throws -> Bool
  ) async throws -> Bool {
    // Mark the start point of the poll.
    let startedOn = Date()
    
    // Loop until we either time out or the action has succeeded.
    while(Date().timeIntervalSince(startedOn) < timeoutSeconds) {
      // Execute the polling action, if it returns true, we are done.
      if try await action() {
        return true
      }
      
      // Yield until the next polling ping should take place.
      try? await Task.sleep(seconds: intervalSeconds)
      
      // Check for cooperative cancellation.
      if Task.isCancelled {
        return false
      }
    }
    
    // If we've reached here the poll timed out, notify the caller.
    return false
  }
}
