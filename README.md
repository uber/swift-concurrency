# Swift Concurrency Utility Classes

A set of concurrency utility classes used by Uber. These are largely inspired by the equivalent [java.util.concurrent](https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/package-summary.html) package classes.

## `AtomicBool` provides locking-free synchronization of a mutable `Bool`. It provides higher performance than using locks to ensure thread-safety and synchronization correctness.

## `AtomicInt` provides locking-free synchronization of a mutable `Int`. It provides higher performance than using locks to ensure thread-safety and synchronization correctness.

## `AtomicReference` provides locking-free synchronization of a mutable object reference. It provides higher performance than using locks to ensure thread-safety and synchronization correctness.

## `CountDownLatch` is a utility class that allows coordination between threads. A count down latch starts with an initial count. Threads can then decrement the count until it reaches zero, at which point, the suspended waiting thread shall proceed.
