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

public let nonTrackingDefaultTaskId = Int.min

/// An individual unit of work that can be executed in a concurrent
/// environment by an executor.
// Task cannot be generic since it needs to be referenced by the executor
// class which cannot provide type information for specific tasks.
public protocol Task {

    /// A unique ID number identifying the task.
    var id: Int { get }

    /// Execute this task without any type information.
    ///
    /// - note: This method should only be used by internal executor
    /// implementations.
    /// - returns: The type erased execution result of this task.
    /// - throws: Any error occurred during execution.
    // Return type cannot be generic since the `Task` type needs to be
    // referenced by the executor class which cannot provide type information
    // for results.
    func typeErasedExecute() throws -> Any
}

/// The base abstraction of a task that has a defined execution result
/// type.
// This class is used to allow subclasses to declare result type generics,
// while allowing the internal executor implementations to operate on the
// non-generic, type-erased `Task` protocol, since Swift does not support
// wildcard generics.
open class AbstractTask<ResultType>: Task {

    /// A unique ID number identifying the task.
    public let id: Int

    /// Initializer.
    ///
    /// - parameter id: A unique ID number identifying the task. This value
    /// defaults to `nonTrackingDefaultTaskId`.
    public init(id: Int = nonTrackingDefaultTaskId) {
        self.id = id
    }

    /// Execute this task without any type information.
    ///
    /// - note: This method should only be used by internal executor
    /// implementations.
    /// - returns: The type erased execution result of this task.
    /// - throws: Any error occurred during execution.
    // Return type cannot be generic since the `Task` type needs to be
    // referenced by the executor class which cannot provide type information
    // for results.
    public final func typeErasedExecute() throws -> Any {
        return try execute()
    }

    /// Execute this task and return the result.
    ///
    /// - returns: The execution result of this task.
    /// - throws: Any error occurred during execution.
    open func execute() throws -> ResultType {
        fatalError("\(self).execute is not yet implemented.")
    }
}
