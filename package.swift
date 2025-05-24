// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SimpleTextEditor",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/raspu/Highlightr.git", from: "2.1.2"),
        .package(url: "https://github.com/johnxnguyen/Down.git", from: "0.11.0")
    ],
    targets: [
        .target(name: "SimpleTextEditor", dependencies: ["Highlightr", "Down"]),
        .testTarget(name: "SimpleTextEditorTests", dependencies: ["SimpleTextEditor"])
    ]
)