// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "tinytomato",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "tinytomato",
            path: "Sources/tinytomato"
        )
    ]
)
