// English: Stable metadata and routing primitives for the Example Demo Catalog 2.0.
// Español: Primitivas estables de metadatos y rutas para el catálogo Demo 2.0 del Example.
// 中文：Example Demo Catalog 2.0 的稳定元数据与路由基础类型。

import UIKit
import PooTools
import SnapKit

enum PTDemoKind: String, Codable, Hashable, Sendable {
    case interactive
    case scenario
    case action
    case documentation
    case hostRequired
    case extensionRequired
    case compatibilityAlias
}

enum PTDemoAvailability: String, Codable, Hashable, Sendable {
    case runnable
    case simulatorLimited
    case physicalDeviceRequired
    case entitlementRequired
    case hostRequired
    case extensionRequired
    case unavailable
    case compatibilityAlias
}

enum PTDemoRequirement: String, Codable, Hashable, Sendable {
    case camera
    case microphone
    case photoLibrary
    case bluetooth
    case location
    case health
    case nfc
    case biometrics
    case physicalDevice
    case appExtension
    case entitlement
}

enum PTDemoPresentation: String, Codable, Hashable, Sendable {
    case push
    case sheet
    case fullScreen
    case rootContainer
    case inline
    case action
}

enum PTDemoCategory: String, Codable, Hashable, Sendable, CaseIterable {
    case coreFoundation = "core-foundation"
    case uiComponents = "ui-components"
    case inputForm = "input-form"
    case navigationRouting = "navigation-routing"
    case mediaGraphics = "media-graphics"
    case networkConnectivity = "network-connectivity"
    case permissionsDevice = "permissions-device"
    case storageData = "storage-data"
    case securityPrivacy = "security-privacy"
    case themeAccessibility = "theme-accessibility"
    case debugDiagnostics = "debug-diagnostics"
    case modernSystem = "modern-system"
    case compatibility = "compatibility"

    var displayTitle: String {
        switch self {
        case .coreFoundation: return "Core & Foundation"
        case .uiComponents: return "UI Components"
        case .inputForm: return "Input & Form"
        case .navigationRouting: return "Navigation & Routing"
        case .mediaGraphics: return "Media & Graphics"
        case .networkConnectivity: return "Network & Connectivity"
        case .permissionsDevice: return "Permissions & Device"
        case .storageData: return "Storage & Data"
        case .securityPrivacy: return "Security & Privacy"
        case .themeAccessibility: return "Theme & Accessibility"
        case .debugDiagnostics: return "Debug & Diagnostics"
        case .modernSystem: return "Modern System"
        case .compatibility: return "Compatibility"
        }
    }
}

struct PTDemoID: Hashable, Codable, Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

typealias PTDemoRouteID = String

struct PTDemoDescriptor: Hashable, Codable, Sendable {
    let id: PTDemoID
    let moduleID: String
    let titleKey: String
    let subtitleKey: String?
    let category: PTDemoCategory
    let kind: PTDemoKind
    let tags: [String]
    let presentation: PTDemoPresentation
    let availability: PTDemoAvailability
    let requirements: [PTDemoRequirement]
    let routeID: PTDemoRouteID?
    let legacyRoute: String?
}

struct PTDemoSection: Sendable {
    let id: String
    let title: String
    let demos: [PTDemoDescriptor]
}

enum PTDemoRegistry {
    // English: The descriptor list is the only Example identity source; UI text is not used as an identity.
    // Español: La lista de descriptores es la única fuente de identidad; la UI no se usa como identidad.
    // 中文：描述符列表是 Example 唯一的身份来源，UI 文本不再承担身份职责。
    static let descriptors: [PTDemoDescriptor] = [
        make("network.local-network", "PToolsHTTPFilePortal", "局域网传送", .networkConnectivity, .scenario, .sheet, .runnable, legacy: "局域网传送", tags: ["network", "http", "local"]),
        make("network.ptmodel-lab", "PooToolsNetwork", "PTModel + Typed Network", .networkConnectivity, .interactive, .push, .runnable, legacy: "PTModel + Typed Network", tags: ["network", "ptmodel", "nested-json", "model-path"]),
        make("media.image-review", "PooToolsMediaViewer", "图片展示", .mediaGraphics, .interactive, .fullScreen, .runnable, legacy: "图片展示", tags: ["image", "gif", "video"]),
        make("media.image-clarity", "PooToolsCore", "Image Loading Clarity", .mediaGraphics, .interactive, .push, .runnable, tags: ["image", "placeholder", "downsampling", "scale"]),
        make("ui.rich-text-attachment-multiline", "PToolsUIFoundation", "Rich Text · Attachment Multiline Regression", .uiComponents, .interactive, .push, .runnable, tags: ["rich-text", "attachment", "multiline", "baseline", "action"]),
        make("ui.rich-text-fragment-line-limit", "PToolsUIFoundation", "Rich Text · Fragment Line Limit Lab", .uiComponents, .interactive, .push, .runnable, tags: ["rich-text", "fragment", "line-limit", "truncation", "action", "attachment"]),
        make("media.video-editor", "PooToolsVideoEditor", "视频编辑", .mediaGraphics, .hostRequired, .fullScreen, .physicalDeviceRequired, [.photoLibrary, .physicalDevice], legacy: "视频编辑", tags: ["video", "export"]),
        make("media.signature", "PooToolsHandSign", "签名", .mediaGraphics, .interactive, .sheet, .runnable, legacy: "签名", tags: ["drawing"]),
        make("media.dynamic-code", "PooToolsCodeView", "动态验证码", .mediaGraphics, .interactive, .sheet, .runnable, legacy: "动态验证码", tags: ["code"]),
        make("audio.speech", "PToolsAudio", "语音", .mediaGraphics, .hostRequired, .push, .physicalDeviceRequired, [.microphone, .physicalDevice], legacy: "语音", tags: ["audio", "speech"]),
        make("media.vision", "PooToolsVision", "看图识字", .mediaGraphics, .hostRequired, .sheet, .physicalDeviceRequired, [.photoLibrary], legacy: "看图识字", tags: ["vision", "ocr"]),
        make("media.photo-picker", "PooToolsPhotoPicker", "媒體選擇", .mediaGraphics, .hostRequired, .fullScreen, .runnable, [.photoLibrary], legacy: "媒體選擇", tags: ["photo", "picker"]),
        make("device.phone-info", "PooToolsPhoneInfo", "手机信息", .permissionsDevice, .documentation, .inline, .runnable, legacy: "手机信息", tags: ["device"]),
        make("device.phone-call", "PooToolsTelephony", "打电话", .permissionsDevice, .action, .action, .simulatorLimited, legacy: "打电话", tags: ["telephony"]),
        make("storage.clear-cache", "PToolsStorage", "清理缓存", .storageData, .action, .action, .runnable, legacy: "清理缓存", tags: ["cache"]),
        make("security.biometrics", "PooToolsBioID", "TouchID", .securityPrivacy, .interactive, .action, .physicalDeviceRequired, [.biometrics, .physicalDevice], legacy: "TouchID", tags: ["biometric"]),
        make("security.acknowledgements", "PToolsAcknowledgements", "开源许可证", .securityPrivacy, .interactive, .push, .runnable, tags: ["license", "offline", "spm", "cocoapods"]),
        make("security.acknowledgements-headless", "PToolsAcknowledgementsCore", "许可证纯数据", .securityPrivacy, .interactive, .push, .runnable, tags: ["license", "headless", "query", "export"]),
        make("device.rotation", "PooToolsRotation", "旋转屏幕", .permissionsDevice, .action, .action, .simulatorLimited, legacy: "旋转屏幕", tags: ["orientation"]),
        make("ui.share", "PooToolsShare", "分享", .uiComponents, .interactive, .sheet, .runnable, legacy: "分享", tags: ["share"]),
        make("network.check-update", "PooToolsCheckUpdate", "检测更新", .networkConnectivity, .scenario, .sheet, .runnable, legacy: "检测更新", tags: ["update"]),
        make("theme.language", "PToolsCore", "語言", .themeAccessibility, .action, .action, .runnable, legacy: "語言", tags: ["language", "localization"]),
        make("theme.dark-mode", "PToolsTheme", "DarkMode", .themeAccessibility, .interactive, .push, .runnable, legacy: "DarkMode", tags: ["theme"]),
        make("ui.slider", "PooToolsSlider", "滑动条", .uiComponents, .interactive, .sheet, .runnable, legacy: "滑动条", tags: ["control"]),
        make("ui.rate", "PooToolsRateView", "评价星星", .uiComponents, .interactive, .sheet, .runnable, legacy: "评价星星", tags: ["control"]),
        make("navigation.segment", "PooToolsSegmented", "分选栏目", .navigationRouting, .interactive, .sheet, .runnable, legacy: "分选栏目", tags: ["segment"]),
        make("ui.count-label", "PToolsUIFoundation", "跳动Label", .uiComponents, .interactive, .sheet, .runnable, legacy: "跳动Label", tags: ["label"]),
        make("ui.through-label", "PToolsUIFoundation", "划线Label", .uiComponents, .interactive, .sheet, .runnable, legacy: "划线Label", tags: ["label"]),
        make("ui.twitter-label", "PToolsUIFoundation", "推文Label", .uiComponents, .interactive, .sheet, .runnable, legacy: "推文Label", tags: ["label"]),
        make("ui.movie-cut-output", "PooToolsProgressBar", "类似剪映的视频输出进度效果", .uiComponents, .interactive, .sheet, .runnable, legacy: "类似剪映的视频输出进度效果", tags: ["progress"]),
        make("ui.progress-bar", "PooToolsProgressBar", "进度条", .uiComponents, .interactive, .sheet, .runnable, legacy: "进度条", tags: ["progress"]),
        make("ui.alert", "PooToolsBanner", "Alert", .uiComponents, .interactive, .sheet, .runnable, legacy: "Alert", tags: ["alert", "action-sheet"]),
        make("ui.tabbar-insets", "PToolsUIFoundation", "TabBar Item Insets", .uiComponents, .interactive, .push, .runnable, legacy: "TabBar Item Insets", tags: ["tabbar", "selection", "insets", "offset"]),
        make("ui.gradient-rendering", "PToolsUIFoundation", "Gradient Rendering", .uiComponents, .interactive, .push, .runnable, legacy: "Gradient Rendering", tags: ["gradient", "label", "image-view"]),
        make("ui.control-menu", "PooToolsCore", "UIControl Menu", .uiComponents, .interactive, .push, .runnable, legacy: "UIControl Menu", tags: ["menu", "uicontrol", "selection", "swift6"]),
        make("ui.menu", "PToolsUIFoundation", "Menu", .uiComponents, .interactive, .sheet, .runnable, legacy: "Menu", tags: ["menu"]),
        make("ui.loading", "PooToolsLoading", "Loading", .uiComponents, .interactive, .sheet, .runnable, legacy: "Loading", tags: ["loading"]),
        make("permissions.overview", "PToolsPermissionUI", "Permission", .permissionsDevice, .hostRequired, .push, .runnable, legacy: "Permission", tags: ["permission"]),
        make("permissions.settings", "PToolsPermissionUI", "Permission Setting", .permissionsDevice, .hostRequired, .push, .runnable, legacy: "Permission Setting", tags: ["permission", "settings"]),
        make("modern.tipkit", "PooToolsiOS17Tips", "TipKit", .modernSystem, .hostRequired, .push, .runnable, legacy: "TipKit", tags: ["ios17"]),
        make("documents.uidocument", "PToolsDocuments", "UIDocument", .storageData, .interactive, .push, .runnable, legacy: "UIDocument", tags: ["document"]),
        make("ui.svga", "PooToolsSVG", "SVGA", .mediaGraphics, .documentation, .sheet, .runnable, legacy: "SVGA", tags: ["animation"]),
        make("ui.swipe", "PToolsUIFoundation", "Swipe", .uiComponents, .interactive, .sheet, .runnable, legacy: "Swipe", tags: ["gesture"]),
        make("device.scan-qr", "PooToolsScanQRCode", "ScanQRCode", .permissionsDevice, .hostRequired, .fullScreen, .physicalDeviceRequired, [.camera, .physicalDevice], legacy: "ScanQRCode", tags: ["camera", "qr"]),
        make("media.filter-camera", "PooToolsHarbethKit", "FilterCamera", .mediaGraphics, .hostRequired, .fullScreen, .physicalDeviceRequired, [.camera, .physicalDevice], legacy: "FilterCamera", tags: ["camera", "filter"]),
        make("media.image-editor", "PooToolsImageEditor", "EditImage", .mediaGraphics, .hostRequired, .fullScreen, .runnable, [.photoLibrary], legacy: "EditImage", tags: ["image", "editor"]),
        make("ui.sort-button", "PToolsUIFoundation", "SortButton", .uiComponents, .interactive, .sheet, .runnable, legacy: "SortButton", tags: ["button"]),
        make("ui.message-kit", "PooToolsMessageKit", "MessageKit", .uiComponents, .hostRequired, .push, .runnable, legacy: "MessageKit", tags: ["chat"]),
        make("media.blur-image-list", "PooToolsMediaViewer", "BlurImageList", .mediaGraphics, .interactive, .push, .runnable, legacy: "BlurImageList", tags: ["image", "blur"]),
        make("ui.cycle-banner", "PooToolsScrollBanner", "CycleBanner", .uiComponents, .interactive, .sheet, .runnable, legacy: "CycleBanner", tags: ["banner"]),
        make("ui.collection-tag", "PToolsForm", "CollectionTag", .inputForm, .interactive, .sheet, .runnable, legacy: "CollectionTag", tags: ["collection", "tag"]),
        make("ui.collection-refresh-lab", "PToolsUIFoundation", "Diffable Refresh Lab", .uiComponents, .interactive, .push, .runnable, legacy: "Diffable Refresh Lab", tags: ["collection", "diffable", "content-refresh", "stress"]),
        make("ui.collection-layout-switch-lab", "PToolsUIFoundation", "Collection Layout Switch Lab", .uiComponents, .interactive, .push, .runnable, legacy: "Collection Layout Switch Lab", tags: ["collection", "layout", "runtime-switch", "stress"]),
        make("ui.collection-skeleton-lab", "PToolsUIFoundation", "Collection Skeleton Lab", .uiComponents, .interactive, .push, .runnable, legacy: "Collection Skeleton Lab", tags: ["collection", "skeleton", "loading", "diffable"]),
        make("ui.layout.snapkit-compatibility", "PToolsConstraintLayout", "PTLayout · SnapKit Compatibility", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "snapkit", "compatibility"]),
        make("ui.layout.missing-superview-no-crash", "PToolsConstraintLayout", "PTLayout · Missing Superview", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "crash-safe", "PTL001"]),
        make("ui.layout.size-only-without-parent", "PToolsConstraintLayout", "PTLayout · Standalone Size", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "size", "standalone"]),
        make("ui.layout.cross-tree-error", "PToolsConstraintLayout", "PTLayout · Cross Tree Error", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "diagnostics", "PTL002"]),
        make("ui.layout.safe-remake", "PToolsConstraintLayout", "PTLayout · Safe Remake", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "remake", "rollback"]),
        make("ui.layout.update-mismatch", "PToolsConstraintLayout", "PTLayout · Update Mismatch", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "update", "signature"]),
        make("ui.layout.safe-area-keyboard-rtl", "PToolsConstraintLayout", "PTLayout · Safe Area / Keyboard / RTL", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "safe-area", "keyboard", "rtl"]),
        make("ui.layout.profile-compare", "PToolsConstraintLayout", "PTLayout · Profile", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "performance", "profile"]),
        make("ui.layout.duo-adaptation", "PToolsConstraintLayout", "PTLayout · Duo Adaptation", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "iphone-duo", "safe-area"]),
        make("ui.layout.lifecycle-reuse", "PToolsConstraintLayout", "PTLayout · Lifecycle / Reuse", .uiComponents, .interactive, .push, .runnable, tags: ["layout", "lifecycle", "reuse"]),
        make("input.input-box", "PooToolsInput", "InputBox", .inputForm, .interactive, .sheet, .runnable, legacy: "InputBox", tags: ["input"]),
        make("input.all-styles", "PooToolsInput", "Input Styles", .inputForm, .interactive, .push, .runnable, legacy: "Input Styles", tags: ["input", "text-field", "text-view", "styles"]),
        make("input.stepper", "PooToolsStepper", "Stepper", .inputForm, .interactive, .sheet, .runnable, legacy: "Stepper", tags: ["input"]),
        make("input.login-description", "PooToolsCustomerLabel", "LoginDesc", .inputForm, .interactive, .sheet, .runnable, legacy: "LoginDesc", tags: ["button", "rich-text"]),
        make("input.stepper-list", "PooToolsStepper", "StepperList", .inputForm, .interactive, .sheet, .runnable, legacy: "StepperList", tags: ["input", "list"]),
        make("media.live-photo", "PooToolsLivePhoto", "LivePhoto", .mediaGraphics, .hostRequired, .sheet, .runnable, [.photoLibrary], legacy: "LivePhoto", tags: ["photo", "live-photo"]),
        make("media.live-photo-disassemble", "PooToolsLivePhoto", "LivePhotoDisassemble", .mediaGraphics, .hostRequired, .sheet, .runnable, [.photoLibrary], legacy: "LivePhotoDisassemble", tags: ["photo", "live-photo"]),
        make("navigation.route", "PooToolsRouter", "路由", .navigationRouting, .interactive, .sheet, .runnable, legacy: "路由", tags: ["route"]),
        make("navigation.split-view", "PooToolsSplitView", "Adaptive SplitView — iPhone / iPad", .navigationRouting, .interactive, .rootContainer, .runnable, legacy: "AdaptiveSplitView", tags: ["split-view", "iphone", "ipad", "compact", "regular", "adaptive", "router", "state-restoration", "inspector"]),
        make("navigation.segment-paging-regression", "PooToolsSegmented", "Segmented / JX Parity & Paging", .navigationRouting, .interactive, .push, .runnable, legacy: "SegmentedPagingRegression", tags: ["segment", "paging", "badge", "jx-parity", "regression"]),
        make("navigation.segment-item-separator", "PooToolsSegmented", "Segmented / Item Separator", .navigationRouting, .interactive, .push, .runnable, legacy: "SegmentedItemSeparator", tags: ["segment", "separator", "rtl", "reuse"]),
        make("navigation.duo-adaptive-bars", "PToolsUIFoundation", "iPhone Duo Adaptive Bars", .navigationRouting, .interactive, .push, .runnable, legacy: "iPhone Duo Adaptive Bars", tags: ["iphone-duo", "navigation", "tabbar", "adaptive", "iOS27.1"]),
        // English: Keep each Duo regression surface directly discoverable in the normal catalog.
        // Español: Mantiene cada superficie de regresión Duo accesible desde el catálogo normal.
        // 中文：让每个 Duo 回归场景都能从常规目录直接进入。
        make("duo.photo-picker-grid", "PooToolsPhotoPicker", "Duo · PhotoPicker Adaptive Grid", .mediaGraphics, .interactive, .fullScreen, .runnable, [.photoLibrary], legacy: "媒體選擇", tags: ["iphone-duo", "photo-picker", "grid"]),
        make("duo.image-editor-controls", "PooToolsImageEditor", "Duo · ImageEditor Safe Controls", .mediaGraphics, .interactive, .fullScreen, .runnable, [.photoLibrary], legacy: "EditImage", tags: ["iphone-duo", "image-editor", "safe-area"]),
        make("duo.video-editor-controls", "PooToolsVideoEditor", "Duo · VideoEditor Timeline Safe Controls", .mediaGraphics, .hostRequired, .fullScreen, .physicalDeviceRequired, [.photoLibrary, .physicalDevice], legacy: "视频编辑", tags: ["iphone-duo", "video-editor", "timeline"]),
        make("duo.media-viewer-paging", "PooToolsMediaViewer", "Duo · MediaViewer Paging Integrity", .mediaGraphics, .interactive, .fullScreen, .runnable, legacy: "图片展示", tags: ["iphone-duo", "media-viewer", "paging"]),
        make("duo.media-viewer-bottom", "PooToolsMediaViewer", "Duo · MediaViewer Bottom Controls", .mediaGraphics, .interactive, .fullScreen, .runnable, legacy: "图片展示", tags: ["iphone-duo", "media-viewer", "bottom-controls"]),
        make("duo.message-kit-chat", "PooToolsMessageKit", "Duo · MessageKit Safe Chat", .uiComponents, .hostRequired, .push, .runnable, legacy: "MessageKit", tags: ["iphone-duo", "message-kit", "chat"]),
        make("duo.large-title-navigation", "PToolsUIFoundation", "Duo · LargeTitle Nav Ownership", .navigationRouting, .interactive, .push, .runnable, legacy: "MessageKit", tags: ["iphone-duo", "navigation", "large-title"]),
        make("duo.tab-accessory-search", "PToolsUIFoundation", "Duo · Tab Accessory Search", .navigationRouting, .interactive, .push, .runnable, legacy: "iPhone Duo Adaptive Bars", tags: ["iphone-duo", "tabbar", "accessory"]),
        make("duo.paging-segmented", "PooToolsSegmented", "Duo · Paging + Segmented + Nested Scroll", .navigationRouting, .interactive, .push, .runnable, legacy: "SegmentedPagingRegression", tags: ["iphone-duo", "paging", "segmented", "nested-scroll"]),
        make("duo.unified-collision-stress", "PToolsUIFoundation", "Duo · Unified Region Collision Stress", .navigationRouting, .interactive, .push, .runnable, legacy: "iPhone Duo Adaptive Bars", tags: ["iphone-duo", "collision", "reserved-region", "stress"]),
        make("duo.alert-action-sheet", "PToolsUIFoundation", "Duo · Alert / ActionSheet", .uiComponents, .interactive, .push, .runnable, tags: ["iphone-duo", "alert", "action-sheet", "dynamic-type"]),
        make("duo.overlay-popover-banner", "PToolsOverlay", "Duo · Overlay / Popover / Banner", .uiComponents, .interactive, .push, .runnable, tags: ["iphone-duo", "overlay", "popover", "banner"]),
        make("duo.form-keyboard-search", "PToolsForm", "Duo · Form / Keyboard / Search", .inputForm, .interactive, .push, .runnable, tags: ["iphone-duo", "form", "keyboard", "search"]),
        make("duo.collection-all-layouts", "PToolsUIFoundation", "Duo · Collection All Layouts", .uiComponents, .interactive, .push, .runnable, tags: ["iphone-duo", "collection", "layouts", "runtime-switch"]),
        make("duo.split-page-container", "PooToolsSplitView", "Duo · Split Page Container", .navigationRouting, .interactive, .push, .runnable, tags: ["iphone-duo", "split-view", "page-container"]),
        make("duo.picker-permission-system", "PooToolsPhotoPicker", "Duo · Picker / Permission / System", .permissionsDevice, .interactive, .push, .runnable, [.photoLibrary], tags: ["iphone-duo", "picker", "permission", "system"]),
        make("duo.debug-overlay-guide", "PooToolsDEBUG", "Duo · Debug Overlay / Guide", .debugDiagnostics, .interactive, .push, .runnable, tags: ["iphone-duo", "debug", "overlay", "guide"]),
        make("duo.rtl-dynamic-type", "PToolsUIFoundation", "Duo · RTL / Dynamic Type", .themeAccessibility, .interactive, .push, .runnable, tags: ["iphone-duo", "rtl", "dynamic-type", "voiceover"]),
        make("security.encryption", "PooToolsDataEncrypt", "Encryption", .securityPrivacy, .interactive, .sheet, .runnable, legacy: "Encryption", tags: ["crypto"]),
        make("network.speed-test", "PooToolsNetworkSpeedTest", "Network Speed Test", .networkConnectivity, .interactive, .push, .runnable, legacy: "NetworkSpeedTest", tags: ["network", "speed", "endpoint"]),
        make("network.ping", "PooToolsPing", "Ping Session", .networkConnectivity, .interactive, .push, .runnable, legacy: "PingSession", tags: ["network", "ping", "state-machine"]),
        make("device.heart-rate", "PooToolsHeartRate", "Heart Rate", .permissionsDevice, .hostRequired, .fullScreen, .physicalDeviceRequired, [.camera, .physicalDevice], legacy: "HeartRate", tags: ["camera", "health", "runtime-safety"]),
        // English: Application infrastructure demos expose each opt-in contract without changing the default Core product.
        // Español: Los demos de infraestructura exponen cada contrato opt-in sin cambiar el producto Core predeterminado.
        // 中文：应用基础设施 Demo 展示各个可选契约，但不改变默认 Core 产品。
        make("infrastructure.database", "PToolsDatabase", "SQLite Database", .storageData, .interactive, .push, .runnable, tags: ["sqlite3", "actor", "migration"]),
        make("infrastructure.auth", "PToolsAuth", "Authentication", .securityPrivacy, .interactive, .push, .runnable, tags: ["auth", "refresh", "pkce"]),
        make("infrastructure.sync", "PToolsSync", "Offline Sync", .storageData, .interactive, .push, .runnable, tags: ["offline", "retry", "conflict"]),
        make("infrastructure.transfer", "PToolsTransfer", "Transfer Queue", .networkConnectivity, .interactive, .push, .runnable, tags: ["background", "checksum"]),
        make("infrastructure.storekit", "PToolsStoreKit", "StoreKit 2", .modernSystem, .hostRequired, .push, .entitlementRequired, [.entitlement], tags: ["storekit2", "purchase"]),
        make("infrastructure.observability", "PToolsObservability", "Observability", .debugDiagnostics, .interactive, .push, .runnable, tags: ["metrics", "privacy"]),
        make("infrastructure.webbridge", "PToolsWebBridge", "Web Bridge", .modernSystem, .interactive, .push, .runnable, tags: ["webkit", "reply"]),
        make("infrastructure.map", "PToolsMap", "MapKit", .modernSystem, .interactive, .push, .runnable, tags: ["mapkit", "route"]),
        make("infrastructure.integrity", "PToolsAppIntegrity", "App Integrity", .securityPrivacy, .hostRequired, .push, .physicalDeviceRequired, [.physicalDevice], tags: ["app-attest", "devicecheck"]),
        make("infrastructure.remote-config", "PToolsConfiguration", "Remote Configuration", .modernSystem, .interactive, .push, .runnable, tags: ["etag", "rollout", "kill-switch"]),
        make("infrastructure.realtime", "PToolsRealtime", "Realtime SSE", .networkConnectivity, .interactive, .push, .runnable, tags: ["sse", "websocket", "reconnect"]),
    ]

    static var sections: [PTDemoSection] {
        let grouped = Dictionary(grouping: descriptors, by: { $0.category })
        return PTDemoCategory.allCases.compactMap { category in
            guard let demos = grouped[category], !demos.isEmpty else { return nil }
            return PTDemoSection(id: category.rawValue, title: category.displayTitle, demos: demos)
        }
    }

    static func descriptor(for id: PTDemoID) -> PTDemoDescriptor? {
        descriptors.first { $0.id == id }
    }

    static func descriptor(forRawID rawValue: String) -> PTDemoDescriptor? {
        descriptor(for: PTDemoID(rawValue: rawValue))
    }

    static func descriptor(forLegacyRoute route: String) -> PTDemoDescriptor? {
        descriptors.first { $0.legacyRoute == route }
    }

    private static func make(
        _ id: String,
        _ moduleID: String,
        _ titleKey: String,
        _ category: PTDemoCategory,
        _ kind: PTDemoKind,
        _ presentation: PTDemoPresentation,
        _ availability: PTDemoAvailability,
        _ requirements: [PTDemoRequirement] = [],
        legacy: String? = nil,
        tags: [String] = []
    ) -> PTDemoDescriptor {
        PTDemoDescriptor(
            id: PTDemoID(rawValue: id),
            moduleID: moduleID,
            titleKey: titleKey,
            subtitleKey: nil,
            category: category,
            kind: kind,
            tags: tags,
            presentation: presentation,
            availability: availability,
            requirements: requirements,
            routeID: id,
            legacyRoute: legacy
        )
    }
}

