// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Support",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        .library(
            name: "Support",
            targets: ["Support"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Support",
            dependencies: [],
            swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
        ),
        .testTarget(
            name: "SupportTests",
            dependencies: ["Support"]
        ),
    ]
)
