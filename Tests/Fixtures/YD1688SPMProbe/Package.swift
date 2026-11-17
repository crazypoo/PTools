// swift-tools-version: 6.0
import PackageDescription

// Isolated downstream consumer: no CocoaPods and no YD1688 project modifications.
// Run on macOS with Xcode iOS SDK; manifest validation alone is not a build.
let package = Package(
    name: "YD1688SPMProbe",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "YD1688SPMProbe", targets: ["YD1688SPMProbe"])
    ],
    dependencies: [
        .package(path: "../../..")
    ],
    targets: [
        .target(
            name: "YD1688SPMProbe",
            dependencies: [
                .product(name: "ptools", package: "ptools"),
                .product(name: "PooToolsScanQRCode", package: "ptools"),
                .product(name: "PooToolsNetWork", package: "ptools"),
                .product(name: "PToolsAcknowledgements", package: "ptools"),
                .product(name: "PToolsDate", package: "ptools"),
                .product(name: "PToolsWebBridge", package: "ptools"),
                .product(name: "PooToolsPagingControl", package: "ptools"),
                .product(name: "PooToolsScrollBanner", package: "ptools"),
                .product(name: "PooToolsRateView", package: "ptools"),
                .product(name: "PooToolsStepper", package: "ptools"),
                .product(name: "PooToolsInput", package: "ptools"),
                .product(name: "PooToolsPicker", package: "ptools"),
                .product(name: "PooToolsPhotoPicker", package: "ptools"),
                .product(name: "PooToolsCustomerLabel", package: "ptools"),
                .product(name: "PooToolsTabbar", package: "ptools"),
                .product(name: "PooToolsLoading", package: "ptools"),
                .product(name: "PooToolsWhatsNewsKit", package: "ptools"),
                .product(name: "PooToolsMediaViewer", package: "ptools"),
                .product(name: "PooToolsProgressBar", package: "ptools"),
                .product(name: "PooToolsMessageKit", package: "ptools"),
                .product(name: "PooToolsSocketKit", package: "ptools"),
                .product(name: "PTNotificationPermission", package: "ptools"),
                .product(name: "PTCameraPermission", package: "ptools"),
                .product(name: "PTLocationPermission", package: "ptools"),
                .product(name: "PooToolsCircle", package: "ptools"),
                .product(name: "PooToolsNotificationBanner", package: "ptools"),
                .product(name: "PooToolsCodeView", package: "ptools"),
                .product(name: "PooToolsBioID", package: "ptools"),
                .product(name: "PooToolsSmartScreenshot", package: "ptools"),
                .product(name: "PooToolsFlag", package: "ptools"),
                .product(name: "PooToolsRouter", package: "ptools"),
                .product(name: "PooToolsShare", package: "ptools"),
                .product(name: "PooToolsDataEncrypt", package: "ptools"),
                .product(name: "PooToolsWebKit", package: "ptools"),
                .product(name: "PooToolsOSSKitSpeech", package: "ptools"),
                .product(name: "PooToolsImageEditor", package: "ptools"),
                .product(name: "PooToolsVideoEditor", package: "ptools"),
                .product(name: "PooToolsVideoCache", package: "ptools"),
                .product(name: "PooToolsHud", package: "ptools"),
                .product(name: "PooToolsFilterCamera", package: "ptools"),
                .product(name: "PooToolsPopover", package: "ptools"),
                .product(name: "PToolsAppIntents", package: "ptools")
            ],
            path: "Sources/YD1688SPMProbe"
        )
    ]
)
