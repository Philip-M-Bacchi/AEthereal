// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AEthereal",
    platforms: [
        .macOS(.v10_11)
    ],
    products: [
        .library(
            name: "AEthereal",
            targets: ["AEthereal"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ThatsJustCheesy/SDEFinitely", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "AEthereal",
            dependencies: ["SDEFinitely"]
        ),
    ]
)
