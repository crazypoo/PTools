//
//  PTDebugFunction.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Kingfisher

@objcMembers
public class PTDebugFunction: NSObject {
    //MARK: App測試模式的檢測
    ///App測試模式的檢測
    @MainActor class open func registerDefaultsFromSettingsBundle(pod:Bool = false) {
        // English: Install the optional adapter before Core asks for debug-aware behavior.
        // Español: Instala el adaptador opcional antes de que Core solicite un comportamiento consciente del diagnóstico.
        // 中文：在 Core 请求诊断相关行为前，先安装可选适配器。
        PTDebugRuntimeAdapter.install()
        let bundleSelected: Bundle
        if pod {
            let bundle = PTUtils.cgBaseBundle()
            let podBundle = bundle.path(forResource: CorePodBundleName, ofType: "bundle")
            guard let podBundle, let resolvedBundle = Bundle(path: podBundle) else {
                PTNSLogConsole("无法加载 PooTools 资源 Bundle", levelType: .error, loggerType: .settings)
                return
            }
            bundleSelected = resolvedBundle
        } else {
            bundleSelected = Bundle.main
        }
        
        if let settingsBundle = bundleSelected.path(forResource: "Settings", ofType: "bundle") {
            guard let settings = NSDictionary(contentsOfFile: settingsBundle.nsString.appendingPathComponent("Root.plist")),
                  let prefernces = settings["PreferenceSpecifiers"] as? [NSDictionary] else {
                PTNSLogConsole("Settings.bundle Root.plist 格式无效", levelType: .error, loggerType: .settings)
                return
            }
            var defaultsToRegister: [String: Any] = [:]
            for prefSpecification in prefernces {
                if let key :String = prefSpecification["Key"] as? String {
                    defaultsToRegister[key] = prefSpecification["DefaultValue"]
                }
            }
            UserDefaults.standard.register(defaults: defaultsToRegister)
            UserDefaults.standard.synchronize()
        } else {
            PTCoreUserDefultsWrapper.shared.AppServiceIdentifier = "1"
            PTNSLogConsole("没有发现Settings.bundle",levelType: PTLogMode,loggerType: .settings)
        }
    }

}

// English: Keep legacy Debug preference keys in the Debug product so Core no longer owns Debug configuration symbols.
// Español: Mantén las claves de preferencias heredadas de Debug en el producto Debug para que Core no posea símbolos de configuración de Debug.
// 中文：将旧 Debug 偏好 key 放回 Debug 产品，避免 Core 持有 Debug 配置符号。
public let PTDevMaskTouchBubbleKey = "PTDevMaskTouchBubbleKey"
public let PTDevMaskKey = "PTDevMaskKey"
public let ConsoleDebug = "UI_debug"
public let TouchInspectorDebug = "TS_debug"
public let TouchInspectorHitsDebug = "TS_Hit_debug"

// English: These deprecated properties preserve source compatibility while forwarding storage to the Debug-owned preference layer.
// Español: Estas propiedades obsoletas conservan la compatibilidad de código y reenvían el almacenamiento a la capa de preferencias de Debug.
// 中文：这些弃用属性继续兼容旧代码，并把存储转发到 Debug 自己的偏好层。
@available(*, deprecated, message: "使用 PTDebugPreferences；Usa PTDebugPreferences.")
public extension PTCoreUserDefultsWrapper {
    var AppDebugMode: Bool {
        get { PTUserDefaultsStore.value(ConsoleDebug, default: false) }
        set { PTUserDefaultsStore.set(newValue, forKey: ConsoleDebug) }
    }

    var AppDebbugTouchBubble: Bool {
        get { PTUserDefaultsStore.value(PTDevMaskTouchBubbleKey, default: true) }
        set { PTUserDefaultsStore.set(newValue, forKey: PTDevMaskTouchBubbleKey) }
    }

    var AppDebbugMark: Bool {
        get { PTUserDefaultsStore.value(PTDevMaskKey, default: true) }
        set { PTUserDefaultsStore.set(newValue, forKey: PTDevMaskKey) }
    }

    var AppTouchInspectShow: Bool {
        get { PTUserDefaultsStore.value(TouchInspectorDebug, default: true) }
        set { PTUserDefaultsStore.set(newValue, forKey: TouchInspectorDebug) }
    }

    var AppTouchInspectShowHits: Bool {
        get { PTUserDefaultsStore.value(TouchInspectorHitsDebug, default: true) }
        set { PTUserDefaultsStore.set(newValue, forKey: TouchInspectorHitsDebug) }
    }