@MainActor
final class PTDemoFactoryRegistry {
    typealias Factory = @MainActor () -> UIViewController

    static let shared = PTDemoFactoryRegistry()
    private var factories: [PTDemoID: Factory] = [:]

    func register(_ factory: @escaping Factory, for id: PTDemoID) {
        factories[id] = factory
    }

    func remove(for id: PTDemoID) {
        factories[id] = nil
    }

    func makeViewController(for descriptor: PTDemoDescriptor) -> UIViewController? {
        factories[descriptor.id]?()
    }
}

@MainActor
final class PTDemoCoordinator {
    static let shared = PTDemoCoordinator()

    func viewController(for descriptor: PTDemoDescriptor) -> UIViewController {
        if let registered = PTDemoFactoryRegistry.shared.makeViewController(for: descriptor) {
            return registered
        }

        // English: Every Duo descriptor gets a visible host even when its real module needs hardware or permissions.
        // Español: Cada descriptor Duo obtiene un host visible aunque el módulo real necesite hardware o permisos.
        // 中文：即使真实模块需要硬件或权限，每个 Duo 描述符也必须先展示可用宿主页面。
        if descriptor.id.rawValue.hasPrefix("duo.") {
            return PTDuoRegressionDemoViewController(descriptor: descriptor)
        }

        switch descriptor.id.rawValue {
        case "navigation.split-view":
            return PT5_61SplitViewDemoViewController()
        case "navigation.duo-adaptive-bars":
            return PTDuoAdaptiveBarDemoViewController()
        case "network.speed-test":
            return PT5_61NetworkSpeedDemoViewController()
        case "network.ping":
            return PT5_61PingDemoViewController()
        case "device.heart-rate":
            return PTHeartRateViewController()
        case "ui.tabbar-insets":
            return PTTabBarInsetsDemoViewController()
        case "ui.gradient-rendering":
            return PTGradientRenderingDemoViewController()
        case "ui.collection-refresh-lab":
            return PTCollectionRefreshLabViewController()
        case "ui.collection-layout-switch-lab":
            return PTCollectionLayoutSwitchLabViewController()
        case "ui.collection-skeleton-lab":
            return PTCollectionSkeletonLabViewController()
        case let id where id.hasPrefix("ui.layout."):
            return PTLayoutLabViewController(demoID: descriptor.id)
        case "ui.control-menu":
            return PTControlMenuDemoViewController()
        case "input.all-styles":
            return PTInputStylesDemoViewController()
        case "media.image-clarity":
            return PTImageClarityDemoViewController()
        case "ui.rich-text-attachment-multiline":
            return PTRichTextAttachmentMultilineDemoViewController()
        case "ui.rich-text-fragment-line-limit":
            return PTRichTextFragmentLineLimitDemoViewController()
        case "security.acknowledgements":
            guard let manifest = PTDemoAcknowledgementsData.manifest else {
                return PTFuncDetailViewController(descriptor: descriptor)
            }
            let vc = PTAcknowledgementsViewController(
                configuration: PTDemoAcknowledgementsData.configuration,
                dataSource: PTInMemoryAcknowledgementsDataSource(manifest: manifest))
            return vc
        case "security.acknowledgements-headless":
            return PTAcknowledgementsHeadlessDemoViewController()
        case "infrastructure.database":
            return PTDatabaseInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.auth":
            return PTAuthInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.sync":
            return PTSyncInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.transfer":
            return PTTransferInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.storekit":
            return PTStoreKitInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.observability":
            return PTObservabilityInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.webbridge":
            return PTWebBridgeInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.map":
            return PTMapInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.integrity":
            return PTIntegrityInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.remote-config":
            return PTRemoteConfigurationInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        case "infrastructure.realtime":
            return PTRealtimeInfrastructureDemoViewController(moduleID: descriptor.moduleID, title: descriptor.titleKey, tags: descriptor.tags)
        default:
            return PTFuncDetailViewController(descriptor: descriptor)
        }
    }

