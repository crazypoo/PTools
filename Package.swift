// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ptools",
    // English: Declare a default localization for legacy .lproj resources and Xcode String Catalogs.
    // Español: Declara una localización predeterminada para recursos .lproj y catálogos de Xcode.
    // 中文：旧版 .lproj 资源和 Xcode String Catalog 都需要声明默认本地化语言。
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        // ==========================================
        // 核心基座
        // ==========================================
        .library(name: "ptools", targets: ["ptools"]),
        // English: Publish the Foundation-only layers so clients can depend on the smallest stable module.
        // Español: Publica las capas basadas solo en Foundation para que los clientes dependan del módulo mínimo estable.
        // 中文：公开仅依赖 Foundation 的分层模块，让调用方按需依赖最小稳定模块。
        .library(name: "PToolsCore", targets: ["PToolsCore"]),
        .library(name: "PToolsUIFoundation", targets: ["PToolsUIFoundation"]),
        // English: Publish permission contracts separately so system services do not import the full UI umbrella.
        // Español: Publica los contratos de permisos por separado para que los servicios del sistema no importen todo el umbrella de UI.
        // 中文：独立公开权限契约，避免系统服务引入完整 UI umbrella。
        .library(name: "PToolsPermissionCore", targets: ["PToolsPermissionCore"]),
        .library(name: "PToolsPermissionUI", targets: ["PToolsPermissionUI"]),

        // ==========================================
        // 基础 UI 与细分组件模块
        // ==========================================
        .library(name: "PooToolsCustomerLabel", targets: ["PooToolsCustomerLabel"]),
        .library(name: "PooToolsProgressBar", targets: ["PooToolsProgressBar"]),
        .library(name: "PooToolsPageControl", targets: ["PooToolsPageControl"]),
        .library(name: "PooToolsLoading", targets: ["PooToolsLoading"]),
        .library(name: "PooToolsHud", targets: ["PooToolsHud"]),
        .library(name: "PooToolsLivePhoto", targets: ["PooToolsLivePhoto"]),
        .library(name: "PooToolsShare", targets: ["PooToolsShare"]),
        .library(name: "PooToolsPDF", targets: ["PooToolsPDF"]),
        .library(name: "PooToolsSVG", targets: ["PooToolsSVG"]),

        // ==========================================
        // 权限模块 (Permissions)
        // ==========================================
        .library(name: "PTCameraPermission", targets: ["PTCameraPermission"]),
        .library(name: "PTLocationPermission", targets: ["PTLocationPermission"]),
        .library(name: "PTCalendarPermission", targets: ["PTCalendarPermission"]),
        .library(name: "PTMotionPermission", targets: ["PTMotionPermission"]),
        .library(name: "PTTrackingPermission", targets: ["PTTrackingPermission"]),
        .library(name: "PTRemindersPermission", targets: ["PTRemindersPermission"]),
        .library(name: "PTSpeechPermission", targets: ["PTSpeechPermission"]),
        .library(name: "PTHealthPermission", targets: ["PTHealthPermission"]),
        .library(name: "PTFaceIDPermission", targets: ["PTFaceIDPermission"]),
        .library(name: "PTContactsPermission", targets: ["PTContactsPermission"]),
        .library(name: "PTMicPermission", targets: ["PTMicPermission"]),
        .library(name: "PTMediaPermission", targets: ["PTMediaPermission"]),
        .library(name: "PTBluetoothPermission", targets: ["PTBluetoothPermission"]),
        .library(name: "PTSiriPermission", targets: ["PTSiriPermission"]),
        .library(name: "PTNotificationPermission", targets: ["PTNotificationPermission"]),

        // ==========================================
        // 核心中上层依赖模块
        // ==========================================
        .library(name: "PooToolsNetWork", targets: ["PooToolsNetWork"]),
        .library(name: "PooToolsDataEncrypt", targets: ["PooToolsDataEncrypt"]),
        .library(name: "PooToolsSearchBar", targets: ["PooToolsSearchBar"]),
        .library(name: "PooToolsMediaViewer", targets: ["PooToolsMediaViewer"]),

        // ==========================================
        // 高级业务模块
        // ==========================================
        .library(name: "PooToolsImagePicker", targets: ["PooToolsImagePicker"]),
        .library(name: "PooToolsPhotoPicker", targets: ["PooToolsPhotoPicker"]),
        .library(name: "PooToolsHarbethKit", targets: ["PooToolsHarbethKit"]),
        .library(name: "PooToolsImageEditor", targets: ["PooToolsImageEditor"]),
        .library(name: "PooToolsVideoEditor", targets: ["PooToolsVideoEditor"]),
        .library(name: "PooToolsCheckDirtyWord", targets: ["PooToolsCheckDirtyWord"]),

        // ==========================================
        // 其他基础功能 Target 映射
        // ==========================================
        .library(name: "PooToolsStepper", targets: ["PooToolsStepper"]),
        .library(name: "PooToolsBankCard", targets: ["PooToolsBankCard"]),
        .library(name: "PooToolsBioID", targets: ["PooToolsBioID"]),
        .library(name: "PooToolsCalendar", targets: ["PooToolsCalendar"]),
        .library(name: "PooToolsTelephony", targets: ["PooToolsTelephony"]),
        .library(name: "PooToolsCheckBox", targets: ["PooToolsCheckBox"]),
        .library(name: "PooToolsCodeView", targets: ["PooToolsCodeView"]),
        .library(name: "PooToolsCountry", targets: ["PooToolsCountry"]),
        .library(name: "PooToolsGuide", targets: ["PooToolsGuide"]),
        .library(name: "PooToolsInput", targets: ["PooToolsInput"]),
        .library(name: "PooToolsKeyboard", targets: ["PooToolsKeyboard"]),
        .library(name: "PooToolsKeyChain", targets: ["PooToolsKeyChain"]),
        .library(name: "PooToolsMotion", targets: ["PooToolsMotion"]),
        .library(name: "PooToolsPhoneInfo", targets: ["PooToolsPhoneInfo"]),
        .library(name: "PooToolsRateView", targets: ["PooToolsRateView"]),
        .library(name: "PooToolsScrollBanner", targets: ["PooToolsScrollBanner"]),
        .library(name: "PooToolsSegmented", targets: ["PooToolsSegmented"]),
        .library(name: "PooToolsHandSign", targets: ["PooToolsHandSign"]),
        .library(name: "PooToolsSlider", targets: ["PooToolsSlider"]),
        .library(name: "PooToolsCheckUpdate", targets: ["PooToolsCheckUpdate"]),
        .library(name: "PooToolsLayout", targets: ["PooToolsLayout"]),
        .library(name: "PooToolsLocation", targets: ["PooToolsLocation"]),
        .library(name: "PooToolsSmartScreenshot", targets: ["PooToolsSmartScreenshot"]),
        .library(name: "PooToolsPagingControl", targets: ["PooToolsPagingControl"]),
        .library(name: "PooToolsScanQRCode", targets: ["PooToolsScanQRCode"]),
        .library(name: "PooToolsStepCount", targets: ["PooToolsStepCount"]),
        .library(name: "PooToolsContact", targets: ["PooToolsContact"]),
        .library(name: "PooToolsVision", targets: ["PooToolsVision"]),
        .library(name: "PooToolsRouter", targets: ["PooToolsRouter"]),
        .library(name: "PooToolsPing", targets: ["PooToolsPing"]),
        .library(name: "PooToolsSpeedPanel", targets: ["PooToolsSpeedPanel"]),
        .library(name: "PooToolsNetworkSpeedTest", targets: ["PooToolsNetworkSpeedTest"]),
        .library(name: "PooToolsOSSKitSpeech", targets: ["PooToolsOSSKitSpeech"]),
        .library(name: "PooToolsiOS17Tips", targets: ["PooToolsiOS17Tips"]),
        .library(name: "PooToolsWhatsNewsKit", targets: ["PooToolsWhatsNewsKit"]),
        .library(name: "PooToolsHeartRate", targets: ["PooToolsHeartRate"]),
        .library(name: "PooToolsChinesePinyin", targets: ["PooToolsChinesePinyin"]),
        .library(name: "PooToolsCircle", targets: ["PooToolsCircle"]),
        .library(name: "PooToolsMessageKit", targets: ["PooToolsMessageKit"]),
        .library(name: "PooToolsSocketKit", targets: ["PooToolsSocketKit"]),
        .library(name: "PooToolsIAP", targets: ["PooToolsIAP"]),
        .library(name: "PooToolsTipsView", targets: ["PooToolsTipsView"]),
        .library(name: "PooToolsPicker", targets: ["PooToolsPicker"]),

        // ==========================================
        // 调试工具模块 (DEBUG)
        // ==========================================
        .library(name: "PooToolsDEBUG", targets: ["PooToolsDEBUG"]),
        .library(name: "PooToolsDEBUGTrackingEyes", targets: ["PooToolsDEBUGTrackingEyes"]),
        .library(name: "PooToolsLaunchTimeProfiler", targets: ["PooToolsLaunchTimeProfiler"]),

        // ==========================================
        // 整合全家桶 (供需要一次性引入全部功能的开发者使用)
        // ==========================================
        .library(name: "PooToolsAll", targets: [
            "ptools",
            "PToolsPermissionCore", "PToolsPermissionUI",
            "PooToolsCustomerLabel", "PooToolsProgressBar", "PooToolsPageControl", "PooToolsLoading",
            "PooToolsHud", "PooToolsLivePhoto", "PooToolsShare", "PooToolsPDF",
            "PooToolsSVG",
            "PTCameraPermission", "PTLocationPermission", "PTCalendarPermission", "PTMotionPermission",
            "PTTrackingPermission", "PTRemindersPermission", "PTSpeechPermission", "PTHealthPermission",
            "PTFaceIDPermission", "PTContactsPermission", "PTMicPermission", "PTMediaPermission",
            "PTBluetoothPermission", "PTSiriPermission", "PTNotificationPermission",
            "PooToolsNetWork", "PooToolsDataEncrypt", "PooToolsSearchBar",
            "PooToolsMediaViewer", "PooToolsImagePicker", "PooToolsPhotoPicker", "PooToolsHarbethKit",
            "PooToolsImageEditor", "PooToolsVideoEditor", "PooToolsCheckDirtyWord", "PooToolsStepper",
            "PooToolsBankCard", "PooToolsBioID", "PooToolsCalendar", "PooToolsTelephony", "PooToolsCheckBox",
            "PooToolsCodeView", "PooToolsCountry", "PooToolsGuide", "PooToolsInput", "PooToolsKeyboard",
            "PooToolsKeyChain", "PooToolsMotion", "PooToolsPhoneInfo", "PooToolsRateView", "PooToolsScrollBanner",
            "PooToolsSegmented", "PooToolsHandSign", "PooToolsSlider", "PooToolsCheckUpdate", "PooToolsLayout",
            "PooToolsLocation", "PooToolsSmartScreenshot", "PooToolsPagingControl", "PooToolsScanQRCode",
            "PooToolsStepCount", "PooToolsContact", "PooToolsVision", "PooToolsRouter", "PooToolsPing",
            "PooToolsSpeedPanel", "PooToolsNetworkSpeedTest", "PooToolsOSSKitSpeech", "PooToolsiOS17Tips",
            "PooToolsWhatsNewsKit", "PooToolsHeartRate", "PooToolsChinesePinyin", "PooToolsCircle",
            "PooToolsMessageKit", "PooToolsSocketKit", "PooToolsIAP", "PooToolsTipsView",
            "PooToolsDEBUG", "PooToolsDEBUGTrackingEyes","PooToolsLaunchTimeProfiler","PooToolsPicker"
        ])
    ],
    dependencies: [
        // Core 依赖
        .package(url: "https://github.com/malcommac/SwiftDate.git", exact: "7.0.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", exact: "5.7.1"),
        .package(url: "https://github.com/SwifterSwift/SwifterSwift.git", from: "8.0.0"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", from: "3.8.0"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.8.0"),
        .package(url: "https://github.com/lixiang1994/AttributedString.git", revision: "d8a72a7e29e8699979b052b59659720087bc2ea0"),
        .package(url: "https://github.com/hackiftekhar/IQKeyboardManager.git", exact: "8.0.3"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", exact: "8.9.0"),
        .package(url: "https://github.com/sparrowcode/SafeSFSymbols.git", from: "2.0.0"),
        .package(url: "https://github.com/iAmMccc/SmartCodable.git", from: "4.0.0"),
        .package(url: "https://github.com/kakaopensource/KakaJSON.git", exact: "1.1.2"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0"),
        
        // English: Keep feature dependencies explicit and reproducible.
        // Español: Mantén las dependencias de funciones explícitas y reproducibles.
        // 中文：保持功能依赖显式且可复现。
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/Daltron/NotificationBanner.git", exact: "3.2.0"),
        
        // English: Declare MarqueeLabel because NotificationBanner does not expose this dependency reliably.
        // Español: Declara MarqueeLabel porque NotificationBanner no expone esta dependencia de forma fiable.
        // 中文：显式声明 MarqueeLabel，避免 NotificationBanner 的隐式依赖解析不稳定。
        .package(url: "https://github.com/cbpowell/MarqueeLabel.git", from: "4.5.3"),
        // English: Swift-JWT owns its Kitura cryptography dependencies transitively; do not duplicate them in PTools.
        // Español: Swift-JWT mantiene sus dependencias criptográficas de Kitura de forma transitiva; PTools no las duplica.
        // 中文：Swift-JWT 通过传递依赖维护 Kitura 加密组件，PTools 不再重复声明它们。
        
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
        .package(url: "https://github.com/amirdew/CollectionViewPagingLayout.git", exact: "1.1.0"),
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", from: "2.6.0"),
        .package(url: "https://github.com/pujiaxin33/JXPagingView.git", from: "2.1.0"),
        .package(url: "https://github.com/pujiaxin33/JXSegmentedView.git", from: "1.3.0"),
        .package(url: "https://github.com/ephread/Instructions.git", from: "2.2.0"),
        .package(url: "https://github.com/PhoneNumberKit/PhoneNumberKit.git", from: "5.0.0"),
        .package(url: "https://github.com/securing/IOSSecuritySuite.git", from: "1.9.0"),
        .package(url: "https://github.com/yangKJ/Harbeth.git", from: "1.1.0"),
        .package(url: "https://github.com/yangKJ/Kakapos.git", exact: "1.1.0"),
        .package(url: "https://github.com/aheze/Popovers.git", from: "1.3.0"),
        .package(url: "https://github.com/pocketsvg/PocketSVG.git", from: "2.7.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "1.37.0"),
        .package(url: "https://github.com/madebybowtie/FlagKit.git", exact: "2.4.0"),
        .package(url: "https://github.com/robnadin/SocketRocket.git", revision: "fe86ec01176ea3365ffa2d04a2bb6dd7a9e6c01e"),
        .package(url: "https://github.com/Kitura/Swift-JWT.git", exact: "4.0.0")

    ],
    targets: [
        // English: PToolsCore contains only value types, URL parsing, and Foundation/Objective-C compatibility helpers.
        // Español: PToolsCore solo contiene tipos de valor, análisis URL y compatibilidad de Foundation/Objective-C.
        // 中文：PToolsCore 只包含值类型、URL 解析以及 Foundation/Objective-C 兼容辅助能力。
        .target(
            name: "PToolsCore",
            path: "PooToolsSource/PToolsCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferSendableFromCaptures")
            ]
        ),
        // English: PToolsUIFoundation owns the standalone SnapKit UI helper without changing legacy source paths.
        // Español: PToolsUIFoundation posee el auxiliar UI independiente de SnapKit sin cambiar las rutas heredadas.
        // 中文：PToolsUIFoundation 独立承载 SnapKit UI 辅助能力，同时不改变旧源码路径。
        .target(
            name: "PToolsUIFoundation",
            dependencies: ["SnapKit"],
            path: "PooToolsSource/PToolsUIFoundation",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferSendableFromCaptures")
            ]
        ),
        // English: Keep permission state, errors, and request protocols independent from UIKit and feature modules.
        // Español: Mantén el estado, los errores y los protocolos de permisos independientes de UIKit y de los módulos de funciones.
        // 中文：让权限状态、错误和请求协议独立于 UIKit 与具体功能模块。
        .target(
            name: "PToolsPermissionCore",
            path: "PooToolsSource/PToolsPermissionCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferSendableFromCaptures")
            ]
        ),
        // English: Keep UIKit-only settings presentation optional and isolated from system permission services.
        // Español: Mantén opcional la presentación de ajustes basada en UIKit y aislada de los servicios de permisos.
        // 中文：让基于 UIKit 的设置页展示保持可选，并与系统权限服务隔离。
        .target(
            name: "PToolsPermissionUI",
            dependencies: ["PToolsPermissionCore", "PToolsUIFoundation"],
            path: "PooToolsSource/PToolsPermissionUI",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferSendableFromCaptures")
            ]
        ),
        // ==========================================
        // 核心基座模块 (Core)
        // ==========================================
        .target(
            name: "ptools",
            dependencies: [
                "PToolsCore",
                "PToolsUIFoundation",
                "PToolsPermissionCore",
                "SwiftDate",
                "SnapKit",
                "SwifterSwift",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                "DeviceKit",
                "AttributedString",
                .product(name: "IQKeyboardManagerSwift", package: "IQKeyboardManager"),
                "Kingfisher",
                "SafeSFSymbols",
                "SmartCodable",
                "KakaJSON",
                .product(name: "Lottie", package: "lottie-ios"),
                "ZipArchive",
                "FlagKit",
                .product(name: "NotificationBannerSwift", package: "NotificationBanner"),
                "Instructions",
                "IOSSecuritySuite",
                "Popovers",
                
            ],
            path: "PooToolsSource",
            sources: [
                "Core", "Blur", "ActionsheetAndAlert", "Base", "AppStore",
                "ApplicationFunction", "BlackMagic", "Button", "Category",
                "Log", "StatusBar", "Protocol", "Animation", "PermissionCore",
                "PhotoLibraryPermission", "AppDelegate", "Foundation",
                "Language", "DarkMode", "Line", "Badge", "Rotation", "Switch",
                "Colors", "Font", "FloatPanel", "SideMenuControl", "iCloud"
            ],
            resources: [
                .process("Resource")
            ],
            swiftSettings: [
                .define("POOTOOLS_COCOAPODS"),
                .define("POOTOOLS_TABBAR"),
                .define("POOTOOLS_ZIPARCHINE"),
                .define("POOTOOLS_FLAG"),
                .define("POOTOOLS_NOTIFICATIONBANNER"),
                .define("POOTOOLS_PICKER"),
                .define("POOTOOLS_INSTRUCTIONS"),
                .define("POOTOOLS_APPZ"),
                .define("POOTOOLS_LAUNCHTIMEPROFILER"),
                .define("POOTOOLS_SECURITYSUITE"),
                .define("POOTOOLS_VIDEOCACHE"),
                .define("POOTOOLS_POPOVERKIT"),
                .define("POOTOOLS_CGDWEBSERVER"),
                .define("POOTOOLS_SPLIT_CORE"),
                .define("POOTOOLS_SPLIT_UIFOUNDATION"),
                .define("POOTOOLS_SPLIT_PERMISSION_CORE"),
                .enableUpcomingFeature("StrictConcurrency"),
                .enableUpcomingFeature("InferSendableFromCaptures")
            ]
        ),

        // ==========================================
        // 基础 UI 与细分组件模块
        // ==========================================
        .target(name: "PooToolsCustomerLabel", dependencies: ["ptools"], path: "PooToolsSource/Label", swiftSettings: [.define("POOTOOLS_CUSTOMERLABEL"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsProgressBar", dependencies: ["ptools"], path: "PooToolsSource/ProgressBar", swiftSettings: [.define("POOTOOLS_PROGRESSBAR"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPageControl", dependencies: ["ptools"], path: "PooToolsSource/PageControl", swiftSettings: [.define("POOTOOLS_PAGECONTROL"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsLoading", dependencies: ["ptools"], path: "PooToolsSource/Loading", swiftSettings: [.define("POOTOOLS_LOADING"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsHud", dependencies: ["ptools", "PooToolsProgressBar"], path: "PooToolsSource/Hud", swiftSettings: [.define("POOTOOLS_HUD"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsLivePhoto", dependencies: ["ptools"], path: "PooToolsSource/LivePhoto", swiftSettings: [.define("POOTOOLS_LIVEPHOTO"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsShare", dependencies: ["PooToolsCustomerLabel"], path: "PooToolsSource/Share", swiftSettings: [.define("POOTOOLS_SHARE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPDF", dependencies: ["ptools"], path: "PooToolsSource/PDF", swiftSettings: [.define("POOTOOLS_PDF"), .define("POOTOOLS_COCOAPODS")]),

        // ==========================================
        // 权限模块 (Permissions)
        // ==========================================
        .target(name: "PTCameraPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/CameraPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_CAMERA"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTLocationPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/LocationPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_LOCATION"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTCalendarPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/CalendarPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_CALENDAR"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTMotionPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/MotionPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_MOTION"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTTrackingPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/TrackingPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_TRACKING"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTRemindersPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/RemindersPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_REMINDERS"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTSpeechPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/SpeechPremission", swiftSettings: [.define("POOTOOLS_PERMISSION_SPEECH"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTHealthPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/HealthPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_HEALTH"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTFaceIDPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/FaceIDPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_FACEIDPERMISSION"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTContactsPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/ContactsPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_CONTACTS"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTMicPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/MicPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_MIC"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTMediaPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/MeidaLibraryPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_MEDIA"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTBluetoothPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/BluetoothPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_BLUETOOTH"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTSiriPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/SiriPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_SIRI"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTNotificationPermission", dependencies: ["PToolsPermissionCore"], path: "PooToolsSource/NotificationPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_NOTIFICATION"), .define("POOTOOLS_SPLIT_PERMISSION_CORE"), .define("POOTOOLS_COCOAPODS")]),

        // ==========================================
        // 核心中上层依赖模块
        // ==========================================
        .target(name: "PooToolsNetWork", dependencies: ["ptools", "PToolsCore", "PooToolsLoading", "Alamofire"], path: "PooToolsSource/NetWork", swiftSettings: [.define("POOTOOLS_NETWORK"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsDataEncrypt", dependencies: ["ptools", "CryptoSwift"], path: "PooToolsSource/AESAndDES", swiftSettings: [.define("POOTOOLS_DATAENCRYPT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSearchBar", dependencies: ["ptools"], path: "PooToolsSource/SearchBar", swiftSettings: [.define("POOTOOLS_SEARCHBAR"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsMediaViewer", dependencies: ["ptools", "PooToolsProgressBar", "PooToolsNetWork", "PooToolsPageControl", "PooToolsLivePhoto"], path: "PooToolsSource/MediaViewer", swiftSettings: [.define("POOTOOLS_MEDIAVIEWER"), .define("POOTOOLS_COCOAPODS")]),

        // ==========================================
        // 高级业务模块
        // ==========================================
        .target(name: "PooToolsImagePicker", dependencies: ["ptools", "PTCameraPermission"], path: "PooToolsSource/ImagePicker", swiftSettings: [.define("POOTOOLS_IMAGEPICKER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPhotoPicker", dependencies: ["ptools", "PooToolsImagePicker", "PTCameraPermission", "PooToolsNetWork", "PooToolsLoading", "Kakapos"], path: "PooToolsSource", sources: ["PhotoPicker"], swiftSettings: [.define("POOTOOLS_PHOTOPICKER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsHarbethKit", dependencies: ["ptools", "Harbeth", "PTCameraPermission"], path: "PooToolsSource/C7Collector", swiftSettings: [.define("POOTOOLS_HARBETHKIT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsImageEditor", dependencies: ["ptools", "Harbeth", "PooToolsHarbethKit", "PooToolsPhotoPicker"], path: "PooToolsSource/ImageEditor", swiftSettings: [.define("POOTOOLS_IMAGEEDITOR"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsVideoEditor", dependencies: ["ptools", "Harbeth", "PooToolsHarbethKit", "PooToolsProgressBar", "PooToolsLoading"], path: "PooToolsSource/VideoEditor", swiftSettings: [.define("POOTOOLS_VIDEOEDITOR"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSVG", dependencies: ["ptools", "Kingfisher", "PocketSVG"], path: "PooToolsSource/KingfisherSVG", swiftSettings: [.define("POOTOOLS_SVG"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCheckDirtyWord", dependencies: ["ptools"], path: "PooToolsSource/CheckDirtyWord", resources: [.process("Resource")], swiftSettings: [.define("POOTOOLS_CHECKDIRTYWORD"), .define("POOTOOLS_COCOAPODS")]),

        // ==========================================
        // 其他基础功能 Target 映射
        // ==========================================
        .target(name: "PooToolsStepper", dependencies: ["ptools"], path: "PooToolsSource/Stepper", swiftSettings: [.define("POOTOOLS_STEPPER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsBankCard", dependencies: ["ptools"], path: "PooToolsSource/BankCard", swiftSettings: [.define("POOTOOLS_BANKCARD"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsBioID", dependencies: ["ptools", "PTFaceIDPermission"], path: "PooToolsSource/BioID", swiftSettings: [.define("POOTOOLS_BILOGYID"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCalendar", dependencies: ["ptools", "PTCalendarPermission", "PTRemindersPermission"], path: "PooToolsSource/Calendar", swiftSettings: [.define("POOTOOLS_CALENDAR"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsTelephony", dependencies: ["ptools"], path: "PooToolsSource/CallMessageMail", swiftSettings: [.define("POOTOOLS_TELEPHONY"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCheckBox", dependencies: ["ptools"], path: "PooToolsSource/CheckBox", swiftSettings: [.define("POOTOOLS_CHECKBOX"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCodeView", dependencies: ["ptools"], path: "PooToolsSource/CodeView", swiftSettings: [.define("POOTOOLS_CODEVIEW"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCountry", dependencies: ["ptools"], path: "PooToolsSource/Country", swiftSettings: [.define("POOTOOLS_COUNTRY"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsGuide", dependencies: ["ptools", "PooToolsPageControl"], path: "PooToolsSource/Guide", swiftSettings: [.define("POOTOOLS_GUIDE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsInput", dependencies: ["ptools", "PhoneNumberKit"], path: "PooToolsSource/Input", swiftSettings: [.define("POOTOOLS_INPUT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsKeyboard", dependencies: ["ptools"], path: "PooToolsSource/Keyboard", swiftSettings: [.define("POOTOOLS_CUSTOMERNUMBERKEYWORD"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsKeyChain", dependencies: ["ptools"], path: "PooToolsSource/KeyChain", swiftSettings: [.define("POOTOOLS_KEYCHAIN"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsMotion", dependencies: ["ptools", "PTMotionPermission"], path: "PooToolsSource/Motion", swiftSettings: [.define("POOTOOLS_MOTION"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPhoneInfo", dependencies: ["ptools"], path: "PooToolsSource/PhoneInfo", swiftSettings: [.define("POOTOOLS_PHONEINFO"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsRateView", dependencies: ["ptools"], path: "PooToolsSource/RateView", swiftSettings: [.define("POOTOOLS_RATE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsScrollBanner", dependencies: ["ptools", "PooToolsPageControl"], path: "PooToolsSource/ScrollBanner", swiftSettings: [.define("POOTOOLS_SCROLLBANNER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSegmented", dependencies: ["ptools"], path: "PooToolsSource/Segmented", swiftSettings: [.define("POOTOOLS_SEGMENT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsHandSign", dependencies: ["ptools"], path: "PooToolsSource/SignView", swiftSettings: [.define("POOTOOLS_HANDSIGN"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSlider", dependencies: ["ptools"], path: "PooToolsSource/Slider", swiftSettings: [.define("POOTOOLS_SLIDER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCheckUpdate", dependencies: ["PooToolsNetWork", .product(name: "SwiftJWT", package: "Swift-JWT")], path: "PooToolsSource/CheckUpdate", swiftSettings: [.define("POOTOOLS_CHECKUPDATE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsLayout", dependencies: ["ptools", "CollectionViewPagingLayout"], path: "PooToolsSource/Layout", swiftSettings: [.define("POOTOOLS_LAYOUT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsLocation", dependencies: ["ptools", "PTLocationPermission"], path: "PooToolsSource/Location", swiftSettings: [.define("POOTOOLS_LOCATION"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSmartScreenshot", dependencies: ["ptools"], path: "PooToolsSource/ScreenShot", swiftSettings: [.define("POOTOOLS_SMARTSCREENSHOT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPagingControl", dependencies: ["ptools", .product(name: "JXPagingView", package: "JXPagingView"), "JXSegmentedView"], path: "PooToolsSource/SegmentControl", swiftSettings: [.define("POOTOOLS_PAGINGCONTROL"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsScanQRCode", dependencies: ["ptools", "PooToolsImagePicker", "PooToolsPhotoPicker", "PTCameraPermission"], path: "PooToolsSource/QRCodeScan", swiftSettings: [.define("POOTOOLS_SCANQRCODE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsStepCount", dependencies: ["ptools", "PTHealthPermission"], path: "PooToolsSource/HealthKit", swiftSettings: [.define("POOTOOLS_STEPCOUNT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsContact", dependencies: ["ptools", "PTContactsPermission"], path: "PooToolsSource/Contact", swiftSettings: [.define("POOTOOLS_CONTACT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsVision", dependencies: ["ptools"], path: "PooToolsSource/Vision", swiftSettings: [.define("POOTOOLS_VISION"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsRouter", dependencies: ["ptools"], path: "PooToolsSource/Router", swiftSettings: [.define("POOTOOLS_ROUTER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPing", dependencies: ["ptools"], path: "PooToolsSource/Ping", swiftSettings: [.define("POOTOOLS_PING"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSpeedPanel", dependencies: ["ptools"], path: "PooToolsSource/SpeedPanel", swiftSettings: [.define("POOTOOLS_SPEEDPANEL"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsNetworkSpeedTest", dependencies: ["ptools"], path: "PooToolsSource/NetworkSpeedTest", swiftSettings: [.define("POOTOOLS_NETWORKSPEEDTEST"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsOSSKitSpeech", dependencies: ["ptools", "PTSpeechPermission"], path: "PooToolsSource/OSSKit", swiftSettings: [.define("POOTOOLS_OSSKITSPEECH"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsiOS17Tips", dependencies: ["ptools"], path: "PooToolsSource/iOS17Tips", swiftSettings: [.define("POOTOOLS_iOS17TIPS"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsWhatsNewsKit", dependencies: ["ptools"], path: "PooToolsSource/WhatsNewsKit", swiftSettings: [.define("POOTOOLS_WHATSNEWSKIT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsHeartRate", dependencies: ["ptools", .product(name: "Lottie", package: "lottie-ios"), "PTCameraPermission"], path: "PooToolsSource/HeartRate", swiftSettings: [.define("POOTOOLS_HEARTRATE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsChinesePinyin", dependencies: ["ptools"], path: "PooToolsSource/Pinyin", swiftSettings: [.define("POOTOOLS_CHINESEPINYIN"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCircle", dependencies: ["ptools"], path: "PooToolsSource/Circle", swiftSettings: [.define("POOTOOLS_CIRCLE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsMessageKit", dependencies: ["ptools", "PooToolsCustomerLabel"], path: "PooToolsSource/MessageKit", swiftSettings: [.define("POOTOOLS_MESSAGEKIT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSocketKit", dependencies: ["ptools", "SocketRocket"], path: "PooToolsSource/SocketKit", swiftSettings: [.define("POOTOOLS_SOCKETKIT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsIAP", dependencies: ["ptools"], path: "PooToolsSource/IAP", swiftSettings: [.define("POOTOOLS_IAP"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsTipsView", dependencies: ["ptools"], path: "PooToolsSource/TipsView", swiftSettings: [.define("POOTOOLS_TIPSVIEW"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPicker", dependencies: ["ptools", "SnapKit", "SwifterSwift"], path: "PooToolsSource/Picker", swiftSettings: [.define("POOTOOLS_PICKER"), .define("POOTOOLS_COCOAPODS")]),

        // ==========================================
        // 调试工具模块 (DEBUG)
        // ==========================================
        .target(
            name: "PooToolsDEBUG",
            dependencies: ["ptools", "PooToolsNetWork", "PooToolsShare", "PooToolsSearchBar", "PooToolsPDF"],
            path: "PooToolsSource",
            sources: [
                "Debug", "LocalConsole", "DevMask", "TouchInspector", "DEBUGLocation",
                "Inspector", "DebugLibs", "DebugCrash", "DebugFile", "DebugColor",
                "DebugRuler", "DebugPerformance", "DebugCategory", "DebugUserDefault", "DebugNetwork"
            ],
            swiftSettings: [.define("POOTOOLS_DEBUG"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsDEBUGTrackingEyes",
            dependencies: ["ptools", "PooToolsDEBUG", "PTCameraPermission"],
            path: "PooToolsSource/WhereIsMyEye",
            swiftSettings: [.define("POOTOOLS_DEBUGTRACKINGEYES"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsLaunchTimeProfiler",
            dependencies: ["ptools"],
            path: "PooToolsSource/LaunchTimeProfiler",
            swiftSettings: [.define("POOTOOLS_LAUNCHTIMEPROFILER"), .define("POOTOOLS_COCOAPODS")]
        ),

        // English: Keep iOS-only quality targets for Core, UI, Network, list, navigation, media, and permission regression checks.
        // Español: Mantiene objetivos de calidad exclusivos de iOS para las regresiones de Core, UI, Network, listas, navegación, medios y permisos.
        // 中文：保留仅面向 iOS 的质量测试目标，覆盖 Core、UI、Network、列表、导航、媒体和权限回归。
        .testTarget(
            name: "PToolsCoreTests",
            dependencies: ["PToolsCore"],
            path: "Tests/PooToolsCoreTests"
        ),
        .testTarget(
            name: "PToolsUIFoundationTests",
            dependencies: ["ptools"],
            path: "Tests/PToolsUIFoundationTests"
        ),
        .testTarget(
            name: "PToolsNetworkTests",
            dependencies: ["PooToolsNetWork"],
            path: "Tests/PToolsNetworkTests"
        ),
        .testTarget(
            name: "PToolsListTests",
            dependencies: ["ptools"],
            path: "Tests/PToolsListTests"
        ),
        .testTarget(
            name: "PToolsNavigationTests",
            dependencies: ["ptools"],
            path: "Tests/PToolsNavigationTests"
        ),
        .testTarget(
            name: "PToolsMediaTests",
            dependencies: ["ptools"],
            path: "Tests/PToolsMediaTests"
        ),
        .testTarget(
            name: "PToolsPermissionTests",
            dependencies: ["ptools"],
            path: "Tests/PToolsPermissionTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
