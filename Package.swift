// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AdversarialKit",
    products: [
        .library(name: "AdversarialKit", targets: ["AdversarialKit"]),
    ],
    targets: [
        .target(name: "AdversarialKit"),
        .testTarget(name: "AdversarialKitTests", dependencies: ["AdversarialKit"]),
    ]
)