    func present(_ descriptor: PTDemoDescriptor, from host: UIViewController, sizes: [PTSheetSize] = [.percent(0.5)]) {
        let viewController = viewController(for: descriptor)
        switch descriptor.presentation {
        case .push:
            if let navigationController = host.navigationController {
                navigationController.pushViewController(viewController, animated: true)
            } else {
                // English: A Demo must remain visible even when its host has no navigation controller.
                // Español: Un Demo debe seguir siendo visible aunque su host no tenga navegación.
                // 中文：即使宿主没有导航控制器，Demo 也不能静默无响应。
                viewController.modalPresentationStyle = .fullScreen
                host.present(viewController, animated: true)
            }
        case .fullScreen:
            viewController.modalPresentationStyle = .fullScreen
            host.showDetailViewController(viewController, sender: nil)
        case .rootContainer:
            viewController.modalPresentationStyle = .fullScreen
            host.present(viewController, animated: true)
        case .sheet, .inline, .action:
            UIViewController.currentPresentToSheet(vc: viewController, sizes: sizes)
        }
    }
}

// English: The demo uses a local fixture so it proves the UI and headless APIs without network access.
// Español: El demo usa un fixture local para demostrar la UI y las APIs headless sin red.
// 中文：Demo 使用本地 Fixture，确保 UI 和纯数据 API 在无网络时也能真实运行。
@MainActor
private enum PTDemoAcknowledgementsData {
    static let configuration: PTAcknowledgementsConfiguration = {
        var value = PTAcknowledgementsConfiguration()
        value.title = "开源许可证"
        value.footer = "SAMPLE · 构建期清单 / Manifest de compilación / Build-time manifest"
        value.grouping = .licenseType
        return value
    }()

    static let manifest: PTLicenseManifest? = {
        let license = PTLicenseDocument(
            fileName: "LICENSE",
            text: "Permission is hereby granted, free of charge, to use this sample.\n"
        )
        let entries = [
            PTAcknowledgement(
                id: "sample.ptools.acknowledgements",
                name: "PTools Acknowledgements",
                version: "5.66.1",
                sourceManagers: [.manual],
                licenseExpression: "MIT",
                licenseTexts: [license],
                verification: .verified
            ),
            PTAcknowledgement(
                id: "sample.foundation",
                name: "Foundation",
                version: nil,
                sourceManagers: [.manual],
                licenseExpression: "Apple SDK",
                verification: .review
            )
        ]
        return try? PTAcknowledgementsProvider.make(
            entries: entries,
            generatorVersion: "demo",
            appTarget: "PooTools_Example"
        )
    }()
}

// English: This screen demonstrates Core queries, statistics, and typed failure handling without the built-in list UI.
// Español: Esta pantalla demuestra consultas, estadísticas y errores tipados de Core sin la UI de lista integrada.
// 中文：这个页面展示 Core 查询、统计和类型化错误处理，不依赖内置列表 UI。
@MainActor
private final class PTAcknowledgementsHeadlessDemoViewController: PTBaseViewController {
    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "许可证纯数据"
        view.backgroundColor = .systemBackground
        textView.isEditable = false
        textView.adjustsFontForContentSizeCategory = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.backgroundColor = .clear
        view.addSubview(textView)
        textView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.layoutMarginsGuide)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.bottom.equalToSuperview()
        }
        textView.text = makeText()
    }

    private func makeText() -> String {
        guard let manifest = PTDemoAcknowledgementsData.manifest else {
            return "无法创建本地示例清单 / No se pudo crear el manifest local / Unable to create local manifest"
        }
        let statistics = manifest.statistics()
        let names = manifest.search("PTools").map(\.name).joined(separator: ", ")
        let jsonSize = (try? manifest.export(.json).count) ?? 0
        let missingText = manifest.validationIssues().filter { $0.code == "missing-license-text" }.count
        return [
            "Headless Core Demo",
            "条目数 / Entradas / Entries: \(statistics.totalDependencies)",
            "已验证 / Verificadas / Verified: \(statistics.verificationCounts[PTAcknowledgementVerification.verified.rawValue, default: 0])",
            "缺少原文 / Sin texto / Missing text: \(missingText)",
            "搜索 PTools / Búsqueda / Search: \(names)",
            "JSON 导出 / Export JSON: \(jsonSize) bytes",
            "\n数据只来自内存 Fixture，不访问网络。\nDatos locales; sin red.\nLocal fixture; no network."
        ].joined(separator: "\n")
    }
}

// English: Keep every Duo regression route visible and actionable instead of falling through to an empty legacy page.
// Español: Mantiene visible y accionable cada ruta de regresión Duo en lugar de caer en una página heredada vacía.
// 中文：让每个 Duo 回归路由都有可见内容和可执行入口，不再落入空白旧页面。
@MainActor
private final class PTDuoRegressionDemoViewController: PTBaseViewController {
    private let descriptor: PTDemoDescriptor
    private let statusLabel = UILabel()

    init(descriptor: PTDemoDescriptor) {
        self.descriptor = descriptor
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is unavailable")
    }

    override func prefersLargeTitle() -> Bool {
        descriptor.id.rawValue == "duo.large-title-navigation"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = descriptor.titleKey
        view.backgroundColor = .systemBackground
        configureContent()
    }

    private func configureContent() {
        let scrollView = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.text = descriptor.titleKey

        let summaryLabel = UILabel()
        summaryLabel.font = .preferredFont(forTextStyle: .body)
        summaryLabel.textColor = .secondaryLabel
        summaryLabel.numberOfLines = 0
        summaryLabel.text = summaryText

        let contractLabel = UILabel()
        contractLabel.font = .preferredFont(forTextStyle: .footnote)
        contractLabel.textColor = .secondaryLabel
        contractLabel.numberOfLines = 0
        contractLabel.text = "iPhone Duo / iOS 27.1\n布局读取当前 Scene 的 bounds、safe area 和 vertical bar edge。"

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.text = "Demo 已加载 / Demo cargado / Demo loaded"

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(summaryLabel)
        stack.addArrangedSubview(contractLabel)

        if let actionTitle {
            let actionButton = UIButton(type: .system)
            actionButton.setTitle(actionTitle, for: .normal)
            actionButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
            actionButton.addTarget(self, action: #selector(runAction), for: .primaryActionTriggered)
            actionButton.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(44)
            }
            stack.addArrangedSubview(actionButton)
        }

        stack.addArrangedSubview(statusLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(20)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }
    }

    private var summaryText: String {
        switch descriptor.id.rawValue {
        case "duo.photo-picker-grid":
            return "验证 PhotoPicker 在 Duo 局部安全区域中的网格、完成按钮和滚动区域。"
        case "duo.image-editor-controls":
            return "验证 ImageEditor 的编辑画布、工具栏和底部控制不会被系统区域遮挡。"
        case "duo.video-editor-controls":
            return "验证 VideoEditor 时间轴和导出控制；真实视频导出需要真机媒体资源。"
        case "duo.media-viewer-paging":
            return "验证 MediaViewer 翻页时媒体内容和页码状态不会被 Duo 保留区域截断。"
        case "duo.media-viewer-bottom":
            return "验证 MediaViewer 底部工具栏在 Duo 场景中保持可操作。"
        case "duo.message-kit-chat":
            return "验证 MessageKit 聊天列表、头像、发信人信息和输入区域的安全边距。"
        case "duo.large-title-navigation":
            return "验证大标题导航在经典布局和 Duo 系统导航栏之间的所有权切换。"
        case "duo.tab-accessory-search":
            return "验证 Tab accessory 和搜索入口不会占用或遮挡主内容区域。"
        case "duo.paging-segmented":
            return "验证 Segmented、Paging 和嵌套滚动在宽度变化时保持状态。"
        case "duo.unified-collision-stress":
            return "验证导航、Tab、Accessory 和 reserved region 同时出现时的碰撞处理。"
        case "duo.alert-action-sheet":
            return "验证多按钮、长文本、Dynamic Type 和键盘出现时，Alert / ActionSheet 的操作区域仍然可达。"
        case "duo.overlay-popover-banner":
            return "验证多方向 anchor、Popover、Banner 和 Scene 尺寸变化时，浮层不会进入保留区域。"
        case "duo.form-keyboard-search":
            return "验证表单 footer、搜索取消按钮、自定义数字键盘和键盘避让。"
        case "duo.collection-all-layouts":
            return "验证 Normal、Grid、Waterfall、Tag、Horizontal、Custom 布局切换和滚动状态连续性。"
        case "duo.split-page-container":
            return "验证 SplitView / PageContainer 展开、折叠以及 child selection 和滚动状态保留。"
        case "duo.picker-permission-system":
            return "验证 ImagePicker、PhotoPicker、权限提示和系统选择器的安全区域与返回入口。"
        case "duo.debug-overlay-guide":
            return "验证 Debug Console、Inspector、Guide spotlight 和 LaunchAd skip 在当前 Scene 中可移动、可关闭。"
        case "duo.rtl-dynamic-type":
            return "验证 RTL、超大字体、VoiceOver、Reduce Motion 和垂直系统 Bar 的可访问性。"
        default:
            return "Duo 回归场景已注册，当前页面提供安全区域和状态连续性检查。"
        }
    }

    private var actionTitle: String? {
        switch descriptor.id.rawValue {
        case "duo.photo-picker-grid": return "打开 PhotoPicker"
        case "duo.image-editor-controls": return "打开 ImageEditor"
        case "duo.media-viewer-paging", "duo.media-viewer-bottom": return "打开 MediaViewer"
        case "duo.message-kit-chat": return "打开 MessageKit"
        case "duo.paging-segmented": return "打开 Segmented / Paging"
        case "duo.alert-action-sheet": return "打开 Alert / ActionSheet"
        case "duo.overlay-popover-banner": return "打开 Overlay / Popover / Banner"
        case "duo.form-keyboard-search": return "打开 Form / Keyboard / Search"
        case "duo.collection-all-layouts": return "打开 Collection Layouts"
        case "duo.split-page-container": return "打开 Split Page Container"
        case "duo.picker-permission-system": return "打开 Picker / Permission"
        case "duo.debug-overlay-guide": return "打开 Debug Overlay / Guide"
        case "duo.rtl-dynamic-type": return "切换 RTL / Dynamic Type"
        default: return nil
        }
    }

    @objc private func runAction() {
        switch descriptor.id.rawValue {
        case "duo.photo-picker-grid":
            let picker = PTMediaLibViewController()
            picker.mediaLibShow()
            statusLabel.text = "PhotoPicker 已打开 / PhotoPicker abierto / PhotoPicker opened"
        case "duo.image-editor-controls":
            let image = UIImage(named: "DemoImage") ?? UIImage()
            let editor = PTEditImageViewController(readyEditImage: image)
            let navigationController = PTBaseNavControl(rootViewController: editor)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: true)
        case "duo.media-viewer-paging", "duo.media-viewer-bottom":
            let model = PTMediaBrowserModel()
            model.imageURL = UIImage(named: "DemoImage")
            let viewer = PTMediaBrowserController(mediaData: [model])
            viewer.modalPresentationStyle = .fullScreen
            present(viewer, animated: true)
        case "duo.message-kit-chat":
            navigationController?.pushViewController(PTTestChatViewController(), animated: true)
        case "duo.paging-segmented":
            guard let descriptor = PTDemoRegistry.descriptor(forRawID: "navigation.segment-paging-regression") else { return }
            navigationController?.pushViewController(PTFuncDetailViewController(descriptor: descriptor), animated: true)
        case "duo.alert-action-sheet":
            UIAlertController.base_alertVC(title: "Duo Alert",
                                           msg: "长文本、多按钮和 Dynamic Type 会根据当前 Scene 重新测量。",
                                           okBtns: ["继续", "更多操作"],
                                           cancelBtn: "取消")
        case "duo.overlay-popover-banner":
            let banner = PTBanner.success(title: "Duo Banner",
                                          subtitle: "浮层会跟随宿主 Scene 的可视区域重新定位")
            PTBannerCenter.shared.show(banner)
        case "duo.form-keyboard-search":
            let controller = PTDuoFormKeyboardSearchDemoViewController()
            navigationController?.pushViewController(controller, animated: true)
        case "duo.collection-all-layouts":
            navigationController?.pushViewController(PTCollectionLayoutSwitchLabViewController(), animated: true)
        case "duo.split-page-container":
            navigationController?.pushViewController(PT5_61SplitViewDemoViewController(), animated: true)
        case "duo.picker-permission-system":
            let picker = PTMediaLibViewController()
            picker.mediaLibShow()
            statusLabel.text = "Picker 已打开 / Picker abierto / Picker opened"
        case "duo.debug-overlay-guide":
            statusLabel.text = "请从 Debug 菜单打开 Console / Inspector / Guide。"
        case "duo.rtl-dynamic-type":
            // English: Scope RTL to this demo instead of mutating process-wide appearance state.
            // Español: Limita RTL a este demo en vez de mutar el estado global de apariencia.
            // 中文：仅对当前 Demo 设置 RTL，避免修改进程级外观状态。
            view.semanticContentAttribute = .forceRightToLeft
            view.setNeedsLayout()
            statusLabel.text = "RTL 已启用 / RTL activado / RTL enabled"
        default:
            break
        }
    }
}

// English: Keep the form regression demo self-contained so keyboard and search behavior can be exercised from the catalog.
// Español: Mantiene autónomo el demo de formulario para probar teclado y búsqueda desde el catálogo.
// 中文：让表单回归 Demo 自包含，用户可以直接从目录验证键盘和搜索行为。
@MainActor
private final class PTDuoFormKeyboardSearchDemoViewController: PTBaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        pt_Title = "Duo Form / Search"
        let scrollView = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16

        let search = UISearchBar()
        search.placeholder = "搜索 / Buscar / Search"
        let input = UITextField()
        input.borderStyle = .roundedRect
        input.placeholder = "输入内容"
        input.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }
        let footer = UILabel()
        footer.numberOfLines = 0
        footer.textColor = .secondaryLabel
        footer.text = "键盘出现时，滚动内容和 footer 应保持在当前可视区域内。"
        stack.addArrangedSubview(search)
        stack.addArrangedSubview(input)
        stack.addArrangedSubview(footer)

        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(20)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }
    }
}

// English: Show all adaptive navigation and tab-bar scenarios without changing the production defaults.
// Español: Muestra todos los escenarios de navegación y tab-bar adaptativos sin cambiar los valores de producción.
// 中文：展示全部自适应导航栏和 TabBar 场景，同时不改变生产默认配置。
@MainActor
private final class PTDuoAdaptiveBarDemoViewController: PTBaseTabBarViewController {
    private let scenarios: [(String, String)] = [
        ("Outer / Vertical Nav + Tabs", "Back、Save、More、4–6 个 Tab、Badge，以及同一侧 rail 的分段布局。"),
        ("Inner Portrait / Classic", "展开直向时保留传统顶部标题、左右操作和底部图文 TabBar。"),
        ("Inner Landscape / Auto Edge", "横向由系统 verticalBarEdge 决定侧边，比较可用内容高度。"),
        ("Expanded / Prefer Classic", "显式 classic policy 只作为稳定 opt-out，不用宽度猜测设备类型。"),
        ("Center Raised + Lottie", "中央操作和动态媒体保留同一个 content 实例，切轴不重建。"),
        ("Badge + Selection + Mini", "无标题、长标题、Badge、Mini 和选中背景沿用同一选择状态。"),
        ("Push / Pop / Interactive Pop", "根页面、二级隐藏、返回恢复与交互式返回不重置选中 Tab。"),
        ("Search + Keyboard + Overflow", "内容区承载输入，空间不足时保留核心入口并转入 overflow。"),
        ("Accessibility", "Dynamic Type、VoiceOver、粗体、Reduce Motion 和 Reduce Transparency。"),
        ("Multi Scene / Split View", "每个 Scene 使用自己的 bounds、safe area、策略和选中状态。"),
        ("FakeNav / Modal / Sheet / Alert", "特殊容器不覆盖关闭入口，系统和自定义层级保持单一所有权。"),
        ("Rapid Fold / Resize Stress", "连续尺寸变化只刷新值类型几何，不清空导航栈、Badge 或输入状态。")
    ]