    var LocalConsoleCurrentFontSize: CGFloat {
        get { PTUserDefaultsStore.value("LocalConsoleFontSize", default: 7.5) }
        set { PTUserDefaultsStore.set(newValue, forKey: "LocalConsoleFontSize") }
    }

    var LocalConsoleCurrentFontColor: String {
        get { PTUserDefaultsStore.value("LocalConsoleFontColor", default: "#FFFFFF") }
        set { PTUserDefaultsStore.set(newValue, forKey: "LocalConsoleFontColor") }
    }

    var PTLocalConsoleWidth: CGFloat? {
        get { PTUserDefaultsStore.optionalValue("LocalConsole.Width") }
        set { PTUserDefaultsStore.set(newValue, forKey: "LocalConsole.Width") }
    }

    var PTLocalConsoleHeight: CGFloat? {
        get { PTUserDefaultsStore.optionalValue("LocalConsole.Height") }
        set { PTUserDefaultsStore.set(newValue, forKey: "LocalConsole.Height") }
    }

    var PTLocalConsoleX: CGFloat? {
        get { PTUserDefaultsStore.optionalValue("LocalConsole.X") }
        set { PTUserDefaultsStore.set(newValue, forKey: "LocalConsole.X") }
    }

    var PTLocalConsoleY: CGFloat? {
        get { PTUserDefaultsStore.optionalValue("LocalConsole.Y") }
        set { PTUserDefaultsStore.set(newValue, forKey: "LocalConsole.Y") }
    }

    var PTMockLocationLat: CGFloat {
        get { PTUserDefaultsStore.value("MockLocationLat", default: 0) }
        set { PTUserDefaultsStore.set(newValue, forKey: "MockLocationLat") }
    }

    var PTMockLocationLng: CGFloat {
        get { PTUserDefaultsStore.value("MockLocationLng", default: 0) }
        set { PTUserDefaultsStore.set(newValue, forKey: "MockLocationLng") }
    }

    var PTMockLocationOpen: Bool {
        get { PTUserDefaultsStore.value("MockLocationOpen", default: false) }
        set { PTUserDefaultsStore.set(newValue, forKey: "MockLocationOpen") }
    }

    var PTLogWrite: Bool {
        get {
            #if DEBUG
            return PTUserDefaultsStore.value("LogWriteToTextFile", default: true)
            #else
            return PTUserDefaultsStore.value("LogWriteToTextFile", default: false)
            #endif
        }
        set {
            PTUserDefaultsStore.set(newValue, forKey: "LogWriteToTextFile")
            PTLogRuntimeConfiguration.defaultWritesToFile = newValue
        }
    }
}

// English: Immutable configuration crosses the Debug foundation boundary without carrying UIKit or UserDefaults state.
// Español: La configuración inmutable cruza el límite de Debug Foundation sin transportar estado de UIKit ni UserDefaults.
// 中文：不可变配置跨越 Debug Foundation 边界时不携带 UIKit 或 UserDefaults 状态。
public struct PTDebugConfiguration: Equatable, Sendable {
    public let consoleEnabled: Bool
    public let touchBubbleEnabled: Bool
    public let maskEnabled: Bool
    public let touchOverlayEnabled: Bool
    public let hitTestingEnabled: Bool
    public let mockLocationEnabled: Bool
    public let writesLogToFile: Bool

    public init(consoleEnabled: Bool = false,
                touchBubbleEnabled: Bool = true,
                maskEnabled: Bool = true,
                touchOverlayEnabled: Bool = true,
                hitTestingEnabled: Bool = true,
                mockLocationEnabled: Bool = false,
                writesLogToFile: Bool = false) {
        self.consoleEnabled = consoleEnabled
        self.touchBubbleEnabled = touchBubbleEnabled
        self.maskEnabled = maskEnabled
        self.touchOverlayEnabled = touchOverlayEnabled
        self.hitTestingEnabled = hitTestingEnabled
        self.mockLocationEnabled = mockLocationEnabled
        self.writesLogToFile = writesLogToFile
    }
}

// English: Keep legacy keys readable and writable while the Debug layer owns their typed accessors.
// Español: Mantén las claves heredadas legibles y escribibles mientras la capa Debug posee sus accesores tipados.
// 中文：由 Debug 层统一管理类型化访问，同时继续读写旧 key，保证 5.x 配置无损兼容。
@MainActor
public final class PTDebugPreferences {
    public static let shared = PTDebugPreferences()

    private let defaults: UserDefaults

