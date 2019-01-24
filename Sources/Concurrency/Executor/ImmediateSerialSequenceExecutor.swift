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

/// An executor that executes sequences of tasks serially from the
/// caller thread as soon as the execute method is invoked.
///
/// - note: Generally this implementation should only be used for debugging
/// purposes, as debugging highly concurrent task executions can be very
/// challenging. Production code should use `ConcurrentSequenceExecutor`.
/// - seeAlso: `SequenceExecutor`.
/// - seeAlso: `Task`.
public class ImmediateSerialSequenceExecutor: SequenceExecutor {

    /// Initializer.
    public init() {}

    /// Execute a sequence of tasks serially from the given initial task
    /// on the caller thread, immediately.
    ///
    /// - parameter initialTask: The root task of the sequence of tasks
    /// to be executed.
    /// - parameter execution: The execution defining the sequence of tasks.
    /// When a task completes its execution, this closure is invoked with
    /// the task and its produced result. This closure is invoked from
    /// the caller thread serially as each task completes. The tasks provided
    /// by this closure are executed serially on the initial caller thread.
    /// - returns: The execution handle that allows control and monitoring
    /// of the sequence of tasks being executed.
    public func executeSequence<SequenceResultType>(from initialTask: Task, with execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) -> SequenceExecutionHandle<SequenceResultType> {
        let handle: SequenceExecutionHandleImpl<SequenceResultType> = SequenceExecutionHandleImpl()
        execute(initialTask, with: handle, execution)
        return handle
    }

    // MARK: - Private

    private func execute<SequenceResultType>(_ task: Task, with sequenceHandle: SequenceExecutionHandleImpl<SequenceResultType>, _ execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) {
        guard !sequenceHandle.isCancelled else {
            return
        }

        do {
            let result = try task.typeErasedExecute()
            let nextExecution = execution(task, result)
            switch nextExecution {
            case .continueSequence(let nextTask):
                self.execute(nextTask, with: sequenceHandle, execution)
            case .endOfSequence(let result):
                sequenceHandle.sequenceDidComplete(with: result)
            }
        } catch {
            sequenceHandle.sequenceDidError(with: error)
        }
    }
}

private class SequenceExecutionHandleImpl<SequenceResultType>: SequenceExecutionHandle<SequenceResultType> {

    private var didCancel = false
    private var result: SequenceResultType?
    private var error: Error?

    fileprivate var isCancelled: Bool {
        return didCancel
    }

    fileprivate override func await(withTimeout timeout: TimeInterval?) throws -> SequenceResultType {
        if let error = self.error {
            throw error
        } else {
            return result!
        }
    }

    fileprivate func sequenceDidComplete(with result: SequenceResultType) {
        self.result = result
    }

    fileprivate func sequenceDidError(with error: Error) {
        self.error = error
    }

    fileprivate override func cancel() {
        didCancel = true
    }
}