    override func viewDidLoad() {
        // English: Use automatic mode so iOS 27.1+ UIKit owns vertical-bar geometry and older systems stay classic.
        // Español: Usa el modo automático para que UIKit gestione la geometría vertical en iOS 27.1+ y los sistemas antiguos sigan clásicos.
        // 中文：使用 automatic，让 iOS 27.1+ 由 UIKit 统一管理垂直 Bar，旧系统保持经典布局。
        adaptiveBarConfiguration = .init(presentationPolicy: .automatic,
                                         minimumTouchTarget: 44,
                                         favorsTabVisibility: true,
                                         enablesCustomEffects: true)
        showsAdaptiveBarDebugOverlay = true
        super.viewDidLoad()

        let configs = [
            makeTab(title: "Duo", symbol: "rectangle.split.2x1", scenarios: scenarios),
            makeTab(title: "Classic", symbol: "iphone", scenarios: Array(scenarios.prefix(4))),
            makeTab(title: "Stress", symbol: "arrow.triangle.2.circlepath", scenarios: Array(scenarios.suffix(4)))
        ]
        configure(items: configs)
        ptCustomBar.setup(configs: configs,
                          layoutStyle: .centerRaised,
                          centerContent: PTTabBarImageContent(normal: PTSymbolResolver.image(.sparkles) ?? UIImage()))
        ptCustomBar.badge(index: 0, badgeValue: "12")
        centerRaisedSet = true
    }

    private func makeTab(title: String,
                         symbol: String,
                         scenarios: [(String, String)]) -> PTTabBarItemConfig {
        let content = PTTabBarImageContent(normal: PTSymbolResolver.image(PTSymbol(rawValue: symbol)) ?? UIImage(),
                                            selected: PTSymbolResolver.image(PTSymbol(rawValue: symbol).appending("fill")))
        let scenarioController = PTDuoAdaptiveScenarioViewController(title: title,
                                                                       scenarios: scenarios)
        return PTTabBarItemConfig(title: title,
                                  content: content,
                                  viewController: PTBaseNavControl(rootViewController: scenarioController))
    }
}

// English: Keep the scenario body in a normal PTools base controller so push/pop behavior is exercised.
// Español: Mantiene el cuerpo del escenario en un controlador base normal de PTools para ejercitar push/pop.
// 中文：使用普通 PTools 基类承载场景内容，以真实验证 push/pop 行为。
@MainActor
private final class PTDuoAdaptiveScenarioViewController: PTBaseViewController {
    private let scenarioTitle: String
    private let scenarios: [(String, String)]

    init(title: String, scenarios: [(String, String)]) {
        scenarioTitle = title
        self.scenarios = scenarios
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        scenarioTitle = ""
        scenarios = []
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pt_Title = scenarioTitle
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(systemItem: .save),
            UIBarButtonItem(systemItem: .organize)
        ]

        let scrollView = UIScrollView()
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill

        let heading = UILabel()
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.textColor = .label
        heading.numberOfLines = 0
        heading.text = "PTools iPhone Duo\n\(scenarioTitle)"
        stack.addArrangedSubview(heading)

        let hint = UILabel()
        hint.font = .preferredFont(forTextStyle: .subheadline)
        hint.textColor = .secondaryLabel
        hint.numberOfLines = 0
        hint.text = "布局由当前 Scene 的 bounds、safe area、verticalBarEdge 和 reserved regions 决定。"
        stack.addArrangedSubview(hint)

        for (index, scenario) in scenarios.enumerated() {
            let label = UILabel()
            label.font = .preferredFont(forTextStyle: .body)
            label.textColor = .label
            label.numberOfLines = 0
            label.text = "\(index + 1). \(scenario.0)\n\(scenario.1)"
            label.accessibilityLabel = "\(scenario.0)：\(scenario.1)"
            stack.addArrangedSubview(label)
        }

        view.addSubview(scrollView)
        scrollView.addSubview(stack)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
    }
}

// English: Demonstrates native menus for PTools UIControls without recreating UIKit menu UI.
// Español: Demuestra menús nativos para UIControls de PTools sin recrear la interfaz de UIKit.
// 中文：演示 PTools UIControl 的原生菜单能力，不重复实现 UIKit 菜单界面。
@MainActor
private final class PTControlMenuDemoViewController: PTBaseViewController {
    private enum Sort: String, CaseIterable, Hashable {
        case all = "综合"
        case sales = "销量"
        case price = "价格"
        case latest = "最新"
    }

    private var currentSort: Sort = .all
    private let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "UIControl Menu"
        configureView()
    }

    private func configureView() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        let longPressButton = PTActionLayoutButton()
        longPressButton.layoutStyle = .title
        longPressButton.setTitle("长按：普通菜单", state: .normal)
        longPressButton.setTitleColor(.label, state: .normal)
        longPressButton.pt_setMenu(
            UIMenu(children: [
                UIAction(title: "复制", image: PTSymbolResolver.image(.docOnDoc)) { [weak self] _ in
                    self?.statusLabel.text = "已选择：复制"
                },
                UIAction(title: "分享", image: PTSymbolResolver.image(.squareAndArrowUp)) { [weak self] _ in
                    self?.statusLabel.text = "已选择：分享"
                }
            ]),
            trigger: .longPress
        )
        longPressButton.addActionHandlers { [weak self] _ in
            self?.statusLabel.text = "普通点击仍然可用"
        }

        let selectionButton = PTActionLayoutButton()
        selectionButton.layoutStyle = .title
        selectionButton.setTitle("排序：综合", state: .normal)
        selectionButton.setTitleColor(.label, state: .normal)
        selectionButton.pt_setSelectionMenuProvider(
            trigger: .primaryAction,
            items: {
                Sort.allCases.map { sort in
                    PTControlMenuSelectionItem(
                        id: sort,
                        title: sort.rawValue,
                        selectedImage: sort == .sales ? PTSymbolResolver.image(PTSymbol(rawValue: "chart.bar.fill")) : nil
                    )
                }
            },
            selectedID: { [weak self] in self?.currentSort },
            selectionChanged: { [weak self, weak selectionButton] sort in
                self?.currentSort = sort
                selectionButton?.setTitle("排序：\(sort.rawValue)", state: .normal)
                self?.statusLabel.text = "当前排序：\(sort.rawValue)"
            }
        )

        let nativeButton = PTBaseButton(type: .system)
        nativeButton.setTitle("UIButton 原生 Primary Menu", for: .normal)
        nativeButton.menu = UIMenu(children: [
            UIAction(title: "系统菜单", image: PTSymbolResolver.image(.checkmarkCircle)) { [weak self] _ in
                self?.statusLabel.text = "UIButton 使用 UIKit 原生 menu"
            }
        ])
        nativeButton.showsMenuAsPrimaryAction = true

        let loadingButton = PTActionLayoutButton()
        loadingButton.layoutStyle = .title
        loadingButton.setTitle("点击后进入 Loading", state: .normal)
        loadingButton.setTitleColor(.label, state: .normal)
        loadingButton.pt_setMenu(
            UIMenu(children: [
                UIAction(title: "长按菜单仍受 loading 状态控制") { [weak self] _ in
                    self?.statusLabel.text = "Loading 已结束"
                }
            ]),
            trigger: .longPress
        )
        loadingButton.addActionHandlers { [weak self] sender in
            sender.startLoading()
            self?.statusLabel.text = "Loading 中：菜单暂时不可用"
            PTGCDManager.shared.delayOnMain(time: 1) {
                sender.stopLoading()
                self?.statusLabel.text = "Loading 结束：菜单已恢复"
            }
        }

        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel
        statusLabel.text = "UIControl 原生菜单能力"

        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.text = "PTActionLayoutButton 支持长按和主点击；UIButton / PTBaseButton 直接使用 UIKit 原生 menu。"

        [descriptionLabel, longPressButton, selectionButton, nativeButton, loadingButton, statusLabel].forEach {
            stack.addArrangedSubview($0)
            $0.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(44)
            }
        }

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
    }
}

// English: The shared host owns only presentation and lifecycle; each infrastructure demo supplies its own local operation.
// Español: El host compartido solo gestiona presentación y ciclo de vida; cada demo de infraestructura aporta su propia operación local.
// 中文：共享宿主只负责展示和生命周期，各基础设施 Demo 自己提供本地可运行操作。
@MainActor
private class PTApplicationInfrastructureDemoViewController: PTBaseViewController {
    private let moduleID: String
    private let demoTitle: String
    private let tags: [String]
    private let statusLabel = UILabel()
    private var task: Task<Void, Never>?

    init(moduleID: String, title: String, tags: [String]) {
        self.moduleID = moduleID
        self.demoTitle = title
        self.tags = tags
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    deinit { task?.cancel() }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = demoTitle
        configureView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        task?.cancel()
        task = nil
    }

    private func configureView() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill

        let titleLabel = UILabel()
        titleLabel.text = demoTitle
        titleLabel.font = .preferredFont(forTextStyle: .title2)

        let moduleLabel = UILabel()
        moduleLabel.text = "Module: \(moduleID)"
        moduleLabel.font = .preferredFont(forTextStyle: .subheadline)
        moduleLabel.textColor = .secondaryLabel

        let contractLabel = UILabel()
        contractLabel.numberOfLines = 0
        contractLabel.text = "iOS 17+ / Swift 6+\n可选基础设施契约已注册；实际宿主按需引入对应 product。"

        let tagLabel = UILabel()
        tagLabel.numberOfLines = 0
        tagLabel.textColor = .secondaryLabel
        tagLabel.text = "Capabilities: \(tags.joined(separator: " · "))"

        let button = UIButton(type: .system)
        button.setTitle("Run local contract check", for: .normal)
        button.addTarget(self, action: #selector(runContractCheck), for: .touchUpInside)

        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.addTarget(self, action: #selector(resetDemo), for: .touchUpInside)

        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel
        statusLabel.text = "等待检查"
        [titleLabel, moduleLabel, contractLabel, tagLabel, button, resetButton, statusLabel].forEach(stack.addArrangedSubview)

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
    }

    @objc private func runContractCheck() {
        statusLabel.text = "运行中… / Ejecutando… / Running…"
        task?.cancel()
        task = Task { [weak self] in
            do {
                let result = try await self?.runModuleCheck() ?? "未返回结果"
                guard !Task.isCancelled else { return }
                self?.statusLabel.text = result
            } catch {
                guard !Task.isCancelled else { return }
                self?.statusLabel.text = "失败 / Error: \(error.localizedDescription)"
            }
        }
    }

    @objc private func resetDemo() {
        task?.cancel()
        task = nil
        statusLabel.text = "等待检查"
    }

    func runModuleCheck() async throws -> String {
        "\(moduleID) · 本地操作未提供 / operación local no disponible / local operation unavailable"
    }
}

// English: Each controller below is a real catalog route with an isolated module-specific smoke operation.
// Español: Cada controlador siguiente es una ruta real del catálogo con una prueba aislada del módulo.
// 中文：下面每个控制器都是独立的真实目录路由，并执行对应模块的轻量冒烟检查。
@MainActor
private final class PTDatabaseInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    private let databaseURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("ptools-5.62-demo-\(UUID().uuidString).sqlite")

    override func runModuleCheck() async throws -> String {
        let database = try await PTDatabase.open(url: databaseURL)
        try await database.execute("CREATE TABLE IF NOT EXISTS demo (id INTEGER PRIMARY KEY, name TEXT NOT NULL)")
        try await database.execute("DELETE FROM demo")
        try await database.transaction { database in
            _ = try await database.insert(PTDatabaseQuery("INSERT INTO demo (name) VALUES (?)", arguments: [.text("PTools")]))
            _ = try await database.insert(PTDatabaseQuery("INSERT INTO demo (name) VALUES (?)", arguments: [.text("Infrastructure")]))
        }
        try await database.execute("UPDATE demo SET name = ? WHERE id = 1", arguments: [.text("PTools 5.62")])
        let page = try await database.pageModels(PTDatabaseQuery("SELECT id, name FROM demo ORDER BY id"),
                                                 as: PTDemoDatabaseRow.self,
                                                 offset: 0,
                                                 limit: 1)
        let backupURL = databaseURL.deletingPathExtension().appendingPathExtension("backup.sqlite")
        let backup = try await database.backup(to: backupURL)
        let integrity = try await database.integrityCheck()
        let runtime = try await database.runtimeSnapshot()
        await database.close()
        try await database.reopen()
        return "SQLite OK · rows: \(page.values.count) · more: \(page.hasMore) · backup: \(backup.byteCount) bytes · integrity: \(integrity.passed) · \(runtime.journalMode) · \(runtime.sqliteVersion)"
    }
}

@MainActor
private final class PTAuthInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        let store = PTDemoAuthCredentialStore()
        let remote = PTDemoAuthRemoteProvider()
        let service = PTAuthService(credentialStore: store, remoteProvider: remote)
        let session = PTAuthSession(userID: "demo",
                                    token: PTAuthToken(accessToken: "expired",
                                                       refreshToken: "refresh",
                                                       expiresAt: .distantPast))
        try await service.signIn(session)
        let tokens = try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
            for _ in 0..<100 { group.addTask { try await service.validToken().accessToken } }
            var values: [String] = []
            for try await value in group { values.append(value) }
            return values
        }
        let state = await service.state()
        let refreshCount = await remote.refreshCount
        let challenge = PTOAuthPKCEGenerator.makeChallenge(state: "demo-state")
        let callbackURL = URL(string: "demo://callback?code=demo-code&state=demo-state")!
        _ = try PTOAuthCallbackValidator.validate(callbackURL: callbackURL, expectedState: challenge.state)
        return "Auth OK · 100 tokens: \(tokens.count) · refreshes: \(refreshCount) · state: \(String(describing: state)) · Apple: \(PTAppleAuthCapability().isAvailable) · Passkey: \(PTPasskeyCapability().isAvailable)"
    }
}

@MainActor
private final class PTSyncInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        let database = try PTDatabase()
        let store = try await PTSyncDatabaseStore(database: database)
        let engine = PTSyncEngine(store: store, remote: PTDemoSyncRemote())
        for index in 0..<10 {
            try await engine.enqueue(PTSyncMutation(key: "demo-\(index)", payload: Data("{}".utf8)))
        }
        let result = await engine.sync()
        let pending = try await store.pending()
        return "Sync OK · results: \(result.count) · pending: \(pending.count) · durable store boundary ready"
    }
}

@MainActor
private final class PTTransferInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        let request = PTTransferRequest(source: .download(URL(string: "https://example.invalid/file")!),
                                        destination: FileManager.default.temporaryDirectory.appendingPathComponent("demo.file"),
                                        priority: .high)
        let snapshot = PTTransferSnapshot(request: request, state: .queued)
        let runtime = PTTransferRuntimeSnapshot(id: request.id,
                                                state: snapshot.state,
                                                progress: snapshot.progress,
                                                canResume: false)
        return "Transfer request OK · priority: \(snapshot.request.priority.rawValue) · max concurrent: \(snapshot.request.policy.maxConcurrent) · state: \(runtime.state) · cancellation boundary ready"
    }
}

