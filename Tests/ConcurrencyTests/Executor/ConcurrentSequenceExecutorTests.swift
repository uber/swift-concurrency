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

import XCTest
@testable import Concurrency

class ConcurrentConcurrentSequenceExecutorTests: XCTestCase {

    static var allTests = [
        ("test_executeSequence_withSingle_verifyConcurrency", test_executeSequence_withSingle_verifyConcurrency),
        ("test_executeSequence_withNonTerminatingSequence_verifyCancel_verifyConcurrency", test_executeSequence_withNonTerminatingSequence_verifyCancel_verifyConcurrency),
        ("test_executeSequence_withTerminatingSequence_noTimeout_verifyAwaitResult_verifyConcurrency", test_executeSequence_withTerminatingSequence_noTimeout_verifyAwaitResult_verifyConcurrency),
        ("test_executeSequence_withNonTerminatingSequence_withTimeout_verifyAwaitTimeout", test_executeSequence_withNonTerminatingSequence_withTimeout_verifyAwaitTimeout),
    ]

    func test_executeSequence_withSingle_verifyConcurrency() {
        let executor = ConcurrentSequenceExecutor(name: "test_executeSequence_withSingle_verifyConcurrency")

        var threadHashes = [Int: Int]()
        let threadHashesLock = NSRecursiveLock()

        for i in 0 ..< 10000 {
            let didComplete = expectation(description: "task-\(i)")
            let task = MockSelfRepeatingTask {
                threadHashesLock.lock()
                let hash = Thread.current.hash
                threadHashes[hash] = hash
                threadHashesLock.unlock()

                didComplete.fulfill()

                return 68281
            }
            _ = executor.executeSequence(from: task) { (_, result) -> SequenceExecution<Int> in
                return .endOfSequence(result as! Int)
            }
        }

        waitForExpectations(timeout: 3, handler: nil)

        threadHashesLock.lock()
        XCTAssertGreaterThan(threadHashes.count, 4)
        threadHashesLock.unlock()
    }

    func test_executeSequence_withNonTerminatingSequence_verifyCancel_verifyConcurrency() {
        let executor = ConcurrentSequenceExecutor(name: "test_executeSequence_withNonTerminatingSequence_verifyCancel_verifyConcurrency")

        var executionCount = 0
        var threadHashes = [Int: Int]()
        let threadHashesLock = NSRecursiveLock()
        let execution: () -> Int = {
            threadHashesLock.lock()
            let hash = Thread.current.hash
            threadHashes[hash] = hash
            executionCount += 1
            threadHashesLock.unlock()
            return 0
        }
        let sequencedTask = MockSelfRepeatingTask(execution: execution)

        let handle = executor.executeSequence(from: sequencedTask) { _, _ -> SequenceExecution<Int> in
            return .continueSequence(MockSelfRepeatingTask(execution: execution))
        }

        Thread.sleep(forTimeInterval: 1)

        handle.cancel()

        threadHashesLock.lock()
        XCTAssertGreaterThan(threadHashes.count, 1)
        XCTAssertGreaterThanOrEqual(executionCount, threadHashes.count)
        threadHashesLock.unlock()
    }

    func test_executeSequence_withTerminatingSequence_noTimeout_verifyAwaitResult_verifyConcurrency() {
        let executor = ConcurrentSequenceExecutor(name: "test_executeSequence_withTerminatingSequence_noTimeout_verifyAwait_verifyConcurrency")

        var executionCount = 0
        var threadHashes = [Int: Int]()
        let threadHashesLock = NSRecursiveLock()
        let execution: () -> Int = {
            threadHashesLock.lock()
            defer {
                threadHashesLock.unlock()
            }
            let hash = Thread.current.hash
            threadHashes[hash] = hash
            executionCount += 1
            return 0
        }
        let sequencedTask = MockSelfRepeatingTask(execution: execution)

        let handle = executor.executeSequence(from: sequencedTask) { _, _ -> SequenceExecution<Int> in
            return executionCount > 100000 ? .endOfSequence(17823781) : .continueSequence(MockSelfRepeatingTask(execution: execution))
        }

        do {
            let result = try handle.await(withTimeout: nil)
            XCTAssertEqual(result, 17823781)
        } catch {
            XCTFail("Waiting for execution completion failed.")
        }

        threadHashesLock.lock()
        XCTAssertGreaterThan(threadHashes.count, 1)
        XCTAssertGreaterThanOrEqual(executionCount, threadHashes.count)
        threadHashesLock.unlock()
    }

    func test_executeSequence_withNonTerminatingSequence_withTimeout_verifyAwaitTimeout() {
        let executor = ConcurrentSequenceExecutor(name: "test_executeSequence_withNonTerminatingSequence_withTimeout_verifyAwaitTimeout")

        let sequencedTask = MockSelfRepeatingTask {
            return 0
        }

        let handle = executor.executeSequence(from: sequencedTask) { _, _ -> SequenceExecution<Int> in
            return .continueSequence(MockSelfRepeatingTask {
                return 0
            })
        }

        var didThrowError = false
        let startTime = CACurrentMediaTime()
        do {
            _ = try handle.await(withTimeout: 0.5)
        } catch SequenceExecutionError.awaitTimeout {
            didThrowError = true
            let endTime = CACurrentMediaTime()
            XCTAssertTrue((endTime - startTime) >= 0.5)
        } catch {
            XCTFail("Incorrect error thrown: \(error)")
        }

        XCTAssertTrue(didThrowError)
    }
}

class MockSelfRepeatingTask: AbstractTask<Int> {

    private let execution: () -> Int

    init(execution: @escaping () -> Int) {
        self.execution = execution
    }

    override func execute() -> Int {
        return execution()
    }
}
