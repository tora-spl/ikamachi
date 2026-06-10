// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IkaMachiKit",
    platforms: [.iOS(.v17), .macOS(.v15)],
    products: [
        .library(name: "IkaMachiKit", targets: ["IkaMachiKit"])
    ],
    targets: [
        .target(
            name: "IkaMachiKit",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "IkaMachiKitTests",
            dependencies: ["IkaMachiKit"],
            resources: [.copy("Fixtures")]
        )
    ]
)
