// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScreenShield",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // The library product that will be available to consumers of this package.
        .library(
            name: "ScreenShield",
            targets: ["ScreenShield"]
        )
    ],
    targets: [
        // The main target containing all source files.
        .target(
            name: "ScreenShield",
            path: "Sources/ScreenShield"
        )
    ]
)
