// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "OpenAppleMacros",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(
            name: "wasm-plugin-server",
            targets: ["wasm-plugin-server"]
        ),
        .executable(
            name: "SwiftUIMacros",
            targets: ["SwiftUIMacros"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-system.git", from: "1.3.2"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0"),
        .package(url: "https://github.com/swiftwasm/WasmKit.git", .upToNextMinor(from: "0.1.5")),
    ],
    targets: [
        .executableTarget(
            name: "SwiftUIMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .executableTarget(
            name: "wasm-plugin-server",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system"),
                .product(name: "WasmKitWASI", package: "WasmKit"),
                .product(name: "_SwiftCompilerPluginMessageHandling", package: "swift-syntax"),
            ]
        ),
    ]
)
