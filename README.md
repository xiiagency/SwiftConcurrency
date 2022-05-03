# SwiftConcurrency Library

[![GitHub](https://img.shields.io/github/license/xiiagency/SwiftConcurrency?style=for-the-badge)](./LICENSE)

An open source library with utilities and extensions to support Swift async/await concurrency.

Developed as re-usable components for various projects at
[XII's](https://github.com/xiiagency) iOS, macOS, and watchOS applications.

## Installation

### Swift Package Manager

1. In Xcode, select File > Swift Packages > Add Package Dependency.
2. Follow the prompts using the URL for this repository
3. Select the `SwiftConcurrency` library to add to your project

## License

See the [LICENSE](LICENSE) file.

## Starting `Task`s with a delay specified in seconds ([Source](Sources/SwiftConcurrency/Task%2BExtensions.swift))

```Swift
extension Task where Failure == Error {
  init(
    delaySeconds: Double,
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async throws -> Success
  )
}

extension Task where Failure == Never {
  init(
    delaySeconds: Double,
    priority: TaskPriority? = nil,
    operation: @escaping @Sendable () async -> Success
  )
}
```

Creates a task with an optional priority that executes the given operation after an initial delay (in seconds).

This is a shorthand for starting a task and then calling `Task.sleep` with a number of nanoseconds to wait.

## `Task::sleep`, but in seconds([Source](Sources/SwiftConcurrency/Task%2BExtensions.swift))

```Swift
extension Task {
  static func sleep(seconds duration: Double) async throws
}
```

Suspends the current task for _at least_ the given duration in seconds, unless the task is cancelled. If the task is cancelled, throws `CancellationError` without waiting for the duration.
This function does _not_ block the underlying thread.

## Using `Task` to poll for operation completion ([Source](Sources/SwiftConcurrency/Task%2BExtensions.swift))

```Swift
extension Task {
  static func poll(
    intervalSeconds: Double,
    timeoutSeconds: Double,
    action: @escaping () async throws -> Bool
  ) async throws
}
```

Performs a polling action at a specific interval, timing out if the action does not return `true` within the timeout interval.

Returns `true` if the polling action succeeds and `false` if the task has timed out or has been cancelled.

## Processing work items via parallel work queue ([Source](Sources/SwiftConcurrency/ParallelProcessing.swift))

```Swift
struct ParallelProcessing {
  static let DEFAULT_MAX_PARALLEL_TASKS = 4

  static func processItemsInParallel<Item, Result>(
    items: [Item],
    maxParallelTasks: Int = DEFAULT_MAX_PARALLEL_TASKS,
    processInRandomOrder: Bool = true,
    processItem: @escaping (Item) async -> Result?
  ) async -> [Result]
}
```

Applies a processing task (`processItem`) to each item in parallel. Limits the maximum parallelism of the processing to `maxParallelTasks` to limit the number of threads created.

All items provided are added to a work queue that is then drained by multiple parallel `Task`s.
