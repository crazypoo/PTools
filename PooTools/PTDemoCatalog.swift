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
        make("input.input-box", "PooToolsInput", "InputBox", .inputForm, .interactive, .sheet, .runnable, legacy: "InputBox", tags: ["input"]),
        make("input.stepper", "PooToolsStepper", "Stepper", .inputForm, .interactive, .sheet, .runnable, legacy: "Stepper", tags: ["input"]),
        make("input.login-description", "PooToolsCustomerLabel", "LoginDesc", .inputForm, .interactive, .sheet, .runnable, legacy: "LoginDesc", tags: ["button", "rich-text"]),
        make("input.stepper-list", "PooToolsStepper", "StepperList", .inputForm, .interactive, .sheet, .runnable, legacy: "StepperList", tags: ["input", "list"]),
        make("media.live-photo", "PooToolsLivePhoto", "LivePhoto", .mediaGraphics, .hostRequired, .sheet, .runnable, [.photoLibrary], legacy: "LivePhoto", tags: ["photo", "live-photo"]),
        make("media.live-photo-disassemble", "PooToolsLivePhoto", "LivePhotoDisassemble", .mediaGraphics, .hostRequired, .sheet, .runnable, [.photoLibrary], legacy: "LivePhotoDisassemble", tags: ["photo", "live-photo"]),
        make("navigation.route", "PooToolsRouter", "路由", .navigationRouting, .interactive, .sheet, .runnable, legacy: "路由", tags: ["route"]),
        make("navigation.split-view", "PooToolsSplitView", "Adaptive SplitView — iPhone / iPad", .navigationRouting, .interactive, .rootContainer, .runnable, legacy: "AdaptiveSplitView", tags: ["split-view", "iphone", "ipad", "compact", "regular", "adaptive", "router", "state-restoration", "inspector"]),
        make("navigation.segment-paging-regression", "PooToolsSegmented", "Segmented / JX Parity & Paging", .navigationRouting, .interactive, .push, .runnable, legacy: "SegmentedPagingRegression", tags: ["segment", "paging", "badge", "jx-parity", "regression"]),
        make("navigation.segment-item-separator", "PooToolsSegmented", "Segmented / Item Separator", .navigationRouting, .interactive, .push, .runnable, legacy: "SegmentedItemSeparator", tags: ["segment", "separator", "rtl", "reuse"]),
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

        switch descriptor.id.rawValue {
        case "navigation.split-view":
            return PT5_61SplitViewDemoViewController()
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
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
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
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
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
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
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
    private let modeControl = UISegmentedControl(items: ["Legacy", "Selection", "Content", "Offset", "Combined"])
    private let descriptionLabel = UILabel()
    private var previewBar: PTTabBarView?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "TabBar Item Insets"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        modeControl.selectedSegmentIndex = 1
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [modeControl, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 12
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        rebuildPreview()
    }

    @objc private func modeChanged() {
        rebuildPreview()
    }

    private func rebuildPreview() {
        previewBar?.removeFromSuperview()

        let mode = modeControl.selectedSegmentIndex
        let layout: PTTabBarLayoutAppearance
        switch mode {
        case 0:
            layout = PTTabBarLayoutAppearance(tabBottomSpacing: 10, tabSelectedMetail: true, tabTopSpacing: 10)
            descriptionLabel.text = "Legacy slot spacing changes the old item layout."
        case 1:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabSelectedMetailInsets: UIEdgeInsets(top: 10, left: 6, bottom: 10, right: 6))
            descriptionLabel.text = "Selection background changes; icon and title size stay unchanged."
        case 2:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentInsets: UIEdgeInsets(top: 4, left: 4, bottom: 2, right: 4))
            descriptionLabel.text = "Content padding changes the content boundary only."
        case 3:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                               tabItemContentOffset: UIOffset(horizontal: 0, vertical: -3))
            descriptionLabel.text = "Content moves upward without changing icon size or selection frame."
        default:
            layout = PTTabBarLayoutAppearance(tabSelectedMetail: true,
                                               tabSelectedMetailColor: .systemBlue,
                                              tabItemContentInsets: UIEdgeInsets(top: 3, left: 4, bottom: 2, right: 4), tabItemContentOffset: UIOffset(horizontal: 0, vertical: -2), tabSelectedMetailInsets: UIEdgeInsets(top: 8, left: 6, bottom: 8, right: 6))
            descriptionLabel.text = "Selection, padding and translation are applied by separate layers."
        }

        let appearance = PTTabBarAppearance(normalColor: .secondaryLabel,
                                             selectedColor: .systemBlue,
                                             layout: layout)
        let bar = PTTabBarView(frame: .zero, appearance: appearance)
        let configs = [
            PTTabBarItemConfig(title: "Home",
                               content: PTTabBarImageContent(normal: demoImage(systemName: "house"),
                                                             selected: demoImage(systemName: "house.fill")),
                               viewController: UIViewController()),
            PTTabBarItemConfig(title: "List",
                               content: PTTabBarImageContent(normal: demoImage(systemName: "list.bullet"),
                                                             selected: demoImage(systemName: "list.bullet.rectangle.fill")),
                               viewController: UIViewController()),
            PTTabBarItemConfig(title: "Profile",
                               content: PTTabBarImageContent(normal: demoImage(systemName: "person"),
                                                             selected: demoImage(systemName: "person.fill")),
                               viewController: UIViewController())
        ]
        bar.setup(configs: configs)
        view.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(24)
            make.height.equalTo(CGFloat.kTabbarHeight_Total)
        }
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
        imageView.image = UIImage(systemName: "photo")?.withTintColor(.white, renderingMode: .alwaysOriginal)
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
