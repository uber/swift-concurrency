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

class AutoReleasingSemaphoreTests: XCTestCase {

    func test_wait_releaseAfterWait_verifyAutoRelease() {
        var semaphore: AutoReleasingSemaphore? = AutoReleasingSemaphore(value: 1)

        let autoreleaseExpectation = expectation(description: "autoreleaseExpectation")
        DispatchQueue.global(qos: .background).async {
            semaphore!.wait()
            autoreleaseExpectation.fulfill()
        }

        Thread.sleep(forTimeInterval: 1)

        waitForExpectations(timeout: 5, handler: nil)
      
        semaphore = nil

    }

    func test_waitWithTimeout_verifyTimeout() {
        let semaphore = AutoReleasingSemaphore(value: 0)

        let waitExpectation = expectation(description: "waitExpectation")
        DispatchQueue.global(qos: .background).async {
            let result = semaphore.wait(timeout: 1)
            XCTAssertEqual(result, DispatchTimeoutResult.timedOut)
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func test_wait_releaseAfterWait_overSignaling_verifyAutoRelease() {
        var semaphore: AutoReleasingSemaphore? = AutoReleasingSemaphore(value: 1)
        for _ in 0 ..< 1000 {
            _ = semaphore!.signal()
        }

        let autoreleaseExpectation = expectation(description: "autoreleaseExpectation")
        DispatchQueue.global(qos: .background).async {
            semaphore!.wait()
            autoreleaseExpectation.fulfill()
        }

        Thread.sleep(forTimeInterval: 1)

        waitForExpectations(timeout: 5, handler: nil)
        semaphore = nil

    }
}
