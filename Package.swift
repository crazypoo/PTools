// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "PooTools",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // 核心公共库
        .library(name: "PooTools", targets: ["PooTools"]),
        // 独立功能模块（外部可按需引入）
        .library(name: "PooToolsNetWork", targets: ["PooToolsNetWork"]),
        .library(name: "PooToolsScrollRefresh", targets: ["PooToolsScrollRefresh"]),
        .library(name: "PooToolsDataEncrypt", targets: ["PooToolsDataEncrypt"]),
        .library(name: "PooToolsMediaViewer", targets: ["PooToolsMediaViewer"]),
        .library(name: "PooToolsPhotoPicker", targets: ["PooToolsPhotoPicker"]),
        .library(name: "PooToolsVideoEditor", targets: ["PooToolsVideoEditor"]),
        // 💡 提供类似 InputAll 的全量聚合包，方便老用户一键引入所有能力
        .library(name: "PooToolsAll", targets: [
            "PooTools", "PooToolsNetWork", "PooToolsScrollRefresh", "PooToolsDataEncrypt",
            "PooToolsMediaViewer", "PooToolsPhotoPicker", "PooToolsVideoEditor",
            "PooToolsCustomerLabel", "PooToolsProgressBar", "PooToolsPageControl"
            // 依据使用习惯，可在此数组中暴露更多开放 Target
        ])
    ],
    dependencies: [
        // Core 依赖
        .package(url: "https://github.com/malcommac/SwiftDate.git", from: "7.0.0"),
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.6.0"),
        .package(url: "https://github.com/SwifterSwift/SwifterSwift.git", from: "6.0.0"),
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack.git", from: "3.8.0"),
        .package(url: "https://github.com/devicekit/DeviceKit.git", from: "5.2.0"),
        .package(url: "https://github.com/indragiek/AttributedString.swift.git", branch: "master"),
        .package(url: "https://github.com/hackiftekhar/IQKeyboardManager.git", from: "7.0.0"),
        .package(url: "https://github.com/facebookarchive/pop.git", branch: "master"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.6.0"),
        .package(url: "https://github.com/sparrowcode/SafeSFSymbols.git", from: "2.0.0"),
        .package(url: "https://github.com/iAmMccc/SmartCodable.git", from: "4.0.0"),
        .package(url: "https://github.com/kakaopensource/KakaJSON.git", branch: "master"),
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.0"),
        
        // 扩展功能依赖
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/Daltron/NotificationBanner.git", from: "3.1.0"),
        .package(url: "https://github.com/CoderMJLee/MJRefresh.git", from: "3.7.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
        .package(url: "https://github.com/WorldDownTown/RangeSeekSlider.git", from: "1.8.0"),
        .package(url: "https://github.com/Kitura/Swift-JWT.git", from: "4.0.0"),
        .package(url: "https://github.com/amirdew/CollectionViewPagingLayout.git", from: "1.1.0"),
        .package(url: "https://github.com/ZipArchive/ZipArchive.git", from: "2.5.0"), // SSZipArchive
        .package(url: "https://github.com/swisspol/GCDWebServer.git", branch: "master"),
        .package(url: "https://github.com/BeauNouvelle/FaceAware.git", branch: "master"),
        .package(url: "https://github.com/pujiaxin33/JXPagingView.git", from: "2.1.0"),
        .package(url: "https://github.com/pujiaxin33/JXSegmentedView.git", from: "1.3.0"),
        .package(url: "https://github.com/borenfocus/BRPickerView.git", from: "2.7.0"),
        .package(url: "https://github.com/ephread/Instructions.git", from: "2.2.0"),
        .package(url: "https://github.com/SwiftKitz/Appz.git", branch: "master"),
        .package(url: "https://github.com/AndyM129/AMKLaunchTimeProfiler.git", branch: "master"),
        .package(url: "https://github.com/marmelroy/PhoneNumberKit.git", from: "3.7.0"),
        .package(url: "https://github.com/speechkit/OSSSpeechKit.git", from: "1.1.0"),
        .package(url: "https://github.com/securing/IOSSecuritySuite.git", from: "1.9.0"),
        .package(url: "https://github.com/yangKJ/Harbeth.git", from: "1.1.0"),
        .package(url: "https://github.com/yangKJ/Kakapos.git", branch: "master"),
        .package(url: "https://github.com/aheze/Popovers.git", from: "1.3.0"),
        .package(url: "https://github.com/pocketsvg/PocketSVG.git", from: "2.7.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", exact: "3.22.1"),
        .package(url: "https://github.com/svga/SVGAPlayer-iOS.git", branch: "master"),
        .package(url: "https://github.com/madebybowtie/FlagKit.git", branch: "master"),
        .package(url: "https://github.com/Kjuly/KTVHTTPCache.git", branch: "master"),
        .package(url: "https://github.com/facebook/SocketRocket.git", from: "0.6.0")
    ],
    targets: [
        // ==========================================
        // 核心基座模块 (Core)
        // ==========================================
        .target(
            name: "PooTools", // 命名为 PooTools 方便外部 import PooTools
            dependencies: [
                "SwiftDate",
                "SnapKit",
                "SwifterSwift",
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                "DeviceKit",
                .product(name: "AttributedString", package: "AttributedString.swift"),
                .product(name: "IQKeyboardManagerSwift", package: "IQKeyboardManager"),
                "pop",
                "Kingfisher",
                "SafeSFSymbols",
                "SmartCodable",
                "KakaJSON",
                .product(name: "Lottie", package: "lottie-ios"),
                // 无源码依赖整合进 Core 确保随库加载
                .product(name: "SSZipArchive", package: "ZipArchive"),
                "FlagKit",
                "NotificationBannerSwift",
                "Instructions",
                "Appz",
                "AMKLaunchTimeProfiler",
                "BRPickerView",
                "IOSSecuritySuite",
                "KTVHTTPCache"
            ],
            path: "PooToolsSource",
            // 💡 绝妙技巧：通过 sources 参数明确指定属于 Core 的离散文件夹，完全避免对其他 Subspec 文件夹产生侵入
            sources: [
                "Core", "Blur", "ActionsheetAndAlert", "Base", "AppStore",
                "ApplicationFunction", "BlackMagic", "Button", "Category",
                "Log", "StatusBar", "Protocol", "Animation", "PermissionCore",
                "PhotoLibraryPermission", "AppDelegate", "Foundation",
                "Language", "DarkMode", "Line", "Badge", "Rotation", "Switch",
                "Colors", "Font", "FloatPanel", "SideMenuControl", "iCloud"
            ],
            resources: [
                .process("Resource"),
                .process("Resources")
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
                .define("POOTOOLS_VIDEOCACHE")
            ]
        ),

        // ==========================================
        // 基础 UI 与细分组件模块
        // ==========================================
        .target(
            name: "PooToolsCustomerLabel",
            dependencies: ["PooTools"],
            path: "PooToolsSource/Label",
            swiftSettings: [.define("POOTOOLS_CUSTOMERLABEL"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsProgressBar",
            dependencies: ["PooTools"],
            path: "PooToolsSource/ProgressBar",
            swiftSettings: [.define("POOTOOLS_PROGRESSBAR"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsPageControl",
            dependencies: ["PooTools"],
            path: "PooToolsSource/PageControl",
            swiftSettings: [.define("POOTOOLS_PAGECONTROL"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsLoading",
            dependencies: ["PooTools"],
            path: "PooToolsSource/Loading",
            swiftSettings: [.define("POOTOOLS_LOADING"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsHud",
            dependencies: ["PooTools", "PooToolsProgressBar"],
            path: "PooToolsSource/Hud",
            swiftSettings: [.define("POOTOOLS_HUD"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsLivePhoto",
            dependencies: ["PooTools"],
            path: "PooToolsSource/LivePhoto",
            swiftSettings: [.define("POOTOOLS_LIVEPHOTO"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsShare",
            dependencies: ["PooToolsCustomerLabel"],
            path: "PooToolsSource/Share",
            swiftSettings: [.define("POOTOOLS_SHARE"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsPDF",
            dependencies: ["PooTools"],
            path: "PooToolsSource/PDF",
            swiftSettings: [.define("POOTOOLS_PDF"), .define("POOTOOLS_COCOAPODS")]
        ),

        // ==========================================
        // 权限模块 (Permissions)
        // ==========================================
        .target(name: "PTCameraPermission", dependencies: ["PooTools"], path: "PooToolsSource/CameraPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_CAMERA"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTLocationPermission", dependencies: ["PooTools"], path: "PooToolsSource/LocationPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_LOCATION"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTCalendarPermission", dependencies: ["PooTools"], path: "PooToolsSource/CalendarPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_CALENDAR"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTMotionPermission", dependencies: ["PooTools"], path: "PooToolsSource/MotionPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_MOTION"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTTrackingPermission", dependencies: ["PooTools"], path: "PooToolsSource/TrackingPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_TRACKING"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTRemindersPermission", dependencies: ["PooTools"], path: "PooToolsSource/RemindersPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_REMINDERS"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTSpeechPermission", dependencies: ["PooTools"], path: "PooToolsSource/SpeechPremission", swiftSettings: [.define("POOTOOLS_PERMISSION_SPEECH"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTHealthPermission", dependencies: ["PooTools"], path: "PooToolsSource/HealthPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_HEALTH"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTFaceIDPermission", dependencies: ["PooTools"], path: "PooToolsSource/FaceIDPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_FACEIDPERMISSION"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTContactsPermission", dependencies: ["PooTools"], path: "PooToolsSource/ContactsPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_CONTACTS"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTMicPermission", dependencies: ["PooTools"], path: "PooToolsSource/MicPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_MIC"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTMediaPermission", dependencies: ["PooTools"], path: "PooToolsSource/MeidaLibraryPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_MEDIA"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTBluetoothPermission", dependencies: ["PooTools"], path: "PooToolsSource/BluetoothPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_BLUETOOTH"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTSiriPermission", dependencies: ["PooTools"], path: "PooToolsSource/SiriPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_SIRI"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PTNotificationPermission", dependencies: ["PooTools"], path: "PooToolsSource/NotificationPermission", swiftSettings: [.define("POOTOOLS_PERMISSION_NOTIFICATION"), .define("POOTOOLS_COCOAPODS")]),

        // ==========================================
        // 核心中上层依赖模块
        // ==========================================
        .target(
            name: "PooToolsNetWork",
            dependencies: ["PooTools", "PooToolsLoading", "Alamofire"],
            path: "PooToolsSource/NetWork",
            swiftSettings: [.define("POOTOOLS_NETWORK"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsScrollRefresh",
            dependencies: ["PooTools", "MJRefresh"],
            path: "PooToolsSource/ScrollRefresh",
            swiftSettings: [.define("POOTOOLS_SCROLLREFRESH"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsDataEncrypt",
            dependencies: ["PooTools", "CryptoSwift"],
            path: "PooToolsSource/AESAndDES",
            swiftSettings: [.define("POOTOOLS_DATAENCRYPT"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsSearchBar",
            dependencies: ["PooTools"],
            path: "PooToolsSource/SearchBar",
            swiftSettings: [.define("POOTOOLS_SEARCHBAR"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsMediaViewer",
            dependencies: ["PooTools", "PooToolsProgressBar", "PooToolsNetWork", "PooToolsPageControl", "PooToolsLivePhoto"],
            path: "PooToolsSource/MediaViewer",
            swiftSettings: [.define("POOTOOLS_MEDIAVIEWER"), .define("POOTOOLS_COCOAPODS")]
        ),

        // ==========================================
        // 高级业务模块
        // ==========================================
        .target(
            name: "PooToolsPhotoPicker",
            dependencies: ["PooTools", "PTCameraPermission", "PooToolsNetWork", "PooToolsLoading", "Kakapos"],
            path: "PooToolsSource",
            sources: ["PhotoPicker", "ImagePicker"], // 精准圈定两个独立目录
            swiftSettings: [.define("POOTOOLS_PHOTOPICKER"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsHarbethKit",
            dependencies: ["PooTools", "Harbeth", "PTCameraPermission"],
            path: "PooToolsSource/C7Collector",
            swiftSettings: [.define("POOTOOLS_HARBETHKIT"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsFilterCamera",
            dependencies: ["PooTools", "PTCameraPermission", "PTMicPermission", "PooToolsHarbethKit", "PooToolsMediaViewer"],
            path: "PooToolsSource/FilterCamera",
            swiftSettings: [.define("POOTOOLS_FILTERCAMERA"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsImageEditor",
            dependencies: ["PooTools", "PooToolsFilterCamera"],
            path: "PooToolsSource/ImageEditor",
            swiftSettings: [.define("POOTOOLS_IMAGEEDITOR"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsVideoEditor",
            dependencies: ["PooTools", "PooToolsHarbethKit", "PooToolsProgressBar", "PooToolsLoading"],
            path: "PooToolsSource/VideoEditor",
            swiftSettings: [.define("POOTOOLS_VIDEOEDITOR"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsSVG",
            dependencies: ["PooTools", "PocketSVG", .product(name: "SwiftProtobuf", package: "swift-protobuf"), "SVGAPlayer"],
            path: "PooToolsSource/KingfisherSVG",
            swiftSettings: [.define("POOTOOLS_SVG"), .define("POOTOOLS_COCOAPODS")]
        ),
        .target(
            name: "PooToolsCheckDirtyWord",
            dependencies: ["PooTools"],
            path: "PooToolsSource/CheckDirtyWord",
            resources: [.process("Resource")],
            swiftSettings: [.define("POOTOOLS_CHECKDIRTYWORD"), .define("POOTOOLS_COCOAPODS")]
        ),

        // ==========================================
        // 其他基础功能 Target 映射
        // ==========================================
        .target(name: "PooToolsStepper", dependencies: ["PooTools"], path: "PooToolsSource/Stepper", swiftSettings: [.define("POOTOOLS_STEPPER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsBankCard", dependencies: ["PooTools"], path: "PooToolsSource/BankCard", swiftSettings: [.define("POOTOOLS_BANKCARD"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsBioID", dependencies: ["PooTools", "PTFaceIDPermission"], path: "PooToolsSource/BioID", swiftSettings: [.define("POOTOOLS_BILOGYID"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCalendar", dependencies: ["PooTools", "PTCalendarPermission", "PTRemindersPermission"], path: "PooToolsSource/Calendar", swiftSettings: [.define("POOTOOLS_CALENDAR"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsTelephony", dependencies: ["PooTools"], path: "PooToolsSource/CallMessageMail", swiftSettings: [.define("POOTOOLS_TELEPHONY"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCheckBox", dependencies: ["PooTools"], path: "PooToolsSource/CheckBox", swiftSettings: [.define("POOTOOLS_CHECKBOX"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCodeView", dependencies: ["PooTools"], path: "PooToolsSource/CodeView", swiftSettings: [.define("POOTOOLS_CODEVIEW"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCountry", dependencies: ["PooTools"], path: "PooToolsSource/Country", swiftSettings: [.define("POOTOOLS_COUNTRY"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsGuide", dependencies: ["PooTools", "PooToolsPageControl"], path: "PooToolsSource/Guide", swiftSettings: [.define("POOTOOLS_GUIDE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsInput", dependencies: ["PooTools", "PhoneNumberKit"], path: "PooToolsSource/Input", swiftSettings: [.define("POOTOOLS_INPUT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsKeyboard", dependencies: ["PooTools"], path: "PooToolsSource/Keyboard", swiftSettings: [.define("POOTOOLS_CUSTOMERNUMBERKEYWORD"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsKeyChain", dependencies: ["PooTools"], path: "PooToolsSource/KeyChain", swiftSettings: [.define("POOTOOLS_KEYCHAIN"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsMotion", dependencies: ["PooTools", "PTMotionPermission"], path: "PooToolsSource/Motion", swiftSettings: [.define("POOTOOLS_MOTION"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPhoneInfo", dependencies: ["PooTools"], path: "PooToolsSource/PhoneInfo", swiftSettings: [.define("POOTOOLS_PHONEINFO"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsRateView", dependencies: ["PooTools"], path: "PooToolsSource/RateView", swiftSettings: [.define("POOTOOLS_RATE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsScrollBanner", dependencies: ["PooTools", "PooToolsPageControl"], path: "PooToolsSource/ScrollBanner", swiftSettings: [.define("POOTOOLS_SCROLLBANNER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSegmented", dependencies: ["PooTools"], path: "PooToolsSource/Segmented", swiftSettings: [.define("POOTOOLS_SEGMENT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsHandSign", dependencies: ["PooTools"], path: "PooToolsSource/SignView", swiftSettings: [.define("POOTOOLS_HANDSIGN"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSlider", dependencies: ["PooTools", "RangeSeekSlider"], path: "PooToolsSource/Slider", swiftSettings: [.define("POOTOOLS_SLIDER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCheckUpdate", dependencies: ["PooToolsNetWork", "SwiftJWT"], path: "PooToolsSource/CheckUpdate", swiftSettings: [.define("POOTOOLS_CHECKUPDATE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsLayout", dependencies: ["PooTools", "CollectionViewPagingLayout"], path: "PooToolsSource/Layout", swiftSettings: [.define("POOTOOLS_LAYOUT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsLocation", dependencies: ["PooTools", "PTLocationPermission"], path: "PooToolsSource/Location", swiftSettings: [.define("POOTOOLS_LOCATION"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSmartScreenshot", dependencies: ["PooTools"], path: "PooToolsSource/ScreenShot", swiftSettings: [.define("POOTOOLS_SMARTSCREENSHOT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPagingControl", dependencies: ["PooTools", .product(name: "JXPagingView", package: "JXPagingView"), "JXSegmentedView"], path: "PooToolsSource/SegmentControl", swiftSettings: [.define("POOTOOLS_PAGINGCONTROL"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsScanQRCode", dependencies: ["PooTools", "PooToolsPhotoPicker", "PTCameraPermission"], path: "PooToolsSource/QRCodeScan", swiftSettings: [.define("POOTOOLS_SCANQRCODE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsStepCount", dependencies: ["PooTools", "PTHealthPermission"], path: "PooToolsSource/HealthKit", swiftSettings: [.define("POOTOOLS_STEPCOUNT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSpeech", dependencies: ["PooTools", "PTSpeechPermission", "OSSSpeechKit"], path: "PooToolsSource/Speech", swiftSettings: [.define("POOTOOLS_SPEECH"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsContact", dependencies: ["PooTools", "PTContactsPermission"], path: "PooToolsSource/Contact", swiftSettings: [.define("POOTOOLS_CONTACT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPopoverKit", dependencies: ["PooTools", "Popovers"], path: "PooToolsSource/PopoverKit", swiftSettings: [.define("POOTOOLS_POPOVERKIT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsVision", dependencies: ["PooTools"], path: "PooToolsSource/Vision", swiftSettings: [.define("POOTOOLS_VISION"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsRouter", dependencies: ["PooTools"], path: "PooToolsSource/Router", swiftSettings: [.define("POOTOOLS_ROUTER"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsPing", dependencies: ["PooTools"], path: "PooToolsSource/Ping", swiftSettings: [.define("POOTOOLS_PING"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSpeedPanel", dependencies: ["PooTools"], path: "PooToolsSource/SpeedPanel", swiftSettings: [.define("POOTOOLS_SPEEDPANEL"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsNetworkSpeedTest", dependencies: ["PooTools"], path: "PooToolsSource/NetworkSpeedTest", swiftSettings: [.define("POOTOOLS_NETWORKSPEEDTEST"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsOSSKitSpeech", dependencies: ["PooTools", "PTSpeechPermission"], path: "PooToolsSource/OSSKit", swiftSettings: [.define("POOTOOLS_OSSKITSPEECH"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsiOS17Tips", dependencies: ["PooTools"], path: "PooToolsSource/iOS17Tips", swiftSettings: [.define("POOTOOLS_iOS17TIPS"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsWhatsNewsKit", dependencies: ["PooTools"], path: "PooToolsSource/WhatsNewsKit", swiftSettings: [.define("POOTOOLS_WHATSNEWSKIT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsHeartRate", dependencies: ["PooTools", .product(name: "Lottie", package: "lottie-ios"), "PTCameraPermission"], path: "PooToolsSource/HeartRate", swiftSettings: [.define("POOTOOLS_HEARTRATE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsChinesePinyin", dependencies: ["PooTools"], path: "PooToolsSource/Pinyin", swiftSettings: [.define("POOTOOLS_CHINESEPINYIN"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsCircle", dependencies: ["PooTools"], path: "PooToolsSource/Circle", swiftSettings: [.define("POOTOOLS_CIRCLE"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsMessageKit", dependencies: ["PooTools", "PooToolsCustomerLabel"], path: "PooToolsSource/MessageKit", swiftSettings: [.define("POOTOOLS_MESSAGEKIT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsSocketKit", dependencies: ["PooTools", "SocketRocket"], path: "PooToolsSource/SocketKit", swiftSettings: [.define("POOTOOLS_SOCKETKIT"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsIAP", dependencies: ["PooTools"], path: "PooToolsSource/IAP", swiftSettings: [.define("POOTOOLS_IAP"), .define("POOTOOLS_COCOAPODS")]),
        .target(name: "PooToolsTipsView", dependencies: ["PooTools"], path: "PooToolsSource/TipsView", swiftSettings: [.define("POOTOOLS_TIPSVIEW"), .define("POOTOOLS_COCOAPODS")]),

        // ==========================================
        // 调试工具模块 (DEBUG)
        // ==========================================
        .target(
            name: "PooToolsDEBUG",
            dependencies: ["PooTools", "PooToolsNetWork", "PooToolsShare", "PooToolsSearchBar", "PooToolsPDF"],
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
            dependencies: ["PooTools", "PooToolsDEBUG", "PTCameraPermission"],
            path: "PooToolsSource/WhereIsMyEye",
            swiftSettings: [.define("POOTOOLS_DEBUGTRACKINGEYES"), .define("POOTOOLS_COCOAPODS")]
        )
    ]
)
