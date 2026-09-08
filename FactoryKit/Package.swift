// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FactoryKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "FactoryKit", targets: ["FactoryKit"]),
    ],
    targets: [
        .target(name: "FactoryKit", path: "Sources/FactoryKit"),
    ]
)
