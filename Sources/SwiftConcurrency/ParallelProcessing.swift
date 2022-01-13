/**
 Utilities for processing data in parallel on multiple background threads.
 */
public struct ParallelProcessing {
  // NOTE: Private initializer, static utilities only.
  private init() { }
  
  // The default level of parallelism used to process items.
  public static let DEFAULT_MAX_PARALLEL_TASKS = 4
  
  /**
   Applies a processing task (`processItem`) to each item in parallel. Limits the maximum parallelism of the processing
   to `maxParallelTasks` to limit the number of threads created.
   
   NOTE: The default level of parallelism is `Self.DEFAULT_MAX_PARALLEL_TASKS`.
   */
  public static func processItemsInParallel<Item, Result>(
    items: [Item],
    maxParallelTasks: Int = DEFAULT_MAX_PARALLEL_TASKS,
    processInRandomOrder: Bool = true,
    processItem: @escaping (Item) async -> Result?
  ) async -> [Result] {
    // Initialize the processing queue, shuffling the items into random order if requested.
    let queue = OrderedParallelProcessingQueue(
      items: processInRandomOrder ? items.shuffled() : items
    )
    
    // Process items in a single task group, with up to the max parallel tasks,
    // combining individual task results into one long list.
    let results: [Result] = await withTaskGroup(of: [Result].self) { taskGroup in
      for _ in (0..<maxParallelTasks) {
        let _ = taskGroup.addTaskUnlessCancelled {
          // Continue processing until the queue is empty, checking for cancellation along the way.
          var taskResults: [Result] = []
          while let nextItem = await queue.incrementAndGetNextItem() {
            guard !Task.isCancelled else {
              break
            }
            
            guard let result = await processItem(nextItem) else {
              continue
            }
            
            taskResults.append(result)
          }
          
          // Return the results of the task.
          return taskResults
        }
      }
      
      // Combine all task result lists into one long list.
      return await taskGroup.reduce([]) { allResults, taskResults in
        allResults + taskResults
      }
    }
    
    // With the process fully complete, return the overall result list.
    return results
  }
}

/**
 An actor that holds the list of items that require processing via multiple background processes.
 
 Allows for a single item to be served up to each background process to work on at a time, without having to split the list into
 unevenly sized chunks, where some threads will reach their idle states before all processing is completed.
 */
private actor OrderedParallelProcessingQueue<Item> {
  /**
   The list of items to be processed in background.
   */
  private let items: [Item]
  
  /**
   The index of the last item returned by `incrementAndGetNextItem`, nil if the first item has not been returned yet.
   */
  private var currentIndex: Int?
  
  /**
   Initializes the queue with a list of items.
   */
  init(items: [Item]) {
    self.items = items
    self.currentIndex = nil
  }
  
  /**
   Returns the next item in the queue to process, or nil if all items have been processed.
   */
  func incrementAndGetNextItem() -> Item? {
    // Increment the index to the next item to process.
    if let currentIndexValue = currentIndex {
      // We started processing, increment index.
      currentIndex = currentIndexValue + 1
    } else {
      // First query to the queue, start at the head.
      currentIndex = 0
    }
    
    // Ensure that we have a next item, and are not fully done yet.
    guard let currentIndex = currentIndex, currentIndex < items.count else {
      return nil
    }
    
    // Return the next item to process if available.
    return items[currentIndex]
  }
}