    private enum Key {
        static let migrationMarker = "PTools.Debug.preferencesMigrated"
        static let console = "PTools.Debug.consoleEnabled"
        static let legacyConsole = ConsoleDebug
        static let touchBubble = "PTools.Debug.touchBubbleEnabled"
        static let legacyTouchBubble = PTDevMaskTouchBubbleKey
        static let mask = "PTools.Debug.maskEnabled"
        static let legacyMask = PTDevMaskKey
        static let touchOverlay = "PTools.Debug.touchOverlayEnabled"
        static let legacyTouchOverlay = TouchInspectorDebug
        static let hitTesting = "PTools.Debug.hitTestingEnabled"
        static let legacyHitTesting = TouchInspectorHitsDebug
        static let fontSize = "PTools.Debug.consoleFontSize"
        static let legacyFontSize = "LocalConsoleFontSize"
        static let fontColor = "PTools.Debug.consoleFontColorHex"
        static let legacyFontColor = "LocalConsoleFontColor"
        static let width = "PTools.Debug.consoleWidth"
        static let legacyWidth = "LocalConsole.Width"
        static let height = "PTools.Debug.consoleHeight"
        static let legacyHeight = "LocalConsole.Height"
        static let x = "PTools.Debug.consoleX"
        static let legacyX = "LocalConsole.X"
        static let y = "PTools.Debug.consoleY"
        static let legacyY = "LocalConsole.Y"
        static let latitude = "PTools.Debug.mockLocationLatitude"
        static let legacyLatitude = "MockLocationLat"
        static let longitude = "PTools.Debug.mockLocationLongitude"
        static let legacyLongitude = "MockLocationLng"
        static let mockLocation = "PTools.Debug.mockLocationEnabled"
        static let legacyMockLocation = "MockLocationOpen"
        static let writesLog = "PTools.Debug.writesLogToFile"
        static let legacyWritesLog = "LogWriteToTextFile"
    }

    public init(userDefaults: UserDefaults = .standard) {
        defaults = userDefaults
        migrateLegacyValuesIfNeeded()
        PTLogRuntimeConfiguration.defaultWritesToFile = writesLogToFile
    }

    public var configuration: PTDebugConfiguration {
        get {
            PTDebugConfiguration(consoleEnabled: isConsoleEnabled,
                                 touchBubbleEnabled: isTouchBubbleEnabled,
                                 maskEnabled: isMaskEnabled,
                                 touchOverlayEnabled: isTouchOverlayEnabled,
                                 hitTestingEnabled: isHitTestingEnabled,
                                 mockLocationEnabled: isMockLocationEnabled,
                                 writesLogToFile: writesLogToFile)
        }
        set {
            isConsoleEnabled = newValue.consoleEnabled
            isTouchBubbleEnabled = newValue.touchBubbleEnabled
            isMaskEnabled = newValue.maskEnabled
            isTouchOverlayEnabled = newValue.touchOverlayEnabled
            isHitTestingEnabled = newValue.hitTestingEnabled
            isMockLocationEnabled = newValue.mockLocationEnabled
            writesLogToFile = newValue.writesLogToFile
        }
    }

    public var isConsoleEnabled: Bool {
        get { bool(canonical: Key.console, legacy: Key.legacyConsole, defaultValue: false) }
        set { set(newValue, canonical: Key.console, legacy: Key.legacyConsole) }
    }

    public var isTouchBubbleEnabled: Bool {
        get { bool(canonical: Key.touchBubble, legacy: Key.legacyTouchBubble, defaultValue: true) }
        set { set(newValue, canonical: Key.touchBubble, legacy: Key.legacyTouchBubble) }
    }

    public var isMaskEnabled: Bool {
        get { bool(canonical: Key.mask, legacy: Key.legacyMask, defaultValue: true) }
        set { set(newValue, canonical: Key.mask, legacy: Key.legacyMask) }
    }

    public var isTouchOverlayEnabled: Bool {
        get { bool(canonical: Key.touchOverlay, legacy: Key.legacyTouchOverlay, defaultValue: true) }
        set { set(newValue, canonical: Key.touchOverlay, legacy: Key.legacyTouchOverlay) }
    }

    public var isHitTestingEnabled: Bool {
        get { bool(canonical: Key.hitTesting, legacy: Key.legacyHitTesting, defaultValue: true) }
        set { set(newValue, canonical: Key.hitTesting, legacy: Key.legacyHitTesting) }
    }

    public var consoleFontSize: CGFloat {
        get { number(canonical: Key.fontSize, legacy: Key.legacyFontSize, defaultValue: 7.5) }
        set { set(newValue, canonical: Key.fontSize, legacy: Key.legacyFontSize) }
    }