@MainActor
private final class PTStoreKitInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        let store = PTStore(verificationPolicy: .init(finishVerifiedTransactions: false))
        let products = (try? await store.products(for: ["com.pootools.demo.credits", "com.pootools.demo.pro", "com.pootools.demo.plus.monthly"])) ?? []
        return "StoreKit 2 ready · products: \(products.count) · configuration: PToolsDemo.storekit · purchase remains explicit"
    }
}

@MainActor
private final class PTObservabilityInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        let bufferURL = FileManager.default.temporaryDirectory.appendingPathComponent("ptools-observability-demo.jsonl")
        let buffer = PTPersistentObservabilityBuffer(fileURL: bufferURL)
        let recorder = PTObservabilityRecorder(persistentBuffer: buffer)
        await recorder.record(event: PTObservabilityEvent(name: "demo.event", attributes: ["token": "secret"]))
        await recorder.record(metric: PTObservabilityMetric(name: "demo.metric", value: 1))
        let span = await recorder.startSpan(name: "demo.span")
        await span.setAttribute("checkout", for: "flow")
        await span.end()
        let records = await recorder.snapshot()
        let flushed = await buffer.flush(to: [PTLoggingObservabilitySink()])
        return "Observability OK · records: \(records.count) · flushed: \(flushed) · persistent buffer ready"
    }
}

@MainActor
private final class PTWebBridgeInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        let script = PTWebScriptBootstrap(methods: ["ping"]).source()
        return "WebBridge OK · bootstrap bytes: \(script.utf8.count) · reply boundary ready"
    }
}

@MainActor
private final class PTMapInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        let coordinate = PTMapCoordinate(latitude: 31.2304, longitude: 121.4737)
        let url = PTMapService().externalMapURL(provider: .apple, destination: coordinate)
        return "MapKit OK · coordinate: \(coordinate.latitude),\(coordinate.longitude) · URL: \(url != nil)"
    }
}

@MainActor
private final class PTIntegrityInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        let service = PTAppIntegrityService()
        return "Integrity capability: \(String(describing: service.capability)) · real device check remains explicit"
    }
}

@MainActor
private final class PTRemoteConfigurationInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        let key = PTConfigKey(name: "demo.enabled", defaultValue: true)
        let store = PTConfigurationStore(defaults: [key.name: try JSONEncoder().encode(true)])
        let snapshot = try await store.refresh()
        let value = try snapshot.value(for: key)
        let source = snapshot.source(for: key.name)?.rawValue ?? "default"
        return "Remote Config OK · demo.enabled: \(value) · source: \(source) · LKG boundary ready"
    }
}

@MainActor
private final class PTRealtimeInfrastructureDemoViewController: PTApplicationInfrastructureDemoViewController {
    override func runModuleCheck() async throws -> String {
        var parser = PTSSEParser()
        _ = parser.consume("retry: 1000")
        _ = parser.consume("data: ping")
        let event = parser.finish()
        let subscription = PTRealtimeSubscription(topic: "demo")
        return "Realtime OK · event: \(event?.data ?? "none") · retry: \(parser.reconnectDelay != nil) · subscription: \(subscription.id)"
    }
}

private struct PTDemoDatabaseRow: Decodable, Sendable {
    let id: Int64
    let name: String
}

private actor PTDemoAuthCredentialStore: PTAuthCredentialStore {
    private var token: PTAuthToken?
    func loadToken() async throws -> PTAuthToken? { token }
    func saveToken(_ token: PTAuthToken) async throws { self.token = token }
    func removeToken() async throws { token = nil }
}

private actor PTDemoAuthRemoteProvider: PTAuthRemoteProvider {
    private(set) var refreshCount = 0
    func refresh(token: PTAuthToken) async throws -> PTAuthToken {
        refreshCount += 1
        return PTAuthToken(accessToken: "fresh", refreshToken: token.refreshToken, expiresAt: .distantFuture)
    }
}

private struct PTDemoSyncRemote: PTSyncRemoteAdapter {
    func push(_ mutation: PTSyncMutation) async throws {}
    func pull(cursor: String?) async throws -> PTSyncPullPage {
        PTSyncPullPage(mutations: [], nextCursor: cursor, hasMore: false)
    }
}

// English: Network speed demos require explicit endpoints and never ship a built-in public server.
// Español: Los demos de velocidad requieren endpoints explícitos y nunca incluyen un servidor público integrado.
// 中文：测速 Demo 必须显式输入 endpoint，不内置生产公共服务器。
@MainActor
private final class PT5_61NetworkSpeedDemoViewController: PTBaseViewController {
    private let downloadField = UITextField()
    private let uploadField = UITextField()
    private let statusLabel = UILabel()
    private var task: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Network Speed Test"
        configureView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        task?.cancel()
        task = nil
    }

    private func configureView() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        downloadField.placeholder = "Download URL"
        uploadField.placeholder = "Upload URL"
        downloadField.borderStyle = .roundedRect
        uploadField.borderStyle = .roundedRect
        statusLabel.numberOfLines = 0
        statusLabel.text = "请输入测试服务地址"
        let button = UIButton(type: .system)
        button.setTitle("Start / Cancel", for: .normal)
        button.addTarget(self, action: #selector(startOrCancel), for: .touchUpInside)
        [downloadField, uploadField, button, statusLabel].forEach(stack.addArrangedSubview)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
    }

    @objc private func startOrCancel() {
        if task != nil {
            task?.cancel()
            task = nil
            Task { await PTNetworkSpeedTester.shared.cancel() }
            statusLabel.text = "已取消"
            return
        }
        guard let downloadURL = URL(string: downloadField.text ?? ""),
              let uploadURL = URL(string: uploadField.text ?? "") else {
            statusLabel.text = "请输入有效的 http/https URL"
            return
        }
        let configuration = PTNetworkSpeedTestConfiguration(downloadURL: downloadURL,
                                                             uploadURL: uploadURL)
        task = Task { [weak self] in
            do {
                let stream = await PTNetworkSpeedTester.shared.start(configuration: configuration)
                for try await snapshot in stream {
                    guard let self else { return }
                    self.statusLabel.text = "\(snapshot.phase)  \(snapshot.megabitsPerSecond) Mbps"
                }
            } catch {
                self?.statusLabel.text = error.localizedDescription
            }
            self?.task = nil
        }
    }
}

// English: Ping demo exposes resolving, success, failure and stop through the typed session state.
// Español: El demo de ping expone resolución, éxito, fallo y parada mediante el estado tipado de la sesión.
// 中文：Ping Demo 通过类型化 Session 状态展示解析、成功、失败和停止。
@MainActor
private final class PT5_61PingDemoViewController: PTBaseViewController {
    private let hostField = UITextField()
    private let statusLabel = UILabel()
    private let session = PTPingSession()
    private var task: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Ping Session"
        hostField.placeholder = "Host or IP"
        hostField.text = "example.com"
        hostField.borderStyle = .roundedRect
        statusLabel.numberOfLines = 0
        let button = UIButton(type: .system)
        button.setTitle("Start / Stop", for: .normal)
        button.addTarget(self, action: #selector(startOrStop), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [hostField, button, statusLabel])
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        task?.cancel()
        Task { await session.stop() }
    }

    @objc private func startOrStop() {
        if task != nil {
            task?.cancel()
            task = nil
            Task { await session.stop() }
            statusLabel.text = "stopped"
            return
        }
        let host = hostField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !host.isEmpty else {
            statusLabel.text = "请输入 Host"
            return
        }
        let pingSession = session
        task = Task { [weak self, pingSession] in
            let stream = await pingSession.start(host: host)
            do {
                for try await response in stream {
                    guard let self else { return }
                    self.statusLabel.text = "success  \(response.responseTime)"
                }
            } catch {
                self?.statusLabel.text = error.localizedDescription
            }
            self?.task = nil
        }
    }
}

// English: Demonstrates independent selection insets, content insets and content offset.
// Español: Demuestra insets de selección, insets de contenido y offset de contenido independientes.
// 中文：演示选中背景内缩、项目内容内边距和项目内容偏移彼此独立。
@MainActor
private final class PTTabBarInsetsDemoViewController: PTBaseViewController {
    // English: Keep every sizing contract visible in one horizontally browsable demo.
    // Español: Mantiene cada contrato de tamaño visible en un único demo desplazable horizontalmente.
    // 中文：在一个可横向浏览的 Demo 中集中展示全部尺寸契约。
    private let modeControl = UISegmentedControl(items: [
        "Legacy", "Selection", "Content +", "Content −", "Vertical", "Horizontal",
        "Offset", "Combined", "Per-item", "Badge", "Mini", "Lottie"
    ])
    private let modeScrollView = UIScrollView()
    private let descriptionLabel = UILabel()
    private let actualSizeLabel = UILabel()
    private let previewContainer = UIView()
    private var previewBar: PTTabBarView?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "TabBar Item Insets"
        modeScrollView.showsHorizontalScrollIndicator = false
        modeScrollView.alwaysBounceHorizontal = true
        modeScrollView.addSubview(modeControl)
        modeControl.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(900)
            make.height.equalTo(32)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        actualSizeLabel.numberOfLines = 0
        actualSizeLabel.textAlignment = .center
        actualSizeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        modeControl.selectedSegmentIndex = 0
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [modeScrollView, descriptionLabel, actualSizeLabel, previewContainer])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        modeScrollView.snp.makeConstraints { make in
            make.height.equalTo(36)
        }
        previewContainer.snp.makeConstraints { make in
            make.height.equalTo(CGFloat.kTabbarHeight_Total)
        }
        rebuildPreview()
    }

    @objc private func modeChanged() {
        rebuildPreview()
    }

    // English: Rebuild only the demo preview; the production TabBar API remains unchanged.
    // Español: Reconstruye solo la vista previa del demo; la API de producción del TabBar no cambia.
    // 中文：只重建 Demo 预览，不改变生产 TabBar API。
    private func rebuildPreview() {
        previewBar?.removeFromSuperview()

        let mode = modeControl.selectedSegmentIndex
        let layout: PTTabBarLayoutAppearance
        let itemInsets: UIEdgeInsets?
        let badge: PTBadgeContent?
        let minimized: Bool
        let lottie: Bool
        switch mode {
        case 0:
            layout = PTTabBarLayoutAppearance(tabBottomSpacing: 10, tabSelectedMetail: true, tabTopSpacing: 10)
            itemInsets = nil
            badge = nil
            minimized = false
            lottie = false
            descriptionLabel.text = "Legacy slot spacing remains unchanged; content size uses the zero-inset contract."
        case 1:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabSelectedMetailInsets: UIEdgeInsets(top: 10, left: 6, bottom: 10, right: 6))
            itemInsets = nil
            badge = nil
            minimized = false
            lottie = false
            descriptionLabel.text = "Selection background changes; content and title sizes stay unchanged."
        case 2:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentInsets: UIEdgeInsets(top: 4, left: 4, bottom: 2, right: 4))
            itemInsets = nil
            badge = nil
            minimized = false
            lottie = false
            descriptionLabel.text = "Positive insets shrink the real media/custom content view; the title is independent."
        case 3:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentInsets: UIEdgeInsets(top: -2, left: -2, bottom: -2, right: -2))
            itemInsets = nil
            badge = nil
            minimized = false
            lottie = false
            descriptionLabel.text = "Negative insets expand the real content view, capped at the safe maximum scale."
        case 4:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentInsets: UIEdgeInsets(top: 6, left: 0, bottom: 4, right: 0))
            itemInsets = nil
            badge = nil
            minimized = false
            lottie = false
            descriptionLabel.text = "Vertical content insets change height without changing horizontal content size."
        case 5:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentInsets: UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6))
            itemInsets = nil
            badge = nil
            minimized = false
            lottie = false
            descriptionLabel.text = "Horizontal content insets change width without changing vertical content size."
        case 6:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentOffset: UIOffset(horizontal: 0, vertical: -3))
            itemInsets = nil
            badge = nil
            minimized = false
            lottie = false
            descriptionLabel.text = "Content offset moves the complete content group without resizing it."
        case 7:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentInsets: UIEdgeInsets(top: 3, left: 4, bottom: 2, right: 4),
                                               tabItemContentOffset: UIOffset(horizontal: 0, vertical: -2),
                                               tabSelectedMetailInsets: UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6))
            itemInsets = nil
            badge = nil
            minimized = false
            lottie = false
            descriptionLabel.text = "Selection, actual content size and translation are applied by separate layers."
        case 8:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue)
            itemInsets = UIEdgeInsets(top: 5, left: 7, bottom: 1, right: 3)
            badge = nil
            minimized = false
            lottie = false
            descriptionLabel.text = "One item overrides the global content configuration without changing other items."
        case 9:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentInsets: UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3))
            itemInsets = nil
            badge = .number(8)
            minimized = false
            lottie = false
            descriptionLabel.text = "Badge placement follows the resolved content width instead of the legacy base slot."
        case 10:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabbarMiniSize: 56,
                                               tabItemContentInsets: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))
            itemInsets = nil
            badge = nil
            minimized = true
            lottie = false
            descriptionLabel.text = "Mini mode fits the resolved content into the mini container without a size jump."
        default:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentInsets: UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2))
            itemInsets = nil
            badge = nil
            minimized = false
            lottie = true
            descriptionLabel.text = "Lottie content uses the same resolved size and inset pipeline as raster content."
        }

        let appearance = PTTabBarAppearance(normalColor: .secondaryLabel,
                                             selectedColor: .systemBlue,
                                             layout: layout)
        let bar = PTTabBarView(frame: .zero, appearance: appearance)
        let configs = [
            PTTabBarItemConfig(title: "Home",
                               content: PTTabBarImageContent(normal: demoImage(systemName: "house"),
                                                             selected: demoImage(systemName: "house.fill"),
                                                             appearance: appearance),
                               viewController: UIViewController(),
                               contentInsets: mode == 8 ? itemInsets : nil),
            PTTabBarItemConfig(title: "List",
                               content: lottie
                                   ? PTTabBarImageContent(normal: "camera", selected: "camera", appearance: appearance)
                                   : PTTabBarImageContent(normal: demoImage(systemName: "list.bullet"),
                                                          selected: demoImage(systemName: "list.bullet.rectangle.fill"),
                                                          appearance: appearance),
                               viewController: UIViewController()),
            PTTabBarItemConfig(title: "Profile",
                               content: PTTabBarImageContent(normal: demoImage(systemName: "person"),
                                                             selected: demoImage(systemName: "person.fill"),
                                                             appearance: appearance),
                               viewController: UIViewController())
        ]
        bar.setup(configs: configs)
        previewContainer.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        previewContainer.layoutIfNeeded()
        bar.layoutIfNeeded()
        if let badge {
            bar.badge(index: 1, content: badge)
        }
        if minimized {
            bar.toggleMinimize(isMinimized: true, selectedIndex: 1)
            bar.layoutIfNeeded()
        }
        let sizes = bar.items.map { item in
            let size = item.imageContent.bounds.size
            return String(format: "%d×%d", Int(size.width.rounded()), Int(size.height.rounded()))
        }.joined(separator: "  /  ")
        actualSizeLabel.text = "Actual content.view size: " + sizes
        previewBar = bar
    }

    private func demoImage(systemName: String) -> UIImage {
        UIImage(systemName: systemName) ?? UIImage()
    }
}

// English: Demonstrates gradient backgrounds behind UILabel and UIImageView content.
// Español: Demuestra fondos degradados detrás del contenido de UILabel y UIImageView.
// 中文：演示 UILabel 和 UIImageView 内容后方的渐变背景。
@MainActor
private final class PTGradientRenderingDemoViewController: PTBaseViewController {
    private let label = UILabel()
    private let imageView = UIImageView()
    private let borderSwitch = UISwitch()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Gradient Rendering"

