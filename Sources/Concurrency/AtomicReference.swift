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
import libkern

/// A concurrency utility class that supports locking-free synchronization on mutating an object
/// reference. Unlike using a lock, concurrent read and write accesses to this class is allowed. At
/// the same time, concurrent operations using the atomic functions provided by this class ensures
/// synchronization correctness without the higher cost of locking.
public class AtomicReference<ValueType> {

    /// The value that guarantees atomic read and write-through memory behavior.
    public var value: ValueType {
        get {
            // Create a memory barrier to ensure the entire memory stack is in sync so we
            // can safely retrieve the value. This guarantees the initial value is in sync.
            atomic_thread_fence(memory_order_seq_cst)
            return wrappedValue
        }
        set {
            while true {
                let oldValue = self.value
                if self.compareAndSet(expect: oldValue, newValue: newValue) {
                    break
                }
            }
        }
    }

    /// Initializer.
    ///
    /// - parameter initialValue: The initial value.
    public init(initialValue: ValueType) {
        wrappedValue = initialValue
        pointer.pointee = unsafePassUnretainedPointer(value: wrappedValue)
    }

    /// Atomically sets the new value, if the current value's memory pointer equals the
    /// expected value's memory pointer.
    ///
    /// - parameter expect: The expected value to compare against.
    /// - parameter newValue: The new value to set to if the comparison succeeds.
    /// - returns: true if the comparison succeeded and the value is set. false otherwise.
    public func compareAndSet(expect: ValueType, newValue: ValueType) -> Bool {
        let expectPointer = unsafePassUnretainedPointer(value: expect)
        let newValuePointer = unsafePassUnretainedPointer(value: newValue)

        if AtomicBridges.comparePointer(pointer, withExpectedPointer: expectPointer, andSwapPointer: newValuePointer) {
            // If pointer swap succeeded, a memory berrier is created, so we can safely write the new
            // value.
            wrappedValue = newValue
            return true
        } else {
            return false
        }
    }

    /// Atomically sets to the given new value and returns the old value.
    ///
    /// - parameter newValue: The new value to set to.
    /// - returns: The old value.
    public func getAndSet(newValue: ValueType) -> ValueType {
        while true {
            let oldValue = self.value
            if compareAndSet(expect: oldValue, newValue: newValue) {
                return oldValue
            }
        }
    }

    // MARK: - Private

    private let pointer: UnsafeMutablePointer<UnsafeMutableRawPointer?> = UnsafeMutablePointer.allocate(capacity: 1)

    private var wrappedValue: ValueType

    private func unsafePassUnretainedPointer(value: ValueType) -> UnsafeMutableRawPointer {
        return UnsafeMutableRawPointer(Unmanaged.passUnretained(value as AnyObject).toOpaque())
    }

    deinit {
        #if swift(>=4.1)
            pointer.deallocate()
        #else
            pointer.deallocate(capacity: 1)
        #endif
    }
}
