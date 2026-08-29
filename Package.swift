// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "XGlass",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "XGlass", targets: ["XGlass"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle.git", exact: "2.9.5")
    ],
    targets: [
        .executableTarget(
            name: "XGlass",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/XGlass",
            exclude: ["Info.plist", "Resources"]
        )
    ]
)
