// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DIKitCloneChallenge",
    products: [
        .library(
            name: "DIKit",
            targets: ["DIKit"]),
        .library(
            name: "DIGenKit",
            targets: ["DIGenKit"]),
        .executable(
            name: "dikitgen",
            targets: ["dikitgen"])
    ],
    dependencies: [
         .package(
            url: "https://github.com/apple/swift-syntax",
            .branch("0.40200.0")),
         .package(
            url: "https://github.com/apple/swift-package-manager",
            .branch("master"))
    ],
    targets: [
        .target(
            name: "DIKit",
            dependencies: []),
        .target(
            name: "DIGenKit",
            dependencies: ["DIKit", "SwiftSyntax", "Utility"]),
        .target(
            name: "dikitgen",
            dependencies: ["DIGenKit"]),
        .testTarget(
            name: "DIGenKitTests",
            dependencies: ["DIGenKit"])
    ]
)
