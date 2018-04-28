// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Concurrency",
    products: [
        .library(
            name: "Concurrency",
            targets: ["Concurrency"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Concurrency",
            dependencies: []),
        .testTarget(
            name: "ConcurrencyTests",
            dependencies: ["Concurrency"]),
    ],
    swiftLanguageVersions: [4]
)
