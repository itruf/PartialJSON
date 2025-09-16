// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PartialJSON",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PartialJSON",
            targets: ["PartialJSON"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PartialJSON",
            dependencies: [],
            path: "PartialJSON",
            sources: ["PartialJSON.swift", "Allow.swift"]),
        .testTarget(
            name: "PartialJSONTests",
            dependencies: ["PartialJSON"],
            path: "PartialJSONTests"),
    ],
    swiftLanguageVersions: [.v5]
)
