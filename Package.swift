// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "prowl-mcp",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0")
    ],
    targets: [
        .executableTarget(
            name: "prowl-mcp",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
            ]
        ),
        .testTarget(
            name: "prowl-mcpTests",
            dependencies: ["prowl-mcp"]
        ),
    ]
)
