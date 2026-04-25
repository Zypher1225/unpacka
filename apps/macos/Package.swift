// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Unpacka",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Unpacka", targets: ["Unpacka"])
    ],
    targets: [
        .executableTarget(
            name: "Unpacka",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "UnpackaTests",
            dependencies: ["Unpacka"]
        )
    ]
)