        label.text = "Visible UILabel text"
        label.textAlignment = .center
        label.textColor = .white
        imageView.image = PTSymbolResolver.image(.photo)?.withTintColor(.white, renderingMode: .alwaysOriginal)
        imageView.contentMode = .scaleAspectFit

        let borderLabel = UILabel()
        borderLabel.text = "Border"
        borderSwitch.isOn = true
        borderSwitch.addTarget(self, action: #selector(renderGradients), for: .valueChanged)
        let borderRow = UIStackView(arrangedSubviews: [borderLabel, borderSwitch])
        borderRow.axis = .horizontal
        borderRow.distribution = .equalSpacing

        let stack = UIStackView(arrangedSubviews: [label, imageView, borderRow])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 18
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.centerY.equalToSuperview()
        }
        label.snp.makeConstraints { $0.height.equalTo(56) }
        imageView.snp.makeConstraints { $0.height.equalTo(120) }
        renderGradients()
    }

    @objc private func renderGradients() {
        let borderWidth: CGFloat = borderSwitch.isOn ? 2 : 0
        label.superGradient(bgType: .LeftToRight,
                            bgColors: [.systemBlue, .systemPurple],
                            borderType: borderWidth > 0 ? .LeftToRight : nil,
                            borderColors: borderWidth > 0 ? [.white, .systemGray] : nil,
                            borderWidth: borderWidth,
                            radius: 14)
        imageView.superGradient(bgType: .TopToBottom,
                                bgColors: [.systemOrange, .systemRed],
                                borderType: borderWidth > 0 ? .LeftToRight : nil,
                                borderColors: borderWidth > 0 ? [.white, .systemYellow] : nil,
                                borderWidth: borderWidth,
                                radius: 20)
    }
}

// English: This lab compares structural and content-only Diffable refreshes with stable identities.
// Español: Este laboratorio compara refrescos estructurales y de contenido con identidades Diffable estables.
// 中文：这个实验页使用稳定身份对比结构刷新和纯内容刷新。
@MainActor
private final class PTCollectionRefreshDemoModel {
    let id: String
    let title: String
    var isSelected = false

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

// English: A Sendable value snapshot lets the lab exercise value and external data ownership.
// Español: Un snapshot de valor Sendable permite probar propiedad de datos por valor y externa.
// 中文：Sendable 值快照用于演示值类型和外部数据源所有权。
private struct PTCollectionRefreshValueModel: Sendable {
    let id: String
    let title: String
    var isSelected: Bool
}

// English: Box the Sendable value for PTRows' legacy AnyObject dataModel slot.
// Español: Envuelve el valor Sendable para el campo heredado AnyObject de PTRows.
// 中文：将 Sendable 值包装进 PTRows 旧版 AnyObject dataModel 槽位。
private final class PTCollectionRefreshValueBox: NSObject {
    let value: PTCollectionRefreshValueModel

    init(_ value: PTCollectionRefreshValueModel) {
        self.value = value
    }
}

// English: A tiny native cell keeps the refresh lab independent from business cell implementations.
// Español: Una celda nativa pequeña mantiene el laboratorio independiente de las celdas de negocio.
// 中文：使用轻量原生 Cell，让实验页不依赖业务 Cell。
@MainActor
private final class PTCollectionRefreshLabCell: PTBaseNormalCell {
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    // English: Render a value snapshot so visible-cell reconfiguration does not need a new cell.
    // Español: Renderiza un snapshot de valor para que la reconfiguración visible no cree otra celda.
    // 中文：渲染值快照，让可见 Cell 更新时无需重新创建。
    func render(title: String, isSelected: Bool) {
        titleLabel.text = isSelected ? "✓  \(title)" : title
        titleLabel.textColor = isSelected ? .white : .label
        contentView.backgroundColor = isSelected ? .systemBlue : .secondarySystemBackground
    }

    override func reconfigureContent(with context: PTCollectionCellContext) -> Bool {
        guard let model = context.row.dataModel as? PTCollectionRefreshValueBox else { return false }
        render(title: model.value.title, isSelected: model.value.isSelected)
        return true
    }
}

// English: The Refresh Lab provides a reproducible path for content, section, row and structure updates.
// Español: El laboratorio ofrece un flujo reproducible para actualizar contenido, secciones, filas y estructura.
// 中文：Refresh Lab 提供内容、Section、Row 和结构更新的固定复现路径。
@MainActor
private final class PTCollectionRefreshLabViewController: PTBaseViewController {
    private enum RefreshMode: Int, CaseIterable {
        case replace
        case sections
        case rows
        case reconfigure
        case item
        case sectionContent
        case replaceCell

        var title: String {
            switch self {
            case .replace: return "Replace"
            case .sections: return "Sections"
            case .rows: return "Rows"
            case .reconfigure: return "Reconfigure"
            case .item: return "Item"
            case .sectionContent: return "Section Content"
            case .replaceCell: return "Replace Cell"
            }
        }
    }

    private enum DataMode: Int, CaseIterable {
        case reference
        case value
        case external
        case store

        var title: String {
            switch self {
            case .reference: return "Ref"
            case .value: return "Value"
            case .external: return "External"
            case .store: return "Store"
            }
        }
    }

    private let modeControl = UISegmentedControl(items: RefreshMode.allCases.map(\.title))
    private let dataModeControl = UISegmentedControl(items: DataMode.allCases.map(\.title))
    private let statusLabel = UILabel()
    private let collectionView: PTCollectionView
    private var models: [[PTCollectionRefreshDemoModel]] = (0..<3).map { section in
        (0..<3).map { row in
            PTCollectionRefreshDemoModel(id: "refresh-\(section)-\(row)", title: "Section \(section) · Item \(row)")
        }
    }
    private var valueModels: [[PTCollectionRefreshValueModel]] = (0..<3).map { section in
        (0..<3).map { row in
            PTCollectionRefreshValueModel(id: "refresh-\(section)-\(row)",
                                          title: "Section \(section) · Item \(row)",
                                          isSelected: false)
        }
    }
    private var externalSelection = Set<String>()
    private var providerCallCount = 0
    private var configureCallCount = 0
    private var operationStartedAt: CFTimeInterval?
    private var lastOperationLatency: TimeInterval = 0

    init() {
        let configuration = PTCollectionViewConfig()
        configuration.viewType = .Normal
        configuration.itemHeight = 56
        configuration.cellLeadingSpace = 12
        configuration.cellTrailingSpace = 8
        configuration.contentTopSpace = 12
        configuration.contentBottomSpace = 12
        collectionView = PTCollectionView(viewConfig: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Diffable Refresh Lab"
        view.backgroundColor = .systemBackground
        modeControl.selectedSegmentIndex = RefreshMode.item.rawValue
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        dataModeControl.selectedSegmentIndex = DataMode.reference.rawValue
        dataModeControl.addTarget(self, action: #selector(dataModeChanged), for: .valueChanged)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Stress", style: .plain, target: self, action: #selector(runStress)),
            UIBarButtonItem(title: "YD Sequence", style: .plain, target: self, action: #selector(runYDSearchSideSequence))
        ]
        statusLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 2
        statusLabel.accessibilityTraits = .updatesFrequently

        view.addSubview(modeControl)
        view.addSubview(dataModeControl)
        view.addSubview(statusLabel)
        view.addSubview(collectionView)
        modeControl.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
        }
        dataModeControl.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.top.equalTo(modeControl.snp.bottom).offset(8)
        }
        statusLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(12)
            make.top.equalTo(dataModeControl.snp.bottom).offset(6)
        }
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(statusLabel.snp.bottom).offset(6)
        }

        collectionView.contentCollectionView.register(PTCollectionRefreshLabCell.self, forCellWithReuseIdentifier: "PTCollectionRefreshLabCell")
        collectionView.cellInCollectionV2 = { [weak self] collectionView, context in
            self?.providerCallCount += 1
            self?.updateStatus()
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PTCollectionRefreshLabCell", for: context.indexPath) as? PTCollectionRefreshLabCell else {
                return nil
            }
            return cell
        }
        collectionView.configureCell = { [weak self] _, cell, context in
            guard let self,
                  let cell = cell as? PTCollectionRefreshLabCell,
                  let model = self.displayModel(for: context) else { return }
            self.configureCallCount += 1
            self.updateStatus()
            cell.render(title: model.title, isSelected: model.isSelected)
        }
        collectionView.collectionDidSelect = { [weak self] _, _, indexPath in
            self?.select(indexPath)
        }
        updateStatus()
        beginLabOperation()
        collectionView.showCollectionDetail(collectionData: makeSections(), animated: false)
        scheduleLabCompletion()
    }

    private func updateStatus() {
        statusLabel.text = "Provider: \(providerCallCount)  Configure: \(configureCallCount)\n" +
            "Apply: \(collectionView.snapshotApplyCount)  Pending: \(collectionView.pendingUpdateCount)  " +
            "Latency: \(String(format: "%.3f", lastOperationLatency))s"
    }

    private func beginLabOperation() {
        operationStartedAt = CACurrentMediaTime()
        updateStatus()
    }

    private func finishLabOperation() {
        if let operationStartedAt {
            lastOperationLatency = max(0, CACurrentMediaTime() - operationStartedAt)
        }
        self.operationStartedAt = nil
        updateStatus()
    }

    private func scheduleLabCompletion() {
        PTMainActorBridge.after(0.15) { [weak self] in
            self?.finishLabOperation()
        }
    }

    private func makeSections() -> [PTSection] {
        valueSnapshots().enumerated().map { sectionIndex, sectionModels in
            let rows = sectionModels.map { model in
                let row = PTRows(title: model.title,
                                 ID: "PTCollectionRefreshLabCell",
                                 diffId: model.id,
                                 dataModel: PTCollectionRefreshValueBox(model))
                row.cellClass = PTCollectionRefreshLabCell.self
                return row
            }
            return PTSection(identifier: "refresh-section-\(sectionIndex)", rows: rows)
        }
    }

    private func valueSnapshots() -> [[PTCollectionRefreshValueModel]] {
        let mode = DataMode(rawValue: dataModeControl.selectedSegmentIndex) ?? .reference
        switch mode {
        case .reference:
            return models.map { section in
                section.map {
                    PTCollectionRefreshValueModel(id: $0.id,
                                                  title: $0.title,
                                                  isSelected: $0.isSelected)
                }
            }
        case .value, .store:
            return valueModels
        case .external:
            return (0..<3).map { section in
                (0..<3).map { row in
                    let id = "refresh-\(section)-\(row)"
                    return PTCollectionRefreshValueModel(id: id,
                                                         title: "Section \(section) · Item \(row)",
                                                         isSelected: externalSelection.contains(id))
                }
            }
        }
    }

    private func currentRow(at indexPath: IndexPath) -> PTRows? {
        guard valueSnapshots().indices.contains(indexPath.section) else { return nil }
        return makeSections()[indexPath.section].rows?[safe: indexPath.item]
    }

    // English: Read external selection state at configuration time instead of copying it into the row first.
    // Español: Lee el estado externo al configurar la celda en lugar de copiarlo primero en la fila.
    // 中文：在配置 Cell 时直接读取外部选中状态，不先复制进 Row。
    private func displayModel(for context: PTCollectionCellContext) -> PTCollectionRefreshValueModel? {
        let mode = DataMode(rawValue: dataModeControl.selectedSegmentIndex) ?? .reference
        if mode == .external {
            return PTCollectionRefreshValueModel(id: context.row.diffId,
                                                  title: context.row.title,
                                                  isSelected: externalSelection.contains(context.row.diffId))
        }
        return (context.row.dataModel as? PTCollectionRefreshValueBox)?.value
    }

    private func syncSelection(at indexPath: IndexPath) {
        let snapshots = valueSnapshots()
        guard snapshots.indices.contains(indexPath.section),
              snapshots[indexPath.section].indices.contains(indexPath.item) else { return }
        let selectedID = snapshots[indexPath.section][indexPath.item].id
        let isSelected = !snapshots[indexPath.section][indexPath.item].isSelected
        let mode = DataMode(rawValue: dataModeControl.selectedSegmentIndex) ?? .reference
        switch mode {
        case .reference:
            models[indexPath.section].forEach { $0.isSelected = false }
            models[indexPath.section][indexPath.item].isSelected = isSelected
        case .value, .store:
            valueModels[indexPath.section] = valueModels[indexPath.section].enumerated().map { index, model in
                PTCollectionRefreshValueModel(id: model.id,
                                              title: model.title,
                                              isSelected: index == indexPath.item ? isSelected : false)
            }
        case .external:
            externalSelection.subtract(snapshots[indexPath.section].map(\.id))
            if isSelected { externalSelection.insert(selectedID) }
        }
    }

    private func select(_ indexPath: IndexPath) {
        let snapshots = valueSnapshots()
        guard snapshots.indices.contains(indexPath.section),
              snapshots[indexPath.section].indices.contains(indexPath.item) else { return }
        syncSelection(at: indexPath)
        beginLabOperation()

        let mode = RefreshMode(rawValue: modeControl.selectedSegmentIndex) ?? .item
        let dataMode = DataMode(rawValue: dataModeControl.selectedSegmentIndex) ?? .reference
        switch mode {
        case .replace:
            collectionView.showCollectionDetail(collectionData: makeSections())
        case .sections:
            collectionView.reloadSections(at: [indexPath.section])
        case .rows:
            let row = currentRow(at: indexPath)
            if let row { collectionView.reloadRows([row], in: indexPath.section) }
        case .reconfigure:
            if dataMode == .external {
                collectionView.reconfigureSections(at: [indexPath.section])
            } else {
                collectionView.updateRows(makeSections()[indexPath.section].rows ?? [], reload: false)
                collectionView.reconfigureSections(at: [indexPath.section])
            }
        case .item:
            if dataMode == .external {
                collectionView.reloadItemContent(at: [indexPath])
            } else if let row = currentRow(at: indexPath) {
                collectionView.updateItemContent(at: indexPath, using: row)
            }
        case .sectionContent:
            if dataMode == .external {
                collectionView.reloadSectionContent(at: [indexPath.section])
            } else {
                collectionView.updateRows(makeSections()[indexPath.section].rows ?? [], reload: false)
                collectionView.reloadSectionContent(at: [indexPath.section])
            }
        case .replaceCell:
            collectionView.reloadItemCell(at: [indexPath])
        }
        scheduleLabCompletion()
    }

    @objc private func modeChanged() { }

    @objc private func dataModeChanged() {
        beginLabOperation()
        collectionView.showCollectionDetail(collectionData: makeSections(), animated: false)
        scheduleLabCompletion()
    }

    @objc private func runStress() {
        beginLabOperation()
        for step in 0..<12 {
            let snapshots = valueSnapshots()
            let section = step % snapshots.count
            let row = step % snapshots[section].count
            let indexPath = IndexPath(item: row, section: section)
            syncSelection(at: indexPath)
            if DataMode(rawValue: dataModeControl.selectedSegmentIndex) == .external {
                collectionView.reloadItemContent(at: [indexPath])
            } else if let currentRow = currentRow(at: indexPath) {
                collectionView.updateItemContent(at: indexPath, using: currentRow)
            }
        }
        scheduleLabCompletion()
    }

    @objc private func runYDSearchSideSequence() {
        beginLabOperation()
        let sequence = [
            IndexPath(item: 0, section: 0),
            IndexPath(item: 0, section: 1),
            IndexPath(item: 0, section: 2),
            IndexPath(item: 1, section: 2)
        ]
        for (offset, indexPath) in sequence.enumerated() {
            PTMainActorBridge.after(TimeInterval(offset) * 0.15) { [weak self] in
                guard let self else { return }
                let snapshots = self.valueSnapshots()
                guard snapshots.indices.contains(indexPath.section),
                      snapshots[indexPath.section].indices.contains(indexPath.item) else { return }
                self.syncSelection(at: indexPath)
                if DataMode(rawValue: self.dataModeControl.selectedSegmentIndex) == .external {
                    self.collectionView.reloadItemContent(at: [indexPath])
                } else if let row = self.currentRow(at: indexPath) {
                    self.collectionView.updateItemContent(at: indexPath, using: row)
                }
                if offset == sequence.count - 1 {
                    self.finishLabOperation()
                }
            }
        }
    }
}