    public var consoleFontColorHex: String {
        get { string(canonical: Key.fontColor, legacy: Key.legacyFontColor, defaultValue: "#FFFFFF") }
        set { set(newValue, canonical: Key.fontColor, legacy: Key.legacyFontColor) }
    }

    public var consoleWidth: CGFloat? {
        get { optionalNumber(canonical: Key.width, legacy: Key.legacyWidth) }
        set { set(newValue, canonical: Key.width, legacy: Key.legacyWidth) }
    }

    public var consoleHeight: CGFloat? {
        get { optionalNumber(canonical: Key.height, legacy: Key.legacyHeight) }
        set { set(newValue, canonical: Key.height, legacy: Key.legacyHeight) }
    }

    public var consoleX: CGFloat? {
        get { optionalNumber(canonical: Key.x, legacy: Key.legacyX) }
        set { set(newValue, canonical: Key.x, legacy: Key.legacyX) }
    }

    public var consoleY: CGFloat? {
        get { optionalNumber(canonical: Key.y, legacy: Key.legacyY) }
        set { set(newValue, canonical: Key.y, legacy: Key.legacyY) }
    }

    public var mockLocationLatitude: CGFloat {
        get { number(canonical: Key.latitude, legacy: Key.legacyLatitude, defaultValue: 0) }
        set { set(newValue, canonical: Key.latitude, legacy: Key.legacyLatitude) }
    }

    public var mockLocationLongitude: CGFloat {
        get { number(canonical: Key.longitude, legacy: Key.legacyLongitude, defaultValue: 0) }
        set { set(newValue, canonical: Key.longitude, legacy: Key.legacyLongitude) }
    }

    public var isMockLocationEnabled: Bool {
        get { bool(canonical: Key.mockLocation, legacy: Key.legacyMockLocation, defaultValue: false) }
        set { set(newValue, canonical: Key.mockLocation, legacy: Key.legacyMockLocation) }
    }

    public var writesLogToFile: Bool {
        get {
            #if DEBUG
            return bool(canonical: Key.writesLog, legacy: Key.legacyWritesLog, defaultValue: true)
            #else
            return bool(canonical: Key.writesLog, legacy: Key.legacyWritesLog, defaultValue: false)
            #endif
        }
        set {
            set(newValue, canonical: Key.writesLog, legacy: Key.legacyWritesLog)
            PTLogRuntimeConfiguration.defaultWritesToFile = newValue
        }
    }

    private func migrateLegacyValuesIfNeeded() {
        guard !defaults.bool(forKey: Key.migrationMarker) else { return }
        let pairs = [
            (Key.console, Key.legacyConsole),
            (Key.touchBubble, Key.legacyTouchBubble),
            (Key.mask, Key.legacyMask),
            (Key.touchOverlay, Key.legacyTouchOverlay),
            (Key.hitTesting, Key.legacyHitTesting),
            (Key.fontSize, Key.legacyFontSize),
            (Key.fontColor, Key.legacyFontColor),
            (Key.width, Key.legacyWidth),
            (Key.height, Key.legacyHeight),
            (Key.x, Key.legacyX),
            (Key.y, Key.legacyY),
            (Key.latitude, Key.legacyLatitude),
            (Key.longitude, Key.legacyLongitude),
            (Key.mockLocation, Key.legacyMockLocation),
            (Key.writesLog, Key.legacyWritesLog)
        ]
        pairs.forEach { canonical, legacy in
            guard defaults.object(forKey: canonical) == nil,
                  let value = defaults.object(forKey: legacy) else { return }
            defaults.set(value, forKey: canonical)
        }
        defaults.set(true, forKey: Key.migrationMarker)
    }

    private func bool(canonical: String, legacy: String, defaultValue: Bool) -> Bool {
        (defaults.object(forKey: legacy) as? NSNumber)?.boolValue
            ?? (defaults.object(forKey: canonical) as? NSNumber)?.boolValue
            ?? defaultValue
    }

    private func number(canonical: String, legacy: String, defaultValue: CGFloat) -> CGFloat {
        optionalNumber(canonical: canonical, legacy: legacy) ?? defaultValue
    }

    private func optionalNumber(canonical: String, legacy: String) -> CGFloat? {
        let value = defaults.object(forKey: legacy) ?? defaults.object(forKey: canonical)
        if let number = value as? NSNumber { return CGFloat(truncating: number) }
        if let value = value as? CGFloat { return value }
        return nil
    }

