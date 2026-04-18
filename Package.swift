// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "VibeGesture",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "VibeGesture",
            targets: ["VibeGesture"]
        )
    ],
    targets: [
        .executableTarget(
            name: "VibeGesture"
        ),
        .testTarget(
            name: "VibeGestureTests",
            dependencies: ["VibeGesture"]
        )
    ]
)