// English: Show the shared image placeholder and display-size pipeline with local fixture data.
// Español: Muestra el placeholder compartido y el canal de tamaño de pantalla con datos locales.
// 中文：使用本地样例展示统一占位图和显示尺寸图片加载管线。
@MainActor
private final class PTImageClarityDemoViewController: PTBaseViewController {
    private let stackView = UIStackView()
    private var imageViews: [UIImageView] = []
    private var didLoadImages = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Image Clarity"
        view.backgroundColor = .systemBackground

        let scrollView = UIScrollView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.addArrangedSubview(makeDescription())
        stackView.addArrangedSubview(makeImageRow(title: "72pt display target", height: 72))
        stackView.addArrangedSubview(makeImageRow(title: "144pt display target", height: 144))
        stackView.addArrangedSubview(makeImageRow(title: "216pt display target", height: 216))

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(20)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !didLoadImages else { return }
        let imageData = UIImage(named: "DemoImage")?.pngData()
        guard let imageData else { return }
        didLoadImages = true
        imageViews.forEach { imageView in
            imageView.loadImage(contentData: imageData,
                                emptyImage: PTSymbolResolver.image(.photo))
        }
    }

    private func makeDescription() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.text = "占位图立即显示，布局稳定后按实际显示尺寸和屏幕比例解码。\nPlaceholder first, display-sized decoding after layout."
        return label
    }

    private func makeImageRow(title: String, height: CGFloat) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.text = title
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        imageView.accessibilityLabel = title
        imageViews.append(imageView)

        container.addSubview(label)
        container.addSubview(imageView)
        label.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        imageView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(height)
        }
        return container
    }
}

// English: Demonstrate multiline attachments, baseline offsets and wrapped actions with real UIKit bounds.
// Español: Demuestra adjuntos multilínea, desplazamientos de línea base y acciones envueltas con bounds UIKit reales.
// 中文：使用真实 UIKit bounds 展示多行附件、基线偏移和换行 Action。
@MainActor
private final class PTRichTextAttachmentMultilineDemoViewController: PTBaseViewController {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let previewScrollView = UIScrollView()
    private let previewContentView = UIView()
    private let richContainer = UIView()
    private let richLabel = UILabel()
    private let plainLabel = UILabel()
    private let statusLabel = UILabel()
    private let heightControl = UISegmentedControl(items: ["40", "64", "80", "120"])
    private let widthControl = UISegmentedControl(items: ["280", "366", "430"])
    private let offsetControl = UISegmentedControl(items: ["-7", "0", "+7"])
    private let breakControl = UISegmentedControl(items: ["Word", "Character"])
    private let actionID = PTTextActionID("rich-text-rule")
    private lazy var actionRegistry: PTTextActionRegistry = {
        let registry = PTTextActionRegistry()
        registry.register(actionID) { [weak self] _ in
            self?.statusLabel.text = "Action callback: rich-text-rule"
        }
        return registry
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Rich Text Attachment"
        view.backgroundColor = .systemBackground
        configureViews()
        updatePreview()
    }

