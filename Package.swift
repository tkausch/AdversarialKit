// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AdversarialKit",
    products: [
        .library(name: "AdversarialKit", targets: ["AdversarialKit"]),
        .executable(name: "TicTacToeSample", targets: ["TicTacToeSample"]),
    ],
    targets: [
        .target(name: "AdversarialKit"),
        .executableTarget(name: "TicTacToeSample", dependencies: ["AdversarialKit"]),
        .testTarget(name: "AdversarialKitTests", dependencies: ["AdversarialKit"]),
    ]
)
