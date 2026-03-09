// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WarmToast",
    platforms: [
        .iOS(.v13), .tvOS(.v13)
    ],
    products: [
        .library(
            name: "WarmToast",
            targets: ["WarmToast"]),
    ],
    targets: [
        .target(
            name: "WarmToast"),
        .testTarget(
            name: "WarmToastTests",
            dependencies: ["WarmToast"]
        ),
    ]
)
