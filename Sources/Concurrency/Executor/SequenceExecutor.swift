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

/// Errors that can occur during a sequence execution.
public enum SequenceExecutionError: Error {
    /// The waiting on sequence completion timed out.
    case awaitTimeout
}

/// The handle of the execution of a sequence of tasks, that allows control
/// and monitoring of the said sequence of tasks.
// This cannot be a protocol, since `SequenceExecutor` references this as a
// type. Protocols with associatedType cannot be directly used as types.
open class SequenceExecutionHandle<SequenceResultType> {

    /// Block the caller thread until the sequence of tasks all finished
    /// execution or the specified timeout period has elapsed.
    ///
    /// - parameter timeout: The duration to wait before the timeout error
    /// is thrown. `nil` to wait indefinitely until the sequence execution
    /// completes.
    /// - throws: `SequenceExecutionError.awaitTimeout` if the given timeout
    /// period elapsed before the sequence execution completed.
    open func await(withTimeout timeout: TimeInterval?) throws -> SequenceResultType {
        fatalError("await not yet implemented.")
    }

    /// Cancel the sequence execution at the point this function is invoked.
    open func cancel() {}
}

/// The execution of a sequence.
public enum SequenceExecution<ResultType> {
    /// The execution of the sequence should continue with the associated
    /// value task.
    case continueSequence(Task)
    /// The end of the entire task sequence with associated value result.
    case endOfSequence(ResultType)
}

/// Executor of sequences of tasks.
///
/// - seeAlso: `Task`.
public protocol SequenceExecutor {

    /// Execute a sequence of tasks from the given initial task.
    ///
    /// - parameter initialTask: The root task of the sequence of tasks
    /// to be executed.
    /// - parameter execution: The execution defining the sequence of tasks.
    /// When a task completes its execution, this closure is invoked with
    /// the task and its produced result.
    /// - returns: The execution handle that allows control and monitoring
    /// of the sequence of tasks being executed.
    func executeSequence<SequenceResultType>(from initialTask: Task, with execution: @escaping (Task, Any) -> SequenceExecution<SequenceResultType>) -> SequenceExecutionHandle<SequenceResultType>
}
