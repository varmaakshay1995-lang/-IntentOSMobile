// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "IntentOSMobile",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "IntentOSKit",
            targets: ["IntentOSKit"]
        ),
        .executable(
            name: "IntentOSApp",
            targets: ["IntentOSApp"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "IntentOSKit",
            dependencies: [],
            path: "Sources/IntentOSKit"
        ),
        .target(
            name: "IntentOSApp",
            dependencies: ["IntentOSKit"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "IntentOSKitTests",
            dependencies: ["IntentOSKit"],
            path: "Tests/IntentOSKitTests"
        ),
    ]
)
