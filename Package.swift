// swift-tools-version:5.1

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
            name: "ObjCBridges",
            dependencies:[]),
        .target(
            name: "Concurrency",
            dependencies: ["ObjCBridges"]),
        .testTarget(
            name: "ConcurrencyTests",
            dependencies: ["Concurrency"]),
    ],
    swiftLanguageVersions: [.v5]
)
