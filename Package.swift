// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "gir2swift",
    products: [
        .executable(name: "gir2swift", targets: ["gir2swift"]),
        .library(name: "libgir2swift", targets: ["libgir2swift"]),
        .plugin(name: "Gir2SwiftPlugin", targets: ["Gir2SwiftPlugin"])
    ],
    dependencies: [ 
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.6"),
        .package(url: "https://github.com/rhx/SwiftLibXML.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.4.0")
    ],
    targets: [
        .executableTarget(
            name: "gir2swift",
            dependencies: [
                "libgir2swift"
            ]
        ),
        .target(
            name: "libgir2swift",
            dependencies: [
                "SwiftLibXML",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Yams"
            ]
        ),
        
        .plugin(name: "Gir2SwiftPlugin", capability: .buildTool(), dependencies: [.target(name: "gir2swift")]),
        
        
        .testTarget(
            name: "gir2swiftTests",
            dependencies: ["libgir2swift"]
        )
    ]
)