    private func string(canonical: String, legacy: String, defaultValue: String) -> String {
        (defaults.object(forKey: legacy) as? String)
            ?? (defaults.object(forKey: canonical) as? String)
            ?? defaultValue
    }

    private func set<T>(_ value: T?, canonical: String, legacy: String) {
        defaults.set(value, forKey: canonical)
        defaults.set(value, forKey: legacy)
    }
}

// English: Plugins keep their original menu contract while gaining idempotent lifecycle hooks with safe defaults.
// Español: Los plugins conservan su contrato de menú original y obtienen hooks de ciclo de vida idempotentes con valores seguros.
// 中文：插件保留原有菜单契约，同时通过安全默认实现获得幂等生命周期钩子。
public protocol PTDebugPlugin: AnyObject {
    var title: String { get }
    var image: UIImage? { get }
    var group: String { get }
    var priority: Int { get }
    var isEnabled: Bool { get }
    var action: UIAction { get }
    var identifier: String { get }
    var isRunning: Bool { get }
    func start()
    func stop()
}

public extension PTDebugPlugin {
    var identifier: String { String(reflecting: type(of: self)) }
    var isRunning: Bool { isEnabled }
    func start() {}
    func stop() {}
}

// English: Collectors are lifecycle-owned by PTDebugManager and never expose mutable implementation state to UI.
// Español: PTDebugManager posee el ciclo de vida de los collectors y la UI nunca recibe su estado mutable interno.
// 中文：PTDebugManager 统一管理 Collector 生命周期，UI 不直接接触其可变实现状态。
@MainActor
public protocol PTDebugCollector: AnyObject {
    var identifier: String { get }
    var isRunning: Bool { get }
    func start()
    func stop()
}

// English: Events use string snapshots so future storage and Instruments consumers do not cross actors with UIKit objects.
// Español: Los eventos usan instantáneas String para que el almacenamiento y futuros consumidores de Instruments no crucen actores con objetos UIKit.
// 中文：事件只携带 String 快照，后续存储和 Instruments 消费者无需跨 actor 传递 UIKit 对象。
public struct PTDebugEvent: Sendable, Equatable {
    public let id: UUID
    public let date: Date
    public let name: String
    public let source: String
    public let payload: [String: String]

    public init(id: UUID = UUID(),
                date: Date = Date(),
                name: String,
                source: String,
                payload: [String: String] = [:]) {
        self.id = id
        self.date = date
        self.name = name
        self.source = source
        self.payload = payload
    }
}

// English: MainActor event delivery makes observer registration, removal, and UI updates deterministic.
// Español: La entrega de eventos en MainActor hace deterministas el registro, la eliminación y las actualizaciones UI.
// 中文：事件统一在 MainActor 投递，让观察者注册、移除和 UI 更新保持确定性。
@MainActor
public final class PTDebugEventCenter {
    public static let shared = PTDebugEventCenter()

    private var observers: [UUID: (PTDebugEvent) -> Void] = [:]

    private init() {}

    @discardableResult
    public func addObserver(_ observer: @escaping (PTDebugEvent) -> Void) -> UUID {
        let token = UUID()
        observers[token] = observer
        return token
    }

    public func removeObserver(_ token: UUID) {
        observers.removeValue(forKey: token)
    }

    public func publish(_ event: PTDebugEvent) {
        observers.values.forEach { $0(event) }
    }
}

// English: PTDebugManager owns registration and lifecycle only; individual tools keep their own behavior.
// Español: PTDebugManager solo posee el registro y el ciclo de vida; cada herramienta conserva su comportamiento.
// 中文：PTDebugManager 只负责注册与生命周期，各工具保留自己的业务行为。
@MainActor
public final class PTDebugManager {
    public static let shared = PTDebugManager()

    private var plugins: [String: PTDebugPlugin] = [:]
    private var collectors: [String: PTDebugCollector] = [:]
    private var collectorOrder: [String] = []
    private var sessionOwners = Set<String>()

    private init() {
        register(collector: PTConsoleCollector())
        register(collector: PTNetworkCollector())
        register(collector: PTLifecycleCollector())
        register(collector: PTInspectorCollector())
        register(collector: PTCrashCollector())
        register(collector: PTLeakCollector())
        register(collector: PTMockLocationCollector())
    }

    public var menuPlugins: [PTDebugPlugin] {
        Array(plugins.values)
    }

    public func register(plugin: PTDebugPlugin) {
        plugins[plugin.identifier] = plugin
    }

