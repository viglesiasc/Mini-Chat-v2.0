// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "p2",
    dependencies: [
        .package(name: "Socket", url: "https://github.com/Kitura/BlueSocket.git", from: "2.0.0"),
    ],
    targets: [
        .target(
            name: "ChatMessage",
            dependencies: ["Socket"]),
        .target(
            name: "Collections"),
        .target(
            name: "chat-server",
            dependencies: ["Socket", "ChatMessage", "Collections"]),
        .target(
            name: "chat-client",
            dependencies: ["Socket", "ChatMessage"]),
        .testTarget(
            name: "CollectionsTests",
            dependencies: ["Collections"]),
        .target(
            name: "queue-test",
            dependencies: ["Collections"]),
    ]
)
