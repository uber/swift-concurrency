# Swift Concurrency

[![Build Status](https://travis-ci.com/uber/swift-concurrency.svg?branch=master)](https://travis-ci.com/uber/swift-concurrency?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)


## Contents

- [Requirements](#requirements)
- [Overview](#overview)
- [Installation](#installation)
- [Building](#building)
- [Testing](#testing)

## Requirements

- Xcode 9.3+
- Swift 4.0+

## Overview

A set of concurrency utility classes used by Uber. These are largely inspired by the equivalent [java.util.concurrent](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/package-summary.html) package classes.

### `AtomicBool`
Provides locking-free synchronization of a mutable `Bool`. It provides higher performance than using locks to ensure thread-safety and synchronization correctness.

### `AtomicInt` 
Provides locking-free synchronization of a mutable `Int`. It provides higher performance than using locks to ensure thread-safety and synchronization correctness.

### `AtomicReference`
Provides locking-free synchronization of a mutable object reference. It provides higher performance than using locks to ensure thread-safety and synchronization correctness.

### `CountDownLatch`
A utility class that allows coordination between threads. A count down latch starts with an initial count. Threads can then decrement the count until it reaches zero, at which point, the suspended waiting thread shall proceed. A `CountDownLatch` behaves differently from a `DispatchSemaphore` once the latch is open. Unlike a semaphore where subsequent waits would still block the caller thread, once a `CountDownLatch` is open, all subsequent waits can directly passthrough.

### `ConcurrentSequenceExecutor`
An execution utility that executes sequences of tasks and returns the final result in a highly concurrent environment.

### `SerialSequenceExecutor`
A debugging executor that executes sequences of tasks and returns the final result serially on the caller thread.

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with dylib frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Swift-Concurrency into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "https://github.com/uber/swift-concurrency.git" ~> 0.4.0
```

Run `carthage update` to build the framework and add the built `Concurrency.framework` into your Xcode project, by following the [instructions](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application)

### Manually

If you prefer not to use Carthage, you can integrate Swift-Concurrency into your project manually, by adding the source files.

## Building

First fetch the dependencies:

```bash
$ swift package fetch
```

You can then build from the command-line:

```bash
$ swift build
```

Or create an Xcode project and build using the IDE:

```bash
$ swift package generate-xcodeproj
```

## Testing

From command-line.

```bash
$ swift test
```

Or you can follow the steps above to generate a Xcode project and run tests within Xcode.


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fuber%2Fswift-concurrency.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fuber%2Fswift-concurrency?ref=badge_large)
