// swift-tools-version:5.5
import PackageDescription

let package =
  Package(
    name: "SwiftConcurrency",
    platforms: [
      .iOS(.v15),
      .watchOS(.v8),
      .macOS(.v12),
    ],
    products: [
      .library(
        name: "SwiftConcurrency",
        targets: ["SwiftConcurrency"]
      ),
    ],
    dependencies: [],
    targets: [
      .target(
        name: "SwiftConcurrency",
        dependencies: []
      ),
      // NOTE: Re-enable when tests are added.
//      .testTarget(
//        name: "SwiftConcurrencyTests",
//        dependencies: ["SwiftConcurrency"]
//      ),
    ]
  )