    private func configureViews() {
        let description = UILabel()
        description.numberOfLines = 0
        description.font = .preferredFont(forTextStyle: .footnote)
        description.textColor = .secondaryLabel
        description.text = "验证 24×24 图片在 40/64/80/120pt 容器、-7/0/+7 基线和多行 Action 下的实际布局。\nValidate real UIKit layout for inline attachments, wrapping and action hit testing."

        heightControl.selectedSegmentIndex = 2
        widthControl.selectedSegmentIndex = 1
        offsetControl.selectedSegmentIndex = 0
        breakControl.selectedSegmentIndex = 0
        [heightControl, widthControl, offsetControl, breakControl].forEach {
            $0.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        }

        richLabel.numberOfLines = 0
        richLabel.font = .systemFont(ofSize: 14)
        richLabel.isUserInteractionEnabled = true
        richLabel.backgroundColor = .secondarySystemBackground
        richLabel.accessibilityLabel = "Rich text attachment preview"
        plainLabel.numberOfLines = 0
        plainLabel.font = .systemFont(ofSize: 14)
        plainLabel.textColor = .secondaryLabel
        plainLabel.backgroundColor = .tertiarySystemBackground
        statusLabel.numberOfLines = 0
        statusLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = .secondaryLabel

        let heightRow = makeControlRow(title: "Height", control: heightControl)
        let widthRow = makeControlRow(title: "Width", control: widthControl)
        let offsetRow = makeControlRow(title: "Baseline", control: offsetControl)
        let breakRow = makeControlRow(title: "Break", control: breakControl)

        previewScrollView.alwaysBounceHorizontal = true
        previewScrollView.showsHorizontalScrollIndicator = true
        previewScrollView.addSubview(previewContentView)
        previewContentView.addSubview(richContainer)
        richContainer.addSubview(richLabel)
        richLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        previewContentView.snp.makeConstraints { make in
            make.edges.equalTo(previewScrollView.contentLayoutGuide)
            make.height.equalTo(previewScrollView.frameLayoutGuide)
            make.width.equalTo(366)
        }
        richContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(80)
        }

        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.addArrangedSubview(description)
        stackView.addArrangedSubview(heightRow)
        stackView.addArrangedSubview(widthRow)
        stackView.addArrangedSubview(offsetRow)
        stackView.addArrangedSubview(breakRow)
        stackView.addArrangedSubview(previewScrollView)
        stackView.addArrangedSubview(plainLabel)
        stackView.addArrangedSubview(statusLabel)
        previewScrollView.snp.makeConstraints { make in
            make.height.equalTo(120)
        }

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-32)
        }
    }

    @objc private func controlChanged() {
        updatePreview()
    }

    private func updatePreview() {
        let width = [280, 366, 430][max(0, min(widthControl.selectedSegmentIndex, 2))]
        let height = [40, 64, 80, 120][max(0, min(heightControl.selectedSegmentIndex, 3))]
        let offset = [-7, 0, 7][max(0, min(offsetControl.selectedSegmentIndex, 2))]
        let lineBreakMode: NSLineBreakMode = breakControl.selectedSegmentIndex == 0 ? .byWordWrapping : .byCharWrapping

        previewContentView.snp.remakeConstraints { make in
            make.edges.equalTo(previewScrollView.contentLayoutGuide)
            make.height.equalTo(previewScrollView.frameLayoutGuide)
            make.width.equalTo(width)
        }
        richContainer.snp.updateConstraints { make in
            make.height.equalTo(height)
        }
        richLabel.lineBreakMode = lineBreakMode
        let richText = makeRichText(offset: CGFloat(offset))
        richLabel.pt_apply(richText: richText,
                           actionRegistry: actionRegistry,
                           interactionMode: .actionsOnly)
        plainLabel.text = "Plain UILabel 对照：\n\(richText.plainText)"
        view.layoutIfNeeded()

        let fitted = richLabel.sizeThatFits(CGSize(width: max(1, CGFloat(width - 16)), height: 10_000))
        statusLabel.text = "bounds=\(NSCoder.string(for: richLabel.bounds))\nsizeThatFits=\(NSCoder.string(for: fitted))\nintrinsic=\(NSCoder.string(for: richLabel.intrinsicContentSize))\noffset=\(offset), break=\(lineBreakMode.rawValue)"
    }

    private func makeControlRow(title: String, control: UISegmentedControl) -> UIView {
        let row = UIStackView(arrangedSubviews: [UILabel(), control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        (row.arrangedSubviews[0] as? UILabel)?.text = title
        (row.arrangedSubviews[0] as? UILabel)?.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func makeRichText(offset: CGFloat) -> PTRichText {
        let image = UIImage(named: "DemoImage") ?? UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
        }
        let imageAttribute = PTTextAttribute.image(image,
                                                    .custom(size: CGSize(width: 24, height: 24)),
                                                    baselineOffset: offset)
        var value = PTRichText(string: "\u{FFFC}", with: [imageAttribute])
        value += PTRichText(" 标题与描述 mixed text that is intentionally long enough to wrap ",
                            with: [.font(.systemFont(ofSize: 14, weight: .bold))])
        value += PTRichText("点击规则",
                            with: [.action(actionID),
                                   .foreground(.systemBlue),
                                   .font(.systemFont(ofSize: 14))])
        return PTRichText(wrap: .embedding(value),
                          .paragraph(.lineBreakMode(.byWordWrapping)))
    }
}

// English: Demonstrate fragment-only line limits while keeping following dates, actions, and attachments intact.
// Español: Demuestra límites por fragmento y conserva intactos las fechas, acciones y adjuntos posteriores.
// 中文：展示片段级限行，同时保留后续日期、Action 和附件的完整显示。
@MainActor
private final class PTRichTextFragmentLineLimitDemoViewController: PTBaseViewController {
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let previewScrollView = UIScrollView()
    private let previewContentView = UIView()
    private let previewLabel = PTRichTextFlowLabel()
    private let statusLabel = UILabel()
    private let lineControl = UISegmentedControl(items: ["0", "1", "2", "3"])
    private let modeControl = UISegmentedControl(items: ["Word", "Char", "Clip", "Head", "Tail", "Middle"])
    private let widthControl = UISegmentedControl(items: ["120", "280", "366", "430"])
    private let languageControl = UISegmentedControl(items: ["EN", "中文", "العربية"])
    private let lengthControl = UISegmentedControl(items: ["Short", "Long"])
    private let actionID = PTTextActionID("fragment-order")
    private lazy var actionRegistry: PTTextActionRegistry = {
        let registry = PTTextActionRegistry()
        registry.register(actionID) { [weak self] event in
            self?.statusLabel.text = "Action: \(event.actionID.rawValue) / \(event.text)"
        }
        return registry
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Fragment Line Limit"
        view.backgroundColor = .systemBackground
        configureViews()
        updatePreview()
    }

    private func configureViews() {
        let description = UILabel()
        description.numberOfLines = 0
        description.font = .preferredFont(forTextStyle: .footnote)
        description.textColor = .secondaryLabel
        description.text = "仅限制订单号片段；后面的时间和图片附件不被截断。\nOnly the order fragment is limited; the date and attachment remain visible."

        lineControl.selectedSegmentIndex = 0
        modeControl.selectedSegmentIndex = 4
        widthControl.selectedSegmentIndex = 1
        languageControl.selectedSegmentIndex = 0
        lengthControl.selectedSegmentIndex = 1
        [lineControl, modeControl, widthControl, languageControl, lengthControl].forEach {
            $0.addTarget(self, action: #selector(controlChanged), for: .valueChanged)
        }

        previewLabel.numberOfLines = 0
        previewLabel.lineBreakMode = .byWordWrapping
        previewLabel.font = .systemFont(ofSize: 16)
        previewLabel.backgroundColor = .secondarySystemBackground
        previewLabel.layer.cornerRadius = 12
        previewLabel.clipsToBounds = true
        previewLabel.isUserInteractionEnabled = true

        statusLabel.numberOfLines = 0
        statusLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = .secondaryLabel

        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.addArrangedSubview(description)
        stackView.addArrangedSubview(makeControlRow(title: "Lines", control: lineControl))
        stackView.addArrangedSubview(makeControlRow(title: "Break", control: modeControl))
        stackView.addArrangedSubview(makeControlRow(title: "Width", control: widthControl))
        stackView.addArrangedSubview(makeControlRow(title: "Language", control: languageControl))
        stackView.addArrangedSubview(makeControlRow(title: "Length", control: lengthControl))

        previewScrollView.showsHorizontalScrollIndicator = true
        previewScrollView.alwaysBounceHorizontal = true
        previewScrollView.addSubview(previewContentView)
        previewContentView.addSubview(previewLabel)
        previewLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
        previewScrollView.snp.makeConstraints { make in
            make.height.equalTo(220)
        }
        stackView.addArrangedSubview(previewScrollView)
        stackView.addArrangedSubview(statusLabel)

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(16)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-32)
        }
    }

    @objc private func controlChanged() {
        updatePreview()
    }

    private func updatePreview() {
        let width = [120, 280, 366, 430][max(0, min(widthControl.selectedSegmentIndex, 3))]
        let maxLines = [0, 1, 2, 3][max(0, min(lineControl.selectedSegmentIndex, 3))]
        let mode = [NSLineBreakMode.byWordWrapping,
                    .byCharWrapping,
                    .byClipping,
                    .byTruncatingHead,
                    .byTruncatingTail,
                    .byTruncatingMiddle][max(0, min(modeControl.selectedSegmentIndex, 5))]

        previewContentView.snp.remakeConstraints { make in
            make.edges.equalTo(previewScrollView.contentLayoutGuide)
            make.height.equalTo(previewScrollView.frameLayoutGuide)
            make.width.equalTo(width)
        }
        previewLabel.semanticContentAttribute = languageControl.selectedSegmentIndex == 2 ? .forceRightToLeft : .unspecified
        PTRichTextRenderer.apply(makeRichText(maxLines: maxLines, mode: mode),
                                 to: previewLabel,
                                 actionRegistry: actionRegistry,
                                 interactionMode: .actionsOnly)
        view.layoutIfNeeded()

        #if DEBUG
        statusLabel.text = "width=\(width), maxLines=\(maxLines), mode=\(mode.rawValue)\n\(previewLabel.pt_richTextFlowDiagnosticReport())"
        #else
        statusLabel.text = "width=\(width), maxLines=\(maxLines), mode=\(mode.rawValue)"
        #endif
    }

    private func makeControlRow(title: String, control: UISegmentedControl) -> UIView {
        let row = UIStackView(arrangedSubviews: [UILabel(), control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        let titleLabel = row.arrangedSubviews.first as? UILabel
        titleLabel?.text = title
        titleLabel?.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func makeRichText(maxLines: Int, mode: NSLineBreakMode) -> PTRichText {
        let language = languageControl.selectedSegmentIndex
        let long = lengthControl.selectedSegmentIndex == 1
        let order: String
        let date: String
        switch language {
        case 1:
            order = long ? "订单号 20261024-PT-000000000000-中文测试" : "订单号 20261024"
            date = "创建时间 2026-10-24 12:34"
        case 2:
            order = long ? "رقم الطلب 20261024-PT-000000000000" : "رقم الطلب 20261024"
            date = "تاريخ الإنشاء 2026-10-24 12:34"
        default:
            order = long ? "Order 20261024-PT-000000000000-Fragment-Test" : "Order 20261024"
            date = "Created 2026-10-24 12:34"
        }

        let orderFragment = PTRichText(string: order,
                                       with: [.foreground(.label),
                                              .font(.systemFont(ofSize: 16, weight: .semibold)),
                                              .action(actionID),
                                              .numberOfLines(maxLines),
                                              .fragmentLineBreakMode(mode),
                                              .keepWithNextAttachment()])
        let image = UIImage(named: "DemoImage") ?? UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        }
        let attachment = PTRichText(string: "\u{FFFC}",
                                    with: [.image(image, .custom(size: CGSize(width: 16, height: 16)))])
        var result = orderFragment
        result += " "
        result += attachment
        result += "\n"
        result += PTRichText(date, .foreground(.secondaryLabel), .font(.systemFont(ofSize: 14)))
        return PTRichText(wrap: .embedding(result), .paragraph(.alignment(language == 2 ? .right : .left)))
    }
}

// English: Demonstrate every public input style without changing the production controls.
// Español: Demuestra cada estilo de entrada público sin modificar los controles de producción.
// 中文：展示 Input 模块的全部公开输入样式，不改变生产控件实现。
@MainActor
private final class PTInputStylesDemoViewController: PTBaseViewController {
    private let stackView = UIStackView()
    private let feedbackLabel = UILabel()
    private var effectFields: [TextFieldEffects] = []
    private weak var nativeHoshiField: PTHoshiTextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Input Styles"
        view.backgroundColor = .systemBackground
        configureContent()
    }

    private func configureContent() {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 18

        let introduction = UILabel()
        introduction.font = .preferredFont(forTextStyle: .subheadline)
        introduction.textColor = .secondaryLabel
        introduction.numberOfLines = 0
        introduction.text = "TextFieldEffects、Floating、验证码、GrowingText 和通用输入控件的完整样式目录。点击各输入框即可查看激活动画。"
        stackView.addArrangedSubview(introduction)
        stackView.addArrangedSubview(makeAppearanceControls())

        addSectionTitle("TextFieldEffects styles")
        addEffectFieldRow(title: "Akira · bottom border", field: makeAkiraField())
        addEffectFieldRow(title: "Hoshi · floating placeholder", field: makeHoshiField())
        addEffectFieldRow(title: "Isao · animated underline", field: makeIsaoField())
        addEffectFieldRow(title: "Jiro · expanding background", field: makeJiroField())
        addEffectFieldRow(title: "Kaede · sliding foreground", field: makeKaedeField())
        addEffectFieldRow(title: "Madoka · drawing border", field: makeMadokaField())
        addEffectFieldRow(title: "Minoru · glow border", field: makeMinoruField())
        addEffectFieldRow(title: "Yoko · 3D background", field: makeYokoField())
        addEffectFieldRow(title: "Yoshiko · configurable border", field: makeYoshikoField())
        addFieldRow(title: "Hoshi native variant", field: makeNativeHoshiField())

        addSectionTitle("Input utilities")
        addFieldRow(title: "PTTextField · custom spacing and right view", field: makePTTextField())
        addViewRow(title: "PTFloatingPlaseholderTextField", view: makeFloatingField(), height: 62)
        addGrowingTextRow()
        addInputBoxRows()
        addShakeRow()

        feedbackLabel.font = .preferredFont(forTextStyle: .footnote)
        feedbackLabel.textColor = .secondaryLabel
        feedbackLabel.numberOfLines = 0
        feedbackLabel.text = "输入完成状态会显示在这里 / Completion status appears here"
        stackView.addArrangedSubview(feedbackLabel)

        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(20)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-40)
        }
    }

    private func addSectionTitle(_ title: String) {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .label
        label.text = title
        label.numberOfLines = 0
        stackView.addArrangedSubview(label)
    }

    private func addFieldRow(title: String, field: UIView, height: CGFloat = 60) {
        let container = UIView()
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.text = title
        label.numberOfLines = 0

        container.addSubview(label)
        container.addSubview(field)
        label.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        field.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(height)
        }
        stackView.addArrangedSubview(container)
    }

    private func addEffectFieldRow(title: String, field: TextFieldEffects) {
        effectFields.append(field)
        addFieldRow(title: title, field: field)
    }

    // English: Expose the shared properties so every input style can be verified in one screen.
    // Español: Expone las propiedades compartidas para verificar todos los estilos en una sola pantalla.
    // 中文：在同一页面提供统一属性控制，方便验证所有输入框样式。
    private func makeAppearanceControls() -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8

        let spacing = UISegmentedControl(items: ["space 0", "space 4", "space 8", "space 16"])
        spacing.selectedSegmentIndex = 2
        spacing.addTarget(self, action: #selector(inputSpacingChanged(_:)), for: .valueChanged)

        let leading = UISegmentedControl(items: ["leading 0", "leading 12", "leading 24"])
        leading.selectedSegmentIndex = 1
        leading.addTarget(self, action: #selector(inputLeadingChanged(_:)), for: .valueChanged)

        let richTextSwitch = UISwitch()
        richTextSwitch.isOn = true
        richTextSwitch.addTarget(self, action: #selector(inputRichTextChanged(_:)), for: .valueChanged)
        let richTextRow = makeSwitchRow(title: "Rich placeholder / 富文本占位符", control: richTextSwitch)

        let rtlSwitch = UISwitch()
        rtlSwitch.addTarget(self, action: #selector(inputDirectionChanged(_:)), for: .valueChanged)
        let rtlRow = makeSwitchRow(title: "RTL layout", control: rtlSwitch)

        let fontButton = UIButton(type: .system)
        fontButton.setTitle("Toggle placeholder font", for: .normal)
        fontButton.addAction(UIAction { [weak self] _ in self?.togglePlaceholderFont() }, for: .touchUpInside)

        let colorButton = UIButton(type: .system)
        colorButton.setTitle("Toggle placeholder color", for: .normal)
        colorButton.addAction(UIAction { [weak self] _ in self?.togglePlaceholderColor() }, for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [fontButton, colorButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 8

        [spacing, leading, richTextRow, rtlRow, buttonRow].forEach { container.addArrangedSubview($0) }
        return container
    }

    private func makeSwitchRow(title: String, control: UISwitch) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        let label = UILabel()
        label.text = title
        label.textColor = .secondaryLabel
        row.addArrangedSubview(label)
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(control)
        return row
    }

    @objc private func inputSpacingChanged(_ sender: UISegmentedControl) {
        let values: [CGFloat] = [0, 4, 8, 16]
        let value = values[safe: sender.selectedSegmentIndex] ?? 8
        effectFields.forEach { $0.textAndPlaceholderSpace = value }
        nativeHoshiField?.textAndPlaceholderSpace = value
    }

    @objc private func inputLeadingChanged(_ sender: UISegmentedControl) {
        let values: [CGFloat] = [0, 12, 24]
        let value = values[safe: sender.selectedSegmentIndex] ?? 12
        effectFields.forEach { $0.leadingSpace = value }
        nativeHoshiField?.leadingSpace = value
    }

    @objc private func inputRichTextChanged(_ sender: UISwitch) {
        effectFields.forEach { field in
            field.placeholderAtt = sender.isOn ? richPlaceholder(for: field.placeholder ?? "Input") : nil
        }
        if let field = nativeHoshiField {
            field.placeholderAtt = sender.isOn ? richPlaceholder(for: field.placeholder ?? "PTHoshi") : nil
        }
    }

    @objc private func inputDirectionChanged(_ sender: UISwitch) {
        let direction: UISemanticContentAttribute = sender.isOn ? .forceRightToLeft : .forceLeftToRight
        effectFields.forEach { $0.semanticContentAttribute = direction }
        nativeHoshiField?.semanticContentAttribute = direction
    }

    private func togglePlaceholderFont() {
        effectFields.forEach { field in
            var appearance = field.inputAppearance
            appearance.placeholderFontOverride = appearance.placeholderFontOverride == nil
                ? .preferredFont(forTextStyle: .title3)
                : nil
            field.inputAppearance = appearance
        }
        if let field = nativeHoshiField {
            var appearance = field.inputAppearance
            appearance.placeholderFontOverride = appearance.placeholderFontOverride == nil
                ? .preferredFont(forTextStyle: .title3)
                : nil
            field.inputAppearance = appearance
        }
    }

    private func togglePlaceholderColor() {
        effectFields.forEach { field in
            var appearance = field.inputAppearance
            appearance.placeholderColorOverride = appearance.placeholderColorOverride == nil ? .systemPink : nil
            field.inputAppearance = appearance
        }
        if let field = nativeHoshiField {
            var appearance = field.inputAppearance
            appearance.placeholderColorOverride = appearance.placeholderColorOverride == nil ? .systemPink : nil
            field.inputAppearance = appearance
        }
    }

    private func richPlaceholder(for text: String) -> PTRichText {
        """
        \(wrap: .embedding("""
        \(text, .foreground(.systemBlue), .font(.preferredFont(forTextStyle: .footnote)))\(" · rich", .foreground(.systemOrange), .font(.preferredFont(forTextStyle: .caption1)))
        """))
        """
    }

    private func addViewRow(title: String, view: UIView, height: CGFloat) {
        addFieldRow(title: title, field: view, height: height)
    }

    private func configure(_ field: TextFieldEffects, placeholder: String) -> TextFieldEffects {
        field.placeholder = placeholder
        field.font = .preferredFont(forTextStyle: .body)
        field.placeholderFont = .preferredFont(forTextStyle: .footnote)
        field.leadingSpace = 12
        field.textAndPlaceholderSpace = 8
        field.textEditingEdges = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        field.textColor = .label
        field.backgroundColor = .secondarySystemBackground
        field.clearButtonMode = .whileEditing
        return field
    }

    private func makeAkiraField() -> TextFieldEffects {
        let field = AkiraTextField(frame: .zero)
        field.borderColor = .systemBlue
        field.placeholderColor = .secondaryLabel
        return configure(field, placeholder: "Akira")
    }

    private func makeHoshiField() -> TextFieldEffects {
        let field = HoshiTextField(frame: .zero)
        field.borderInactiveColor = .systemGray4
        field.borderActiveColor = .systemBlue
        field.placeholderColor = .secondaryLabel
        let configured = configure(field, placeholder: "Hoshi")
        configured.placeholderAtt = """
        \(wrap: .embedding("""
        \("Hoshi", .foreground(.systemBlue), .font(.preferredFont(forTextStyle: .footnote)))\(" · rich", .foreground(.systemOrange), .font(.preferredFont(forTextStyle: .footnote)))
        """))
        """
        return configured
    }

    private func makeIsaoField() -> TextFieldEffects {
        let field = IsaoTextField(frame: .zero)
        field.inactiveColor = .systemGray4
        field.activeColor = .systemBlue
        return configure(field, placeholder: "Isao")
    }

    private func makeJiroField() -> TextFieldEffects {
        let field = JiroTextField(frame: .zero)
        field.borderColor = .systemOrange
        field.placeholderColor = .secondaryLabel
        return configure(field, placeholder: "Jiro")
    }

    private func makeKaedeField() -> TextFieldEffects {
        let field = KaedeTextField(frame: .zero)
        field.foregroundColor = .systemBlue.withAlphaComponent(0.16)
        field.placeholderColor = .secondaryLabel
        return configure(field, placeholder: "Kaede")
    }

    private func makeMadokaField() -> TextFieldEffects {
        let field = MadokaTextField(frame: .zero)
        field.borderColor = .systemPurple
        field.placeholderColor = .secondaryLabel
        return configure(field, placeholder: "Madoka")
    }

    private func makeMinoruField() -> TextFieldEffects {
        let field = MinoruTextField(frame: .zero)
        field.placeholderColor = .secondaryLabel
        return configure(field, placeholder: "Minoru")
    }

    private func makeYokoField() -> TextFieldEffects {
        let field = YokoTextField(frame: .zero)
        field.foregroundColor = .systemTeal
        field.placeholderColor = .secondaryLabel
        return configure(field, placeholder: "Yoko")
    }

    private func makeYoshikoField() -> TextFieldEffects {
        let field = YoshikoTextField(frame: .zero)
        field.activeBorderColor = .systemGreen
        field.inactiveBorderColor = .systemGray4
        field.activeBackgroundColor = .systemGreen.withAlphaComponent(0.08)
        field.placeholderColor = .secondaryLabel
        return configure(field, placeholder: "Yoshiko")
    }

    private func makeNativeHoshiField() -> UIView {
        let field = PTHoshiTextField(frame: .zero)
        nativeHoshiField = field
        field.placeholder = "PTHoshiTextField"
        field.placeholderColor = .secondaryLabel
        field.placeholderFont = .preferredFont(forTextStyle: .footnote)
        field.font = .preferredFont(forTextStyle: .body)
        field.textColor = .label
        field.inputAppearance = PTInputAppearance(
            placeholderColorOverride: .secondaryLabel,
            placeholderFontOverride: .preferredFont(forTextStyle: .footnote),
            textAndPlaceholderSpace: 8,
            leadingSpace: 12,
            textEditingEdges: UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        )
        field.backgroundColor = .secondarySystemBackground
        return field
    }

    private func makePTTextField() -> UIView {
        let field = PTTextField(frame: .zero)
        field.placeholder = "PTTextField"
        field.font = .preferredFont(forTextStyle: .body)
        field.textColor = .label
        field.borderStyle = .roundedRect
        field.leftSpace = 10

        let rightConfig = PTTextCustomRightViewConfig()
        rightConfig.size = CGSize(width: 22, height: 22)
        rightConfig.rightSpace = 10
        rightConfig.image = PTSymbolResolver.image(.magnifyingglass)?.withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
        field.rightConfig = rightConfig
        return field
    }

    private func makeFloatingField() -> UIView {
        let config = PTFloatingPlaseholderConfig()
        config.containerRadius = 12
        config.borderLayerColor = .systemGray4
        config.borderLayerFloatingColor = .systemBlue
        config.normalPlaceholderColor = .secondaryLabel
        config.floatingPlaceholderColor = .systemBlue
        config.textColor = .label
        config.textFont = .preferredFont(forTextStyle: .body)
        config.normalPlaceholderFont = .preferredFont(forTextStyle: .body)
        config.floatingPlaceholderFont = .preferredFont(forTextStyle: .footnote)
        config.insidePadding = 14

        let field = PTFloatingPlaseholderTextField(config: config)
        field.configure(placeholder: "PTFloatingPlaseholderTextField")
        return field
    }

    private func addGrowingTextRow() {
        let textView = PTGrowingTextView(frame: .zero, textContainer: nil)
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textColor = .label
        textView.placeholder = "PTGrowingTextView"
        textView.placeholderColor = .secondaryLabel
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.minHeight = 96
        textView.maxHeight = 160
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 12
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.separator.cgColor
        addViewRow(title: "PTGrowingTextView · auto height", view: textView, height: 96)
    }

    private func addInputBoxRows() {
        let numberConfig = PTInputBoxConfiguration()
        numberConfig.autoShowKeyboard = false
        numberConfig.keyboardType = .numberPad
        numberConfig.inputType = .Number
        numberConfig.inputBoxHighlightedColor = .systemBlue
        addInputBoxRow(title: "PTInputBoxView · Number", config: numberConfig)

        let secureConfig = PTInputBoxConfiguration()
        secureConfig.autoShowKeyboard = false
        secureConfig.secureTextEntry = true
        secureConfig.showUnderLine = true
        secureConfig.inputBoxFinishColor = .systemGreen
        secureConfig.inputBoxHighlightedColor = .systemOrange
        addInputBoxRow(title: "PTInputBoxView · Secure + underline", config: secureConfig)

        let alphabetConfig = PTInputBoxConfiguration()
        alphabetConfig.autoShowKeyboard = false
        alphabetConfig.keyboardType = .asciiCapable
        alphabetConfig.inputType = .Alphabet
        alphabetConfig.inputBoxNumber = 6
        alphabetConfig.inputBoxWidth = 38
        alphabetConfig.customInputHolder = "•"
        addInputBoxRow(title: "PTInputBoxView · Alphabet", config: alphabetConfig)
    }

    private func addInputBoxRow(title: String, config: PTInputBoxConfiguration) {
        let inputBox = PTInputBoxView(config: config)
        inputBox.finishBlock = { [weak self] _, code in
            self?.feedbackLabel.text = "完成：\(title) → \(code)"
        }
        addViewRow(title: title, view: inputBox, height: config.inputBoxHeight + 16)
    }

    private func addShakeRow() {
        let button = UIButton(type: .system)
        button.setTitle("UIView.shake · 点击测试 / Test shake", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 12
        button.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(50)
        }
        button.addTarget(self, action: #selector(shakeDemo), for: .primaryActionTriggered)
        stackView.addArrangedSubview(button)
    }

    @objc private func shakeDemo(_ sender: UIButton) {
        sender.shake(direction: .horizontal) { [weak self] in
            self?.feedbackLabel.text = "UIView.shake 已完成 / Shake completed"
        }
    }
}
