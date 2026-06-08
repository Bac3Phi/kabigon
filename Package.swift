// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Kabigon",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),
    ],
    targets: [
        .target(
            name: "KabigonCore",
            path: "Sources/KabigonCore"
        ),
        .executableTarget(
            name: "kabigon",
            dependencies: ["KabigonCore", .product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/App",
            resources: [.copy("Resources/pmd")]
        ),
        .testTarget(
            name: "KabigonCoreTests",
            dependencies: ["KabigonCore"],
            path: "Tests/KabigonCoreTests"
        ),
    ]
)
