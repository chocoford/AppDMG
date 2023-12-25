// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppDMG",
    platforms: [.macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AppDMG",
            targets: ["AppDMG"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/chocoford/hdiutil.git", branch: "main"),
        .package(url: "https://github.com/chocoford/DSStoreKit.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppDMG",
            dependencies: [
                "hdiutil",
                "DSStoreKit"
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "AppDMGTests",
            dependencies: ["AppDMG"]),
//        .testTarget(
//            name: "DSStoreKitTests",
//            dependencies: ["DSStoreKit"],
//            path: "../DSStoreKit/Tests/DSStoreKitTests"
//        ),
    ]
)
