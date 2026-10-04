// English: Stable metadata and routing primitives for the Example Demo Catalog 2.0.
// Español: Primitivas estables de metadatos y rutas para el catálogo Demo 2.0 del Example.
// 中文：Example Demo Catalog 2.0 的稳定元数据与路由基础类型。

import UIKit
import PooTools

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
        make("navigation.split-view", "PooToolsSplitView", "Adaptive SplitView", .navigationRouting, .interactive, .push, .runnable, legacy: "AdaptiveSplitView", tags: ["split-view", "ipad", "adaptive", "state-restoration"]),
        make("navigation.segment-paging-regression", "PooToolsSegmented", "Segmented / JX Parity & Paging", .navigationRouting, .interactive, .push, .runnable, legacy: "SegmentedPagingRegression", tags: ["segment", "paging", "badge", "jx-parity", "regression"]),
        make("navigation.segment-item-separator", "PooToolsSegmented", "Segmented / Item Separator", .navigationRouting, .interactive, .push, .runnable, legacy: "SegmentedItemSeparator", tags: ["segment", "separator", "rtl", "reuse"]),
        make("security.encryption", "PooToolsDataEncrypt", "Encryption", .securityPrivacy, .interactive, .sheet, .runnable, legacy: "Encryption", tags: ["crypto"]),
        make("network.speed-test", "PooToolsNetworkSpeedTest", "Network Speed Test", .networkConnectivity, .interactive, .push, .runnable, legacy: "NetworkSpeedTest", tags: ["network", "speed", "endpoint"]),
        make("network.ping", "PooToolsPing", "Ping Session", .networkConnectivity, .interactive, .push, .runnable, legacy: "PingSession", tags: ["network", "ping", "state-machine"]),
        make("device.heart-rate", "PooToolsHeartRate", "Heart Rate", .permissionsDevice, .hostRequired, .fullScreen, .physicalDeviceRequired, [.camera, .physicalDevice], legacy: "HeartRate", tags: ["camera", "health", "runtime-safety"]),
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
        default:
            return PTFuncDetailViewController(descriptor: descriptor)
        }
    }

    func present(_ descriptor: PTDemoDescriptor, from host: UIViewController, sizes: [PTSheetSize] = [.percent(0.5)]) {
        let viewController = viewController(for: descriptor)
        switch descriptor.presentation {
        case .push:
            host.navigationController?.pushViewController(viewController, animated: true)
        case .fullScreen:
            viewController.modalPresentationStyle = .fullScreen
            host.showDetailViewController(viewController, sender: nil)
        case .sheet, .inline, .action:
            UIViewController.currentPresentToSheet(vc: viewController, sizes: sizes)
        }
    }
}

// English: This compact SplitView demo exercises double/triple columns and adaptive navigation without a second demo framework.
// Español: Este demo compacto de SplitView prueba columnas dobles/triples y navegación adaptativa sin otro framework de demos.
// 中文：这个紧凑的 SplitView Demo 演示双栏/三栏和自适应导航，不创建第二套 Demo 框架。
@MainActor
private final class PT5_61SplitViewDemoViewController: PTSplitViewController {
    init() {
        super.init(configuration: PTSplitConfiguration(style: .tripleColumn,
                                                        displayMode: .oneBesideSecondary,
                                                        splitBehavior: .tile,
                                                        primaryWidthFraction: 0.25,
                                                        supplementaryWidthFraction: 0.25,
                                                        navigationPolicy: .wrapAll))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setPrimary(PT5_61DemoLabelViewController(title: "Sidebar / 主栏"))
        setSupplementary(PT5_61DemoLabelViewController(title: "Search / 搜索"))
        setSecondary(PT5_61DemoLabelViewController(title: "Detail / 详情"))
        setInspector(PT5_61DemoLabelViewController(title: "Inspector / 检查器"))
    }
}

// English: The shared label controller keeps the demo deterministic and safe on every simulator size.
// Español: El controlador de etiqueta compartido mantiene el demo determinista y seguro en cualquier tamaño de simulador.
// 中文：共享标签控制器让 Demo 在不同模拟器尺寸下保持确定且安全。
@MainActor
private final class PT5_61DemoLabelViewController: PTBaseViewController {
    private let titleText: String

    init(title: String) {
        titleText = title
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        titleText = ""
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.text = titleText
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .label
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
