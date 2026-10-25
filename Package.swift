// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AdversarialKit",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: [
        .library(name: "AdversarialKit", targets: ["AdversarialKit"]),
    ],
    targets: [
        .target(name: "AdversarialKit"),
        .testTarget(name: "AdversarialKitTests", dependencies: ["AdversarialKit"]),
    ]
)
