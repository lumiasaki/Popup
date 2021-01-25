// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Popup",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Popup",
            targets: ["Popup"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
          url: "https://github.com/davecom/SwiftPriorityQueue.git",
          .upToNextMinor(from: "1.3.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Popup",
            dependencies: ["SwiftPriorityQueue"]
            exclude: ["Example"]
        ),
        .testTarget(
            name: "PopupTests",
            dependencies: ["Popup"]),
    ]
)
