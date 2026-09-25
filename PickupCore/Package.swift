// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PickupCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "PickupCore", targets: ["PickupCore"])],
    targets: [
        .target(name: "PickupCore"),
        .testTarget(name: "PickupCoreTests", dependencies: ["PickupCore"])
    ],
    swiftLanguageModes: [.v6]
)