    public func unregister(pluginIdentifier: String) {
        plugins.removeValue(forKey: pluginIdentifier)?.stop()
    }

    public func clearPlugins() {
        plugins.values.forEach { $0.stop() }
        plugins.removeAll()
    }

    public func register(collector: PTDebugCollector) {
        if collectors[collector.identifier] == nil {
            collectorOrder.append(collector.identifier)
        }
        collectors[collector.identifier] = collector
    }

    public func start(identifier: String) {
        collectors[identifier]?.start()
        plugins[identifier]?.start()
    }

    public func stop(identifier: String) {
        collectors[identifier]?.stop()
        plugins[identifier]?.stop()
    }

    public func startAll() {
        collectorOrder.forEach { collectors[$0]?.start() }
        plugins.values.forEach { $0.start() }
    }

    // English: Keep collectors alive until the last visible scene releases its Debug session.
    // Español: Mantén los collectors activos hasta que la última escena visible libere su sesión de Debug.
    // 中文：只有最后一个可见场景释放 Debug 会话后，才停止所有 Collector。
    public func startSession(owner: String) {
        guard !owner.isEmpty, sessionOwners.insert(owner).inserted else { return }
        if sessionOwners.count == 1 {
            startAll()
        }
    }

    // English: Scene-scoped release prevents one console from stopping another scene's diagnostics.
    // Español: La liberación por escena evita que una consola detenga los diagnósticos de otra escena.
    // 中文：按场景释放会话，避免一个控制台关闭时误停另一个场景的诊断能力。
    public func stopSession(owner: String) {
        guard !owner.isEmpty, sessionOwners.remove(owner) != nil else { return }
        if sessionOwners.isEmpty {
            stopAll()
        }
    }

    public func stopAll() {
        sessionOwners.removeAll()
        plugins.values.forEach { $0.stop() }
        collectorOrder.reversed().forEach { collectors[$0]?.stop() }
    }

    public func collector(identifier: String) -> PTDebugCollector? {
        collectors[identifier]
    }

    public func setLeakHandler(_ handler: (@MainActor @Sendable (PTPerformanceLeak) -> Void)?) {
        (collectors["leak"] as? PTLeakCollector)?.handler = handler
    }
}

// English: Keep the old plugin manager as a source-compatible facade over the new foundation manager.
// Español: Mantén el antiguo administrador de plugins como fachada compatible sobre el nuevo administrador de foundation.
// 中文：保留旧插件管理器作为新 Foundation Manager 的源码兼容门面。
@MainActor
final class PTDebugPluginManager {
    static let shared = PTDebugPluginManager()

    private init() {}

    var plugins: [PTDebugPlugin] {
        PTDebugManager.shared.menuPlugins
    }

    func clearAll() {
        PTDebugManager.shared.clearPlugins()
    }

    func register(_ plugin: PTDebugPlugin) {
        PTDebugManager.shared.register(plugin: plugin)
    }

    func groupedPlugins() -> [String: [PTDebugPlugin]] {
        Dictionary(grouping: plugins.filter(\.isEnabled), by: \.group)
    }
}

// English: The window coordinator keeps diagnostic windows scene-scoped and avoids stealing the business key window.
// Español: El coordinador mantiene las ventanas de diagnóstico por escena y evita robar la ventana clave de negocio.
// 中文：窗口协调器按场景管理诊断窗口，避免抢占业务窗口的 key window 状态。
@MainActor
public final class PTDebugWindowCoordinator {
    public static let shared = PTDebugWindowCoordinator()

    private init() {}

    public func hideAuxiliaryWindows() {
        PTSceneContext.connectedWindowScenes()
            .flatMap { $0.windows }
            .compactMap { $0 as? PTConsoleWindow }
            .forEach { $0.isHidden = true }
    }

    public func restoreAuxiliaryWindows() {
        PTSceneContext.connectedWindowScenes()
            .flatMap { $0.windows }
            .compactMap { $0 as? PTConsoleWindow }
            .forEach { window in
                guard window.rootViewController != nil else { return }
                window.windowLevel = PTConsoleWindow.debugWindowLevel
                window.isHidden = false
            }
    }

    public func bringConsoleContentToFront() {
        LocalConsole.knownConsoles.forEach { console in
            guard console.isVisiable,
                  let window = console.consoleOverlayWindow else { return }
            if let maskView = console.maskView {
                window.bringSubviewToFront(maskView)
            }
            if let terminal = console.terminal {
                window.bringSubviewToFront(terminal)
            }
        }
    }
}

