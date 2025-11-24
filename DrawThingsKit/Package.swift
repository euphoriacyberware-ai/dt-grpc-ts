// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DrawThingsKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DrawThingsKit",
            targets: ["DrawThingsKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/grpc/grpc-swift.git", from: "1.23.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.27.0"),
        .package(url: "https://github.com/google/flatbuffers.git", exact: "25.9.23"),
    ],
    targets: [
        .target(
            name: "DrawThingsKit",
            dependencies: [
                .product(name: "GRPC", package: "grpc-swift"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "FlatBuffers", package: "flatbuffers"),
            ]
        ),
        .testTarget(
            name: "DrawThingsKitTests",
            dependencies: ["DrawThingsKit"]
        ),
    ]
)