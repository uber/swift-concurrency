//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// An executor that executes sequences of tasks concurrently.
///
/// - seeAlso: `SequenceExecutor`.
/// - seeAlso: `Task`.
public class ConcurrentSequenceExecutor: SequenceExecutor {

    /// Initializer.
    ///
    /// - parameter name: The name of the executor.
    /// - parameter qos: The quality of service of this executor. This
    /// defaults to `userInitiated`.
    public init(name: String, qos: DispatchQoS = .userInitiated) {
        taskQueue = DispatchQueue(label: "Executor.taskQueue-\(name)", qos: qos, attributes: .concurrent)
    }

    /// Execute a sequence of tasks concurrently from the given initial task.
    ///
    /// - parameter initialTask: The root task of the sequence of tasks
    /// to be executed.
    /// - parameter execution: The execution defining the sequence of tasks.
    /// When a task completes its execution, this closure is invoked with
    /// the task and its produced result. This closure is invoked from
    /// multiple threads concurrently, therefore it must be thread-safe.
    /// The tasks provided by this closure are executed concurrently.
    /// - returns: The execution handle that allows control and monitoring
    /// of the sequence of tasks being executed.
    public func executeSequence<SequenceResultType>(from initialTask: Task, with execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) -> SequenceExecutionHandle<SequenceResultType> {
        let handle: SynchronizedSequenceExecutionHandle<SequenceResultType> = SynchronizedSequenceExecutionHandle()
        execute(initialTask, with: handle, execution)
        return handle
    }

    // MARK: - Private

    private let taskQueue: DispatchQueue

    private func execute<SequenceResultType>(_ task: Task, with sequenceHandle: SynchronizedSequenceExecutionHandle<SequenceResultType>, _ execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) {
        taskQueue.async {
            guard !sequenceHandle.isCancelled else {
                return
            }

            let result = task.typeErasedExecute()
            let nextExecution = execution(task, result)
            switch nextExecution {
            case .continueSequence(let nextTask):
                self.execute(nextTask, with: sequenceHandle, execution)
            case .endOfSequence(let result):
                sequenceHandle.sequenceDidComplete(with: result)
            }
        }
    }
}

private class SynchronizedSequenceExecutionHandle<SequenceResultType>: SequenceExecutionHandle<SequenceResultType> {

    private let latch = CountDownLatch(count: 1)
    private let didCancel = AtomicBool(initialValue: false)

    // Use a lock to ensure result is properly accessed, since the read
    // `await` method may be invoked on a different thread than the write
    // `sequenceDidComplete` method.
    private let resultLock = NSRecursiveLock()
    private var result: SequenceResultType?

    fileprivate var isCancelled: Bool {
        return didCancel.value
    }

    fileprivate override func await(withTimeout timeout: TimeInterval?) throws -> SequenceResultType {
        let didComplete = latch.await(timeout: timeout)
        if !didComplete {
            throw SequenceExecutionError.awaitTimeout
        }

        resultLock.lock()
        defer {
            resultLock.unlock()
        }
        // If latch was counted down, the result must have been set. Therefore,
        // this forced unwrap is safe.
        return result!
    }

    fileprivate func sequenceDidComplete(with result: SequenceResultType) {
        resultLock.lock()
        self.result = result
        resultLock.unlock()

        latch.countDown()
    }

    fileprivate override func cancel() {
        didCancel.compareAndSet(expect: false, newValue: true)
    }
}