// English: This adapter is the only Debug-to-Core bridge; Core remains usable when the Debug product is absent.
// Español: Este adaptador es el único puente de Debug hacia Core; Core sigue funcionando sin el producto Debug.
// 中文：该适配器是 Debug 到 Core 的唯一桥接点；未安装 Debug 产品时 Core 仍可独立使用。
@MainActor
public enum PTDebugRuntimeAdapter {
    private static var isInstalled = false

    public static func install() {
        guard !isInstalled else { return }
        isInstalled = true

        PTUIKitRuntimeHooks.makeApplicationWindow = { scene in
            switch UIApplication.shared.inferredEnvironment_PT {
            case .appStore, .testFlight:
                return nil
            default:
                let window = TouchInspectorWindow(windowScene: scene)
                window.showTouches = PTDebugPreferences.shared.isTouchOverlayEnabled
                window.showHitTesting = PTDebugPreferences.shared.isHitTestingEnabled
                return window
            }
        }
        PTUIKitRuntimeHooks.consoleVisibilityHandler = { visible in
            LocalConsole.shared.isVisiable = visible
        }
        PTUIKitRuntimeHooks.restoreConsoleState = {
            LocalConsole.shared.isVisiable = PTDebugPreferences.shared.isConsoleEnabled
        }
        PTUIKitRuntimeHooks.settingsBundleHandler = {
            PTDebugFunction.registerDefaultsFromSettingsBundle()
        }
        PTUIKitRuntimeHooks.webImageOptionsProvider = { _, _ in
            PTDevFunction.webImageLoadOptions()
        }
        PTUIKitRuntimeHooks.interceptPush = { viewController, completion in
            let console = LocalConsole.shared
            guard console.isVisiable,
                  let presenter = PTUtils.getCurrentVC(),
                  presenter.presentedViewController == nil else {
                return false
            }
            let navigationController = PTBaseNavControl(rootViewController: viewController)
            navigationController.modalPresentationStyle = .formSheet
            presenter.present(navigationController, animated: true) {
                completion?()
                PTDebugWindowCoordinator.shared.bringConsoleContentToFront()
            }
            return true
        }
        PTUIKitRuntimeHooks.shouldTrackViewBorders = {
            LocalConsole.shared.debugBordersEnabled
        }
        PTUIKitRuntimeHooks.shouldPreserveContextMenuOrder = { menu in
            menu.title == .debug || menu.title == .userDefaults
        }
        PTUIKitRuntimeHooks.presentationWillBegin = {
            PTDebugWindowCoordinator.shared.hideAuxiliaryWindows()
        }
        PTUIKitRuntimeHooks.presentationDidComplete = {
            PTMainActorBridge.after(0.35) {
                PTDebugWindowCoordinator.shared.restoreAuxiliaryWindows()
                PTDebugWindowCoordinator.shared.bringConsoleContentToFront()
            }
        }
        PTUIKitRuntimeHooks.controllerTransitionDidComplete = {
            PTDebugWindowCoordinator.shared.bringConsoleContentToFront()
        }
        // English: Forward the existing lifecycle swizzle as immutable text snapshots for optional consumers.
        // Español: Reenvía el swizzle de ciclo de vida existente como snapshots de texto inmutables para consumidores opcionales.
        // 中文：把现有生命周期 swizzle 转发为不可变文本快照，供可选消费者使用。
        PTUIKitRuntimeHooks.controllerLifecycleHandler = { phase, controller in
            PTDebugEventCenter.shared.publish(
                PTDebugEvent(name: "lifecycle.\(phase)",
                             source: "uiviewcontroller",
                             payload: ["controller": controller])
            )
        }
    }
}

// English: The console collector owns stdout and stderr capture only; it does not know about the console UI.
// Español: El collector de consola solo posee la captura de stdout y stderr; no conoce la UI de la consola.
// 中文：控制台 Collector 只负责 stdout 和 stderr 捕获，不依赖控制台 UI。
@MainActor
final class PTConsoleCollector: PTDebugCollector {
    let identifier = "console"
    private(set) var isRunning = false

    func start() {
        guard !isRunning else { return }
        isRunning = true
        StdoutCapture.startCapturing()
        StderrCapture.startCapturing()
        StderrCapture.syncData()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        StdoutCapture.stopCapturing()
        StderrCapture.stopCapturing()
    }
}

