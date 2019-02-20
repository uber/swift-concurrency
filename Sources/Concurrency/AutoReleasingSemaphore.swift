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

/// Similar to `DispatchSemaphore`, `AutoReleasingSemaphore` is a
/// synchronization mechanism that ensures only a set number of threads can
/// concurrently access a protected resource. Unlike `DispatchSemaphore`,
/// `AutoReleasingSemaphore` auto-releases all blocked threads when the
/// semaphore itself is deallocated.
public class AutoReleasingSemaphore {

    /// Initializer.
    ///
    /// - parameter value: The starting value for the semaphore. Do not
    /// pass a value less than zero.
    public init(value: Int) {
        semaphore = DispatchSemaphore(value: value)
    }

    /// Signals, or increments, a semaphore.
    ///
    /// - note: Increment the counting semaphore. If the previous value
    /// was less than zero, this function wakes a thread currently waiting
    /// in dispatch_semaphore_wait(_:_:).
    /// - returns: This function returns non-zero if a thread is woken.
    /// Otherwise, zero is returned.
    @discardableResult
    public func signal() -> Int {
        let newValue = waitingCount.decrementAndGet()
        if newValue < 0 {
            waitingCount.value = 0
        }
        return semaphore.signal()
    }

    /// Waits for, or decrements, a semaphore.
    ///
    /// - note: Decrement the counting semaphore. If the resulting value
    /// is less than zero, this function waits for a signal to occur
    /// before returning.
    public func wait() {
        waitingCount.incrementAndGet()
        semaphore.wait()
    }

    /// Waits for, or decrements, a semaphore for up to the specified
    /// time.
    ///
    /// - note: Decrement the counting semaphore. If the resulting value
    /// is less than zero, this function waits for a signal to occur
    /// before returning.
    /// - parameter timeout: The amount of time in seconds to wait
    /// before returning with failure.
    /// - returns: The waiting result.
    @discardableResult
    public func wait(timeout: TimeInterval) -> DispatchTimeoutResult {
        waitingCount.incrementAndGet()
        return semaphore.wait(timeout: DispatchTime.now() + timeout)
    }

    deinit {
        for _ in 0 ..< waitingCount.value {
            semaphore.signal()
        }
    }

    // MARK: - Private

    private let semaphore: DispatchSemaphore
    private let waitingCount = AtomicInt(initialValue: 0)
}
