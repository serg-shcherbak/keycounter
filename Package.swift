// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KeyCount",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "KeyCount", targets: ["KeyCount"])
    ],
    targets: [
        .executableTarget(
            name: "KeyCount",
            path: "KeyCount"
        )
    ]
)