// English: The network collector owns protocol interception and publishes immutable status snapshots.
// Español: El collector de red posee la interceptación de protocolos y publica instantáneas de estado inmutables.
// 中文：网络 Collector 负责协议拦截，并发布不可变的网络状态快照。
@MainActor
final class PTNetworkCollector: PTDebugCollector {
    let identifier = "network"
    private(set) var isRunning = false
    private var statusTask: Task<Void, Never>?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        URLSessionConfiguration.swizzleMethods()
        PTNetworkHelper.shared.enable()
        statusTask = Task { @MainActor [weak self] in
            for await status in PTNetWorkStatus.shared.statusStream {
                guard !Task.isCancelled, let self, self.isRunning else { return }
                let value = NetWorkStatus.valueName(type: status)
                PTDebugEventCenter.shared.publish(
                    PTDebugEvent(name: "network.status",
                                 source: self.identifier,
                                 payload: ["value": value])
                )
            }
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        statusTask?.cancel()
        statusTask = nil
        PTNetworkHelper.shared.disable()
    }
}

// English: Lifecycle and interaction hooks are installed once through the shared swizzle registry.
// Español: Los hooks de ciclo de vida e interacción se instalan una vez mediante el registro de swizzles compartido.
// 中文：生命周期和交互钩子通过共享 swizzle 注册表只安装一次。
@MainActor
final class PTLifecycleCollector: PTDebugCollector {
    let identifier = "lifecycle"
    private(set) var isRunning = false

    func start() {
        guard !isRunning else { return }
        isRunning = true
        PTLaunchTimeTracker.measureAppStartUpTime()
        UIViewController.lvcdSwizzleLifecycleMethods()
        UIView.swizzleMethods()
        UIWindow.db_swizzleMethods()
    }

    func stop() {
        isRunning = false
    }
}

// English: Inspector startup is isolated so LocalConsole stays responsible only for displaying console content.
// Español: El inicio de Inspector está aislado para que LocalConsole solo gestione el contenido de consola.
// 中文：Inspector 启动被独立隔离，让 LocalConsole 只负责展示控制台内容。
@MainActor
final class PTInspectorCollector: PTDebugCollector {
    let identifier = "inspector"
    private(set) var isRunning = false

    func start() {
        guard !isRunning else { return }
        isRunning = true
        Inspector.sharedInstance.start()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        Inspector.sharedInstance.stop()
    }
}

// English: Crash handlers are intentionally registered once because the underlying signal hooks cannot be undone safely.
// Español: Los handlers de crash se registran una sola vez porque los hooks de señales subyacentes no se pueden deshacer con seguridad.
// 中文：崩溃处理器只注册一次，因为底层信号钩子无法安全撤销。
@MainActor
final class PTCrashCollector: PTDebugCollector {
    let identifier = "crash"
    private(set) var isRunning = false
    private var didRegister = false

    func start() {
        guard !isRunning else { return }
        if !didRegister {
            PTCrashManager.register()
            didRegister = true
        }
        isRunning = true
    }

    func stop() {
        isRunning = false
    }
}

// English: Leak detection is connected through a weak handler and publishes only text snapshots to the event center.
// Español: La detección de fugas usa un handler débil y solo publica instantáneas de texto al centro de eventos.
// 中文：泄漏检测通过弱引用回调连接，并只向事件中心发布文本快照。
@MainActor
final class PTLeakCollector: PTDebugCollector {
    let identifier = "leak"
    private(set) var isRunning = false
    var handler: (@MainActor @Sendable (PTPerformanceLeak) -> Void)?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        PTPerformanceLeakDetector.setup()
        PTPerformanceLeakDetector.delay = 1
        PTPerformanceLeakDetector.callback = { [weak self] leak in
            self?.handler?(leak)
            PTDebugEventCenter.shared.publish(
                PTDebugEvent(name: "leak.detected",
                             source: self?.identifier ?? "leak",
                             payload: ["message": leak.message])
            )
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        PTPerformanceLeakDetector.callback = nil
        PTPerformanceLeakDetector.teardown()
    }
}

// English: Mock-location swizzling is an irreversible compatibility hook and is enabled only when the preference is on.
// Español: El swizzle de ubicación simulada es irreversible y solo se habilita cuando la preferencia está activa.
// 中文：模拟定位 swizzle 属于不可逆兼容钩子，仅在偏好开关开启时启用。
@MainActor
final class PTMockLocationCollector: PTDebugCollector {
    let identifier = "mock-location"
    private(set) var isRunning = false

    func start() {
        guard PTDebugPreferences.shared.isMockLocationEnabled, !isRunning else { return }
        isRunning = true
        CLLocationManager.swizzleMethods()
    }

    func stop() {
        isRunning = false
    }
}
