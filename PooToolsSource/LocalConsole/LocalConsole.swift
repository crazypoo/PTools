//
//  LocalConsole.swift
//  Diou
//
//  Created by jax on 2021/8/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import DeviceKit
import CoreFoundation
import AttributedString
import SwifterSwift
import SafeSFSymbols
import SnapKit
import CoreLocation
#if canImport(InAppViewDebugger)
import InAppViewDebugger
#endif
#if canImport(FLEX)
import FLEX
#endif

public let LocalConsoleFontMin:CGFloat = 4
public let LocalConsoleFontMax:CGFloat = 20
public let SystemLogViewTag = 999999
public let systemLog_base_width:CGFloat = 240
public let systemLog_base_height:CGFloat = 148
public let borderLine:CGFloat = 5
public let diameter:CGFloat = 28

extension String {
    static let shareText = "Share Text..."
    static let copyText = "Copy Text"
    static let resizeConsole = "Resize Console"
    static let clearConsole = "Clear Console"
    static let userDefaults = "UserDefaults"
    static let Performance = "Performance"
    static let hideColorCheck = "Hide Color check"
    static let showColorCheck = "Show Color check"
    static let hideRulerCheck = "Hide Ruler check"
    static let showRulerCheck = "Show Ruler check"
    static let appDocument = "App Document"
    static let flex = "Flex"
    static let inApp = "InApp"
    static let devMaskClose = "Dev Mask close"
    static let devMaskOpen = "Dev Mask open"
    static let devMaskBubbleClose = "Dev Mask Bubble close"
    static let devMaskBubbleOpen = "Dev Mask Bubble open"
    static let hideViewFrames = "Hide View Frames"
    static let showViewFrames = "Show View Frames"
    static let systemReport = "System Report"
    static let displayReport = "Display Report"
    static let terminateApp = "Terminate App"
    static let respring = "Respring"
    static let debug = "Debug"
    static let debugController = "Debug Input Controller"
    static let crashLog = "Crash log"
    static let network = "Network"
    static let mockLocation = "MockLocation"
    static let log = "Log"
}

@MainActor
extension UIImage {
    static func resizeImage()-> UIImage {
        return UIImage(.arrow.upBackwardAndArrowDownForward).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static let shareImage = UIImage(.square.andArrowUp).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let copyImage = UIImage(.doc.onDocFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static func clearImage()-> UIImage {
        return UIImage(.delete.backward).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static func userDefaultsImage()-> UIImage {
        return UIImage(.doc.badgeGearshape).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static func colorImage()-> UIImage {
        return UIImage(.paintpalette).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static func rulerImage()-> UIImage {
        return UIImage(.ruler).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static let docImage = UIImage(.doc).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let dev3thPartyImage = UIImage(.plus.magnifyingglass).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static func maskImage()-> UIImage {
        return UIImage(.theatermasks).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static let maskBubbleImage = UIImage(systemName: "bubble.right")!.withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static func viewFrameImage()-> UIImage {
        return UIImage(.square.insetFilled).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static func cpuImage()-> UIImage {
        return UIImage(.cpu).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static func displayImage()-> UIImage {
        let result: String

        let hasHomeButton = UIScreen.main.value(forKey: "_displ" + "ayCorn" + "erRa" + "dius") as! CGFloat == 0

        if UIDevice.current.userInterfaceIdiom == .pad {
            if hasHomeButton {
                result = "ipad.homebutton"
            } else {
                result = "ipad"
            }
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            if hasHomeButton {
                result = "iphone.homebutton"
            } else {
                result = "iphone"
            }
        } else {
            result = "rectangle"
        }
        let deviceSymbol: String = result

        return UIImage(systemName: deviceSymbol)!.withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static let debugControllerImage = UIImage(.pencil).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let terminateAppImage = UIImage(.xmark).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static func respringImage()-> UIImage {
        return UIImage(.arrowtriangle.backward).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
    static let debugImage = UIImage(.ant).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let performanceImage = UIImage(.eyeglasses).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let crashLogImage = UIImage(.exclamationmark.triangleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let networkImage = UIImage(.globe).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let mockLocationImage = UIImage(.location.circleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let logFile = UIImage(.textformat.abc).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let InspectorImage = UIImage(.stethoscope).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    
    static func LoadedLibImage()-> UIImage {
        return UIImage(.cross.vial).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    }
}

final class PTConsoleWindow: UIWindow {

    static let shared = PTConsoleWindow()

    static let debugWindowLevel:UIWindow.Level = .alert + 200
    
    private weak var debugView: UIView?

    private init() {
        if let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {

            super.init(windowScene: scene)
        } else {
            super.init(frame: UIScreen.main.bounds)
        }

        windowLevel = PTConsoleWindow.debugWindowLevel
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }
        
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let rootView = rootViewController?.view else { return nil }

        let hitView = super.hitTest(point, with: event)

        // ✅ 关键：如果点到的是“背景 view”，直接穿透
        if hitView == rootView {
            return nil
        }

        return hitView
    }

    func show(view:UIView) {
        if debugView != nil {
            isHidden = false
            return
        }

        addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        debugView = view

        isHidden = false
    }
}

public enum PTLogLevel {
    case info
    case warning
    case error
    
    var color: UIColor {
        switch self {
        case .info: return .white
        case .warning: return .systemYellow
        case .error: return .systemRed
        }
    }
}

public final class PTLogBuffer {
    public struct LogItem {
        let text: String
        let level: PTLogLevel
    }

    private var logs: [LogItem] = []
    private let maxCount: Int
    
    init(maxCount: Int = 1000) {
        self.maxCount = maxCount
    }
    
    func append(_ text: String, level: PTLogLevel = .info) {
        logs.append(LogItem(text: text, level: level))
        if logs.count > maxCount {
            logs.removeFirst(logs.count - maxCount)
        }
    }
    
    func clear() {
        logs.removeAll()
    }
    
    func all() -> [LogItem] {
        logs
    }
}

public protocol PTDebugPlugin {
    
    /// 显示标题
    var title: String { get }
    
    /// 图标
    var image: UIImage? { get }
    
    /// 分组（关键🔥）
    var group: String { get }
    
    /// 排序（组内排序）
    var priority: Int { get }
    
    /// 是否可用（动态控制）
    var isEnabled: Bool { get }
    
    /// 行为
    var action: UIAction { get }
}

@MainActor
final class PTDebugPluginManager {
    
    static let shared = PTDebugPluginManager()
    
    private(set) var plugins: [PTDebugPlugin] = []
    
    private init() {}
    
    func clearAll() {
        plugins.removeAll()
    }
    
    func register(_ plugin: PTDebugPlugin) {
        plugins.append(plugin)
    }
    
    /// 分组后的插件
    func groupedPlugins() -> [String: [PTDebugPlugin]] {
        
        let enabledPlugins = plugins.filter { $0.isEnabled }
        
        return Dictionary(grouping: enabledPlugins, by: { $0.group })
    }
}

@objc public enum LocalConsoleActionType : Int {
    case CopyLog
    case ShareLog
    case RestoreUserDefult
    case AppUpdate
    case Debug
    case DebugSetting
    case NoActionCallBack
}

public typealias PTLocalConsoleBlock = (_ actionType:LocalConsoleActionType,_ debug:Bool,_ logUrl:URL) -> Void

@MainActor
@objcMembers
public class LocalConsole: NSObject {
    public static let shared = LocalConsole()
            
    // 新增一个游标，记录已经渲染到 UI 的日志索引
    private var lastFlushedIndex: Int = 0
    
    private let logBuffer = PTLogBuffer(maxCount: 50000)
    private var pendingUpdate = false
    private let throttleInterval: TimeInterval = 0.05
    private var dynamicLogs: [String: String] = [:]
    private var dynamicRange: NSRange?

    public var closeAllOutsideFunction:PTActionTask?
    public var leakCallback: (@MainActor @Sendable (PTPerformanceLeak) -> Void)?
    public var networkStatus = ""

    public var menu: UIMenuElement? = nil {
        didSet {
            Task { @MainActor in
                terminal!.menuButton.menu = makeMenu()
            }
        }
    }

    @MainActor public var isVisiable:Bool = PTCoreUserDefultsWrapper.shared.AppDebugMode {
        didSet {
            guard oldValue != isVisiable else { return }
            PTCoreUserDefultsWrapper.shared.AppDebugMode = isVisiable
            if isVisiable {
                createSystemLogView()
                terminal!.transform = .init(scaleX: 0.9, y: 0.9)
                UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.6) { [self] in
                    terminal!.transform = .init(scaleX: 1, y: 1)
                }.startAnimation()
                UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) { [self] in
                    terminal!.alpha = 1
                }.startAnimation()
                
                let animation = CABasicAnimation(keyPath: "shadowOpacity")
                animation.fromValue = 0
                animation.toValue = 0.5
                animation.duration = 0.6
                terminal!.layer.add(animation, forKey: animation.keyPath)
                terminal!.layer.shadowOpacity = 0.5
                if PTCoreUserDefultsWrapper.shared.AppDebbugMark {
                    maskOpenFunction()
                }
                
                commitTextChanges(requestMenuUpdate: true)
                watcherInit()
            } else {
                Inspector.sharedInstance.stop()
                PTNetworkHelper.shared.disable()
                UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) { [self] in
                    terminal!.transform = .init(scaleX: 0.9, y: 0.9)
                }.startAnimation()
                
                UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1) { [self] in
                    Task { @MainActor in
                        terminal!.alpha = 0
                        cleanSystemLogView()
                    }
                }.startAnimation()
            }
        }
    }
    
    public func setAttFontSize(@PTClampedPropertyWrapper(range:LocalConsoleFontMin...LocalConsoleFontMax) fontSizes:CGFloat) {
        PTCoreUserDefultsWrapper.shared.LocalConsoleCurrentFontSize = fontSizes
        terminal!.fontSize = fontSizes
    }
    
    public func setAttFontColor(color:UIColor) {
        terminal!.fontColor = color
    }
    
    public var terminal:PTTerminal?
    public var maskView:PTDevMaskView?

    @MainActor fileprivate let userdefaultShares = PTUserDefaultKeysAndValues.shares
    public var showAllUserDefaultsKeys = false {
        didSet {
            Task { @MainActor in
                userdefaultShares.showAllUserDefaultsKeys = showAllUserDefaultsKeys
            }
        }
    }
    
    func commitTextChanges(requestMenuUpdate menuUpdateRequested: Bool) {
        if menuUpdateRequested {
            // Update the context menu to show the clipboard/clear actions.
            Task { @MainActor in
                terminal!.menuButton.menu = makeMenu()
            }
        }
    }
    
    lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    var debugBordersEnabled = false {
        didSet {
            
            Swizzle(UIView.self) {
                #selector(UIView.layoutSubviews) <-> #selector(UIView.swizzled_layoutSubviews)
            }
            
            guard debugBordersEnabled else {
                GLOBAL_BORDER_TRACKERS.forEach {
                    $0.deactivate()
                }
                GLOBAL_BORDER_TRACKERS = []
                return
            }
            
            func subviewsRecursive(in _view: UIView) -> [UIView] {
                _view.subviews + _view.subviews.flatMap {
                    subviewsRecursive(in: $0)
                }
            }
            
            var allViews: [UIView] = []
            
            for window in UIApplication.shared.currentWindows! {
                allViews.append(contentsOf: subviewsRecursive(in: window))
            }
            allViews.forEach {
                let tracker = BorderManager(view: $0)
                GLOBAL_BORDER_TRACKERS.append(tracker)
                tracker.activate()
            }
        }
    }

    @MainActor private override init() {
        super.init()
        
        if isVisiable {
            createSystemLogView()
            if PTCoreUserDefultsWrapper.shared.AppDebbugMark {
                maskOpenFunction()
            }
            
            watcherInit()
        } else {
            cleanSystemLogView()
        }
    }
    
    @MainActor private func watcherInit() {
        Inspector.sharedInstance.start()
//        PTAlertDebugWindow.shared.show()
        UIView.swizzleMethods()
        UIWindow.db_swizzleMethods()
        URLSessionConfiguration.swizzleMethods()
        UIViewController.lvcdSwizzleLifecycleMethods()
        if PTCoreUserDefultsWrapper.shared.PTMockLocationOpen {
            CLLocationManager.swizzleMethods()
        }
        StdoutCapture.startCapturing()
        StderrCapture.startCapturing()
        StderrCapture.syncData()
        PTNetworkHelper.shared.enable()
        PTLaunchTimeTracker.measureAppStartUpTime()
        PTCrashManager.register()
        PTPerformanceLeakDetector.delay = 1
        PTPerformanceLeakDetector.callback = leakCallback
        
        Task {
            // 只要 Task 存活，这个 for 循环就会一直等待最新的网络状态
            for await currentStatus in PTNetWorkStatus.shared.statusStream {
                PTNSLogConsole("当前网络状态发生了改变：\(NetWorkStatus.valueName(type: currentStatus))")
                Task { @MainActor in
                    LocalConsole.shared.networkStatus = NetWorkStatus.valueName(type: currentStatus)
                }
            }
        }        
    }
    
    @MainActor public func cleanSystemLogView() {
        terminal?.removeFromSuperview()
        terminal = nil
        closeAllFunction()
    }
            
    var temporaryKeyboardHeightValueTracker: CGFloat?
    // MARK: Handle keyboard show/hide.
    private var keyboardHeight: CGFloat? = nil {
        didSet {
            Task { @MainActor in
                temporaryKeyboardHeightValueTracker = oldValue
                
                if possibleEndpoints.count > 2, terminal?.center != possibleEndpoints[0] && terminal?.center != possibleEndpoints[1] {
                    let nearestTargetPosition = nearestTargetTo(terminal?.center ?? .zero, possibleTargets: possibleEndpoints.suffix(2))
                    
                    UIViewPropertyAnimator(duration: 0.55, dampingRatio: 1) {
                        self.terminal?.center = nearestTargetPosition
                    }.startAnimation()
                }
                
                temporaryKeyboardHeightValueTracker = keyboardHeight
            }
        }
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            self.keyboardHeight = keyboardRectangle.height
        }
    }
    
    @objc func keyboardWillHide() {
        keyboardHeight = nil
    }

    @MainActor var possibleEndpoints: [CGPoint] {
        guard let appWindow = AppWindows else { return [] }
        
        let screenSize = appWindow.frame.size
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        let hasNotch = UIDevice.current.hasNotch
        let safeInsets = PTUtils.getCurrentVC()?.view.safeAreaInsets ?? .zero
        let isPortrait = screenSize.width < screenSize.height
        let orientation = UIDevice.current.orientation

        let isLandscape = isPhone && !isPortrait
        let isLeftNotch = isLandscape && hasNotch && orientation == .landscapeLeft
        let isRightNotch = isLandscape && hasNotch && orientation == .landscapeRight

        let topOffset: CGFloat = 12 + (hasNotch && isPortrait ? -10 : 0)
        let bottomOffset: CGFloat = (keyboardHeight ?? safeInsets.bottom) + 12 + (isLandscape ? 10 : 0)
        let leftOffset: CGFloat = (isLandscape ? 4 : 12) + (isRightNotch ? -16 : 0)
        let rightOffset: CGFloat = (isLandscape ? 4 : 12) + (isLeftNotch ? 16 : 0)

        let leftX = consoleSize.width / 2 + safeInsets.left + leftOffset
        let rightX = screenSize.width - consoleSize.width / 2 - safeInsets.right - rightOffset
        let topY = consoleSize.height / 2 + safeInsets.top + topOffset
        let bottomY = screenSize.height - consoleSize.height / 2 - bottomOffset

        let isLeftEdge = terminal?.frame.minX ?? 0 <= 0
        let isRightEdge = terminal?.frame.maxX ?? 0 >= screenSize.width
        let terminalCenterY = terminal?.center.y ?? 0
        let keyboardAwareScreenHeight = screenSize.height - (temporaryKeyboardHeightValueTracker ?? 0)
        let isTopHalf = terminalCenterY < keyboardAwareScreenHeight / 2
        let yOffset = isTopHalf ? topY : bottomY

        var endpoints: [CGPoint] = []

        if consoleSize.width < screenSize.width - 112 {
            // 四角點
            let topLeft = CGPoint(x: leftX, y: topY)
            let topRight = CGPoint(x: rightX, y: topY)
            let bottomLeft = CGPoint(x: leftX, y: bottomY)
            let bottomRight = CGPoint(x: rightX, y: bottomY)
            
            if isLeftEdge {
                endpoints = [topLeft, bottomLeft]
                if !isLeftNotch {
                    endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28, y: yOffset))
                }
            } else if isRightEdge {
                endpoints = [topRight, bottomRight]
                if !isRightNotch {
                    endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28, y: yOffset))
                }
            } else {
                endpoints = [topLeft, topRight, bottomLeft, bottomRight]
            }
        } else {
            // 垂直中線
            let centerTop = CGPoint(x: screenSize.width / 2, y: topY)
            let centerBottom = CGPoint(x: screenSize.width / 2, y: bottomY)
            endpoints = [centerTop, centerBottom]

            if isLeftEdge {
                endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28, y: yOffset))
            } else if isRightEdge {
                endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28, y: yOffset))
            }
        }

        return endpoints
    }
    
    let defaultConsoleSize = CGSize(width: systemLog_base_width, height: systemLog_base_height)

    /// The fixed size of the console view.
    lazy var consoleSize = defaultConsoleSize {
        didSet {
            terminal!.frame.size = consoleSize
                                    
            PTCoreUserDefultsWrapper.shared.PTLocalConsoleWidth = consoleSize.width
            PTCoreUserDefultsWrapper.shared.PTLocalConsoleHeight = consoleSize.height
        }
    }

    func snapToCachedEndpoint() {
        Task { @MainActor in
            let cachedConsolePosition = CGPoint(x: PTCoreUserDefultsWrapper.shared.PTLocalConsoleX ?? possibleEndpoints.first!.x, y: PTCoreUserDefultsWrapper.shared.PTLocalConsoleY ?? possibleEndpoints.first!.y)
            
            terminal!.center = cachedConsolePosition // Update console center so possibleEndpoints are calculated correctly.
            terminal!.center = nearestTargetTo(cachedConsolePosition, possibleTargets: possibleEndpoints)
        }
    }
    
    lazy var consoleWindow:PTBaseViewController = {
        let control = PTBaseViewController(hideBaseNavBar: true)
        control.view.backgroundColor = .clear
        control.view.isUserInteractionEnabled = true
        return control
    }()

    lazy var scenesDebug:PTAlertDebugView = {
        let view = PTAlertDebugView(frame: CGRect(x: 40, y: 100, width: 280, height: 250))
        return view
    }()
    
    @MainActor public func createSystemLogView() {

        guard terminal == nil else { return }

        let window = PTConsoleWindow.shared
        window.rootViewController = consoleWindow
        window.isHidden = false
        let terminal = PTTerminal(inView: consoleWindow.view ,
                                  frame: CGRect(x: 0,
                                                y: CGFloat.kNavBarHeight_Total,
                                                width: PTCoreUserDefultsWrapper.shared.PTLocalConsoleWidth ?? consoleSize.width,
                                                height: PTCoreUserDefultsWrapper.shared.PTLocalConsoleHeight ?? consoleSize.height)
        )
        terminal.tag = SystemLogViewTag

        consoleWindow.view.addSubviews([terminal,scenesDebug])

        SwizzleTool.swizzleContextMenuReverseOrder()

        self.terminal = terminal

        snapToCachedEndpoint()

        setupTerminalActions()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    private func setupTerminalActions() {

        terminal?.dragEnd = { [weak self] in
            Task { @MainActor in
                // After the PiP is thrown, determine the best corner and re-target it there.
                let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
                
                let projectedPosition = CGPoint(x: self!.terminal!.center.x + project(initialVelocity: self!.terminal!.x, decelerationRate: decelerationRate), y: self!.terminal!.center.y + project(initialVelocity: self!.terminal!.y, decelerationRate: decelerationRate))
                
                let nearestTargetPosition = nearestTargetTo(projectedPosition, possibleTargets: self!.possibleEndpoints)
                
                let relativeInitialVelocity = CGVector(dx: relativeVelocity(forVelocity: self!.terminal!.x, from: self!.terminal!.center.x, to: nearestTargetPosition.x), dy: relativeVelocity(forVelocity: self!.terminal!.x, from: self!.terminal!.center.y, to: nearestTargetPosition.y))
                
                let timingParameters = UISpringTimingParameters(damping: 0.85, response: 0.45, initialVelocity: relativeInitialVelocity)
                let positionAnimator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
                positionAnimator.addAnimations { [self] in
                    self!.terminal!.center = nearestTargetPosition
                }
                positionAnimator.startAnimation()
                PTCoreUserDefultsWrapper.shared.PTLocalConsoleX = nearestTargetPosition.x
                PTCoreUserDefultsWrapper.shared.PTLocalConsoleY = nearestTargetPosition.y
            }
        }

        Task { @MainActor in
            terminal?.menuButton.showsMenuAsPrimaryAction = true
            terminal?.menuButton.menu = makeMenu()
        }
    }
    
    var hasShortened = false
    
    public var isCharacterLimitDisabled = false
    public var isCharacterLimitWarningDisabled = false

    public func print(_ items: Any, level: PTLogLevel = .info) {
        logBuffer.append("\(items)", level: level)
        scheduleUIUpdate()
    }
    
    func scheduleUIUpdate() {
        guard !pendingUpdate else { return }
        pendingUpdate = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + throttleInterval) { [weak self] in
            guard let self else { return }
            self.pendingUpdate = false
            self.flushUI()
        }
    }
    
    @MainActor
    private func flushUI() {
        guard let terminal else { return }
        
        let allLogs = logBuffer.all()
        let totalCount = allLogs.count
        
        // 如果没有新日志，直接返回
        guard lastFlushedIndex < totalCount else { return }
        
        // 1. 只获取真正的新日志（避免重复拼接）
        let newLogs = allLogs[lastFlushedIndex..<totalCount]
        
        // 2. 将所有新日志在内存中合并为一整块，而不是多次操作 UI
        let combinedText = newLogs.map { $0.text }.joined(separator: "\n") + "\n"
        
        // 取第一条的 Level 颜色作为基准（或者你可以改造 appendLogs 支持多颜色块）
        let item = PTLogBuffer.LogItem(text: combinedText, level: newLogs.last?.level ?? .info)
        
        // 3. 一次性送给 Terminal 渲染
        terminal.appendLog(item)
        
        // 4. 更新游标
        lastFlushedIndex = totalCount
        
        commitTextChanges(requestMenuUpdate: true)
    }
    
    var dynamicReportTimer: Timer? {
        willSet {
            timerInvalidationCounter = 0
            dynamicReportTimer?.invalidate()
        }
    }
    
    var timerInvalidationCounter = 0
}

extension LocalConsole : UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [self] _ in
            makeMenu() // 返回你之前创建的菜单
        }
    }
}

extension LocalConsole:UITextFieldDelegate {}

//MARK: Menu
extension LocalConsole {
    @MainActor
    func makeMenu() -> UIMenu {
        var menuContent: [UIMenuElement] = []
        
        // 性能优化：直接读取 isEmpty 属性，避免全量文本加载到内存
        let isTerminalEmpty = terminal?.systemText?.pt_isEmpty ?? true

        // 1. 构建顶部基础操作区 (分享、调整大小)
        menuContent.append(contentsOf: buildTopMenuElements(isTerminalEmpty: isTerminalEmpty))

        // 2. 构建核心的 Debug 开发者菜单
        menuContent.append(buildDebugMenu())

        // 3. 注入外部可能传入的自定义菜单
        if let customMenu = menu {
            menuContent.append(customMenu)
        }

        // 4. 构建底部的清理操作 (仅在控制台有文本时显示)
        if !isTerminalEmpty {
            menuContent.append(UIMenu(title: "", options: .displayInline, children: [buildClearAction()]))
        }

        return UIMenu(title: "", children: menuContent)
    }
    
    func rulerAction() {
        Task { @MainActor in
            if PTViewRulerPlugin.share.showed {
                PTViewRulerPlugin.share.hide()
            } else {
                PTViewRulerPlugin.share.show()
            }
        }
    }
    
    func colorAction() {
        Task { @MainActor in
            if PTColorPickPlugin.share.showed {
                PTColorPickPlugin.share.close()
            } else {
                PTColorPickPlugin.share.show()
            }
        }
    }
        
    func resizeAction() {
        PTGCDManager.shared.delayOnMain(time: 0.1) {
            ResizeController.shared.isActive.toggle()
            ResizeController.shared.platterView.reveal()
        }
    }
    
    func shareAction() {
        Task { @MainActor in
            let activityViewController = PTActivityViewController(text: terminal!.systemText!.pt_fullText)
            activityViewController.previewNumberOfLines = 10
            PTUtils.getCurrentVC()?.present(activityViewController, animated: true)
        }
    }
    
    /// Clear text in the console view.
    public func clear() {
        terminal?.systemText?.text = ""
        logBuffer.clear()
        lastFlushedIndex = 0 // 清空时重置游标
    }
    
    func loadedLibs() {
        let vc = PTLoadedLibsViewController()
        consoleSheetPresent(vc: vc)
    }
    
    func logFileOpen() {
        let vc = PTLogConsoleViewController()
        consoleSheetPresent(vc: vc)
    }
    
    func mockLocationOpen() {
        let vc = PTDebugLocationViewController()
        consoleSheetPresent(vc: vc)
    }
    
    func networkWatcherOpen() {
        let vc = PTNetworkWatcherViewController()
        consoleSheetPresent(vc: vc)
    }
    
    func performanceControlOpen() {
        let vc = PTDebugPerformanceViewController()
        consoleSheetPresent(vc: vc)
    }
    
    func crashLogControlOpen() {
        let vc = PTCrashLogViewController()
        consoleSheetPresent(vc: vc)
    }
    
    func consoleSheetPresent(vc:PTBaseViewController) {
        let nav = PTBaseNavControl(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        let options = PTSheetOptions()
        UIViewController.currentPresentToSheet(vc: nav,sizes: [.fullscreen],options: options)
    }
    
    func maskOpenFunction() {
        if maskView != nil {
            PTCoreUserDefultsWrapper.shared.AppDebbugMark = false
            maskView?.removeFromSuperview()
            maskView = nil
        } else {
            Task { @MainActor in
                PTCoreUserDefultsWrapper.shared.AppDebbugMark = true
                
                let maskConfig = PTDevMaskConfig()
                maskView = PTDevMaskView(config: maskConfig)
                maskView?.frame = AppWindows!.frame
                AppWindows?.addSubview(maskView!)
            }
        }
    }
    
    func maskOpenBubbleFunction() {
        PTCoreUserDefultsWrapper.shared.AppDebbugTouchBubble = !PTCoreUserDefultsWrapper.shared.AppDebbugTouchBubble
        if maskView != nil {
            maskView!.showTouch = PTCoreUserDefultsWrapper.shared.AppDebbugTouchBubble
        }
    }

    @MainActor func closeAllFunction() {
        debugBordersEnabled = false
        PTViewRulerPlugin.share.hide()
        PTColorPickPlugin.share.close()
        PTNetworkHelper.shared.disable()
        StderrCapture.stopCapturing()
        PTDebugPerformanceToolKit.shared.floatingShow = false
        PTDebugPerformanceToolKit.shared.performanceClose()
        ResizeController.shared.isActive = false
        PTCoreUserDefultsWrapper.shared.AppDebbugMark = false
        maskView?.removeFromSuperview()
        maskView = nil
//        PTAlertDebugWindow.shared.dismiss()
        closeAllOutsideFunction?()
    }

    func debugControllerAction() {
        let vc = PTDebugViewController()
        self.consoleSheetPresent(vc: vc)
    }
    
    func copyTextAction() {
        terminal!.systemText!.pt_fullText.copyToPasteboard()
    }
    
    @MainActor func respringAction() {
        guard let window = AppWindows else { return }
        
        window.layer.cornerRadius = UIScreen.main.value(forKey: "_displ" + "ayCorn" + "erRa" + "dius") as! CGFloat
        window.layer.masksToBounds = true
        
        UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1) {
            window.transform = .init(scaleX: 0.96, y: 0.96)
            window.alpha = 0
        }.startAnimation()
        
        // Concurrently run these snapshots to decrease the time to crash.
        for _ in 0...1000 {
            PTGCDManager.shared.runOnBackground {

                // This will cause jetsam to terminate backboardd.
                while true {
                    Task { @MainActor in
                        window.snapshotView(afterScreenUpdates: false)
                    }
                }
            }
        }
    }

    func terminateApplicationAction() {
        UIApplication.shared.perform(NSSelectorFromString("terminateWithSuccess"))
    }

    func viewFramesAction() {
        debugBordersEnabled.toggle()
    }
    
    @MainActor func watchViewsAction() {
#if canImport(InAppViewDebugger)
        InAppViewDebugger.present()
#endif
    }
        
    @MainActor func flexAction() {
#if canImport(FLEX)
        if FLEXManager.shared.isHidden {
            FLEXManager.shared.showExplorer()
        } else {
            FLEXManager.shared.hideExplorer()
        }
#endif
    }
    
    func documentAction() {
        let vc = PTFileBrowserViewController()
        consoleSheetPresent(vc: vc)
    }    
}

///Menu Subs
extension LocalConsole {
    
    /// 1. 构建顶部的基础操作区
    @MainActor
    private func buildTopMenuElements(isTerminalEmpty: Bool) -> [UIMenuElement] {
        var elements: [UIMenuElement] = []
        
        // 性能优化：弃用遍历视图树找方向，直接根据物理屏幕比例判断
        let screenSize = UIScreen.main.bounds.size
        let isLandscapePhone = UIDevice.current.userInterfaceIdiom == .phone && screenSize.width > screenSize.height
        
        let resize = UIAction(title: .resizeConsole, image: UIImage.resizeImage()) { [weak self] _ in self?.resizeAction() }
        if isLandscapePhone {
            resize.attributes = .disabled
            resize.subtitle = "Portrait Orientation Only"
        }
        
        if !isTerminalEmpty {
            let share: UIAction
            if #available(iOS 16, *) {
                share = UIAction(title: .shareText, image: UIImage.shareImage) { [weak self] _ in self?.shareAction() }
            } else {
                share = UIAction(title: .copyText, image: UIImage.copyImage) { [weak self] _ in self?.copyTextAction() }
            }
            // 合并显示分享和调整大小
            elements.append(UIMenu(title: "", options: .displayInline, children: [share, resize]))
        } else {
            // 为空时只显示调整大小
            elements.append(UIMenu(title: "", options: .displayInline, children: [resize]))
        }
        
        return elements
    }
    
    /// 2. 构建核心的开发者调试菜单 (包含所有子模块)
    @MainActor
    private func buildDebugMenu() -> UIMenu {
        var debugActions: [UIMenuElement] = []
        
        // 2.1 动态加载的特殊菜单
        debugActions.append(buildUserDefaultsMenu())
        debugActions.append(buildMaskMenu())
        
        // 2.2 常规工具操作集合
        var normalActions: [UIAction] = [
            UIAction(title: "Inspectors", image: UIImage.InspectorImage) { _ in Task { Inspector.sharedInstance.present(animated: true) } },
            UIAction(title: .log, image: UIImage.logFile) { [weak self] _ in self?.logFileOpen() },
            UIAction(title: .mockLocation, image: UIImage.mockLocationImage) { [weak self] _ in self?.mockLocationOpen() },
            UIAction(title: .network, image: UIImage.networkImage) { [weak self] _ in self?.networkWatcherOpen() },
            UIAction(title: .crashLog, image: UIImage.crashLogImage) { [weak self] _ in self?.crashLogControlOpen() },
            UIAction(title: .Performance, image: UIImage.performanceImage) { [weak self] _ in self?.performanceControlOpen() },
            UIAction(title: PTColorPickPlugin.share.showed ? .hideColorCheck : .showColorCheck, image: UIImage.colorImage()) { [weak self] _ in self?.colorAction() },
            UIAction(title: PTViewRulerPlugin.share.showed ? .hideRulerCheck : .showRulerCheck, image: UIImage.rulerImage()) { [weak self] _ in self?.rulerAction() },
            UIAction(title: .appDocument, image: UIImage.docImage) { [weak self] _ in self?.documentAction() },
            UIAction(title: debugBordersEnabled ? .showViewFrames : .hideViewFrames, image: UIImage.viewFrameImage()) { [weak self] _ in
                guard let self = self else { return }
                self.viewFramesAction()
                self.terminal?.menuButton.menu = self.makeMenu() // 刷新菜单状态
            },
            UIAction(title: .systemReport, image: UIImage.cpuImage()) { [weak self] _ in self?.systemReport() },
            UIAction(title: .displayReport, image: UIImage.displayImage()) { [weak self] _ in self?.displayReport() },
            UIAction(title: "Loaded libs", image: UIImage.LoadedLibImage()) { [weak self] _ in self?.loadedLibs() }
        ]
        
        #if canImport(FLEX)
        normalActions.append(UIAction(title: .flex, image: UIImage.dev3thPartyImage) { [weak self] _ in Task { @MainActor in self?.flexAction() } })
        #endif
        
        #if canImport(InAppViewDebugger)
        normalActions.append(UIAction(title: .inApp, image: UIImage.dev3thPartyImage) { [weak self] _ in Task { @MainActor in self?.watchViewsAction() } })
        #endif
        
        // 性能优化：使用系统底层的本地化对比，极速排序
        let sortedActions = normalActions.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        debugActions.append(contentsOf: sortedActions)
        
        // 2.3 破坏性操作 (红色警告样式)
        let destructActions = [
            UIAction(title: .debugController, image: UIImage.debugControllerImage, attributes: .destructive) { [weak self] _ in self?.debugControllerAction() },
            UIAction(title: .terminateApp, image: UIImage.terminateAppImage, attributes: .destructive) { [weak self] _ in self?.terminateApplicationAction() },
            UIAction(title: .respring, image: UIImage.respringImage(), attributes: .destructive) { [weak self] _ in self?.respringAction() }
        ]
        
        return UIMenu(title: .debug, image: UIImage.debugImage, children: [
            UIMenu(title: "", options: .displayInline, children: debugActions),
            UIMenu(title: "", options: .displayInline, children: destructActions)
        ])
    }
    
    /// 3. 构建 UserDefaults 专属动态菜单
    @MainActor
    private func buildUserDefaultsMenu() -> UIMenu {
        let deferredList = UIDeferredMenuElement.uncached { [weak self] completion in
            guard let self = self else {
                completion([])
                return
            }
            
            var actions: [UIAction] = []
            let keyValues = self.userdefaultShares.keyAndValues()
            
            if keyValues.isEmpty {
                actions.append(UIAction(title: "No Entries", attributes: .disabled) { _ in })
            } else {
                keyValues.forEach { dict in
                    // 安全解包，避免应用崩溃
                    guard let firstKey = dict.keys.first, let firstVal = dict.values.first else { return }
                    
                    let action = UIAction(title: firstKey, image: nil) { [weak self] _ in
                        guard let self = self else { return }
                        UIAlertController.base_alertVC(
                            title: "Key\n" + firstKey,
                            msg: "\nValue\n" + "\(firstVal)",
                            okBtns: ["Copy Value", "Clear Value", "Edit value"],
                            cancelBtn: "Cancel",
                            moreBtn: { index, title in
                                if title == "Copy Value" {
                                    "\(firstVal)".copyToPasteboard()
                                } else if title == "Clear Value" {
                                    UserDefaults.standard.removeObject(forKey: firstKey)
                                } else if title == "Edit value" {
                                    UIAlertController.base_textfield_alertVC(
                                        title: "Edit\n" + firstKey,
                                        okBtn: "⭕️",
                                        cancelBtn: "Cancel",
                                        placeHolders: [firstKey],
                                        textFieldTexts: ["\(firstVal)"],
                                        keyboardType: [.default],
                                        textFieldDelegate: self
                                    ) { result in
                                        if let newValue = result.values.first {
                                            UserDefaults.standard.setValue(newValue, forKey: firstKey)
                                        }
                                    }
                                }
                            }
                        )
                    }
                    action.subtitle = "\(firstVal)"
                    actions.append(action)
                }
                
                actions.append(
                    UIAction(title: "Clear Defaults", image: UIImage(.trash), attributes: .destructive) { _ in
                        keyValues.forEach { dict in
                            if let key = dict.keys.first { UserDefaults.standard.removeObject(forKey: key) }
                        }
                    }
                )
            }
            completion(actions)
        }
        
        return UIMenu(title: .userDefaults, image: UIImage.userDefaultsImage(), children: [deferredList])
    }
    
    /// 4. 构建 Mask 遮罩专属动态菜单
    @MainActor
    private func buildMaskMenu() -> UIMenu {
        let deferredMaskList = UIDeferredMenuElement.uncached { [weak self] completion in
            guard let self = self else {
                completion([])
                return
            }
            
            var actions: [UIAction] = []
            
            let maskOpen = UIAction(title: self.maskView != nil ? .devMaskClose : .devMaskOpen, image: UIImage.maskImage()) { [weak self] _ in
                self?.maskOpenFunction()
            }
            actions.append(maskOpen)

            if self.maskView != nil {
                let maskTouchBubble = UIAction(title: PTCoreUserDefultsWrapper.shared.AppDebbugTouchBubble ? .devMaskBubbleClose : .devMaskBubbleOpen, image: UIImage.maskBubbleImage) { [weak self] _ in
                    self?.maskOpenBubbleFunction()
                }
                actions.append(maskTouchBubble)
            }
            completion(actions)
        }
        
        return UIMenu(title: "Dev Mask", image: UIImage.maskImage(), children: [deferredMaskList])
    }
    
    /// 5. 构建底部清理操作
    @MainActor
    private func buildClearAction() -> UIAction {
        return UIAction(title: .clearConsole, image: UIImage.clearImage(), attributes: .destructive) { [weak self] _ in self?.clear() }
    }
}

//MARK: System report
extension LocalConsole {
    func systemReport() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }

            if self.dynamicReportTimer?.isValid == true {
                self.dynamicReportTimer?.invalidate()
                self.dynamicReportTimer = nil
            }

            self.printStaticSystemInfo()

            self.dynamicReportTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                let safeTimer = PTTimerBox(timer: timer)
                PTGCDManager.shared.runOnMain { [weak self] in
                    guard let self,let terminal = self.terminal?.systemText,!terminal.pt_fullText.stringIsEmpty() else {
                        safeTimer.timer.invalidate()
                        return
                    }

                    Task {
                        self.updateDynamicSystemInfo()
                    }
                }
            }
        }
    }
    
    @MainActor private func updateDynamicSystemInfo() {
        dynamicLogs["ThermalState"] = "ThermalState: \(SystemReport.shared.thermalState)"
        dynamicLogs["SystemUptime"] = "SystemUptime: \(ProcessInfo.processInfo.systemUptime.formattedString ?? "")"
        dynamicLogs["LowPowerMode"] = "LowPowerMode: \(ProcessInfo.processInfo.isLowPowerModeEnabled)"

        refreshDynamicSection()
    }
    
    @MainActor
    private func refreshDynamicSection() {
        guard let textStorage = terminal?.systemText?.textStorage else { return }

        textStorage.beginEditing()
        
        // 增加安全校验，防止多线程插入导致的 Range 越界 Crash
        if let range = dynamicRange, range.location + range.length <= textStorage.length {
            textStorage.deleteCharacters(in: range)
        }

        let start = textStorage.length
        let combined = "\n--- System Monitor ---\n" + dynamicLogs.values.joined(separator: "\n") + "\n"
        
        let attr = NSAttributedString(string: combined, attributes: [
            .font: UIFont.systemFont(ofSize: PTCoreUserDefultsWrapper.shared.LocalConsoleCurrentFontSize, weight: .bold, design: .monospaced),
            .foregroundColor: UIColor.systemGreen // 动态数据给个绿色方便区分
        ])
        
        textStorage.append(attr)
        let end = textStorage.length
        
        dynamicRange = NSRange(location: start, length: end - start)
        
        textStorage.endEditing()
        // 动态刷新时不强制 scrollToBottom，以免打断用户翻看历史日志
    }
    
    private func printStaticSystemInfo() {
        // 提取静态信息构造字符串（保持你原来的逻辑）
        // 加入所有 volume、battery 等静态内容的打印
        var volumeAvailableCapacityForImportantUsageString = ""
        var volumeAvailableCapacityForOpportunisticUsageString = ""
        var volumesString = ""
        volumeAvailableCapacityForImportantUsageString = String(format: "%d", Device.volumeAvailableCapacityForImportantUsage!)
        volumeAvailableCapacityForOpportunisticUsageString = String(format: "%d", Device.volumeAvailableCapacityForOpportunisticUsage!)
        volumesString = String(format: "%d", Device.volumes!)

        var hzString = ""
        hzString = "MaxFrameRate: \(UIScreen.main.maximumFramesPerSecond) Hz"

        let supportApplePencilString = UIDevice.pt.supportApplePencil.description

        let systemText = """
                ModelName: \(SystemReport.shared.gestaltMarketingName)
                ModelIdentifier: \(SystemReport.shared.gestaltModelIdentifier)
                Architecture: \(SystemReport.shared.gestaltArchitecture)
                Firmware: \(SystemReport.shared.gestaltFirmwareVersion)
                KernelVersion: \(SystemReport.shared.kernel) \(SystemReport.shared.kernelVersion)
                SystemVersion: \(SystemReport.shared.versionString)
                OSCompileDate: \(SystemReport.shared.compileDate)
                Memory: \(UIDevice.pt.memoryTotal) GB
                ProcessorCores: \(Int(UIDevice.pt.processorCount))
                ThermalState: \(SystemReport.shared.thermalState)
                SystemUptime: \(UIDevice.pt.systemUptime)
                LowPowerMode: \(UIDevice.pt.lowPowerMode)
                IsSimulator: \(Device.current.isSimulator ? "Yes" : "No")
                IsTouchIDCapable: \(Device.current.isTouchIDCapable ? "Yes" : "No")
                IsFaceIDCapable: \(Device.current.isFaceIDCapable ? "Yes" : "No")
                HasBiometricSensor:\(Device.current.hasBiometricSensor ? "Yes" : "No")
                HasSensorHousing: \(Device.current.hasSensorHousing ? "Yes" : "No")
                HasRoundedDisplayCorners: \(Device.current.hasRoundedDisplayCorners ? "Yes" : "No")
                Has3dTouchSupport: \(Device.current.has3dTouchSupport ? "Yes" : "No")
                SupportsWirelessCharging: \(Device.current.supportsWirelessCharging ? "Yes" : "No")
                HasLidarSensor: \(Device.current.hasLidarSensor ? "Yes" : "No")
                PPI: \(Device.current.ppi ?? 0)
                ScreenSize: \(UIScreen.main.bounds.size)
                ScreenCornerRadius: \(UIScreen.main.value(forKey: "_displ" + "ayCorn" + "erRa" + "dius") as! CGFloat)
                ScreenScale: \(UIScreen.main.scale)
                \(hzString)
                Brightness: \(String(format: "%.2f", UIDevice.pt.brightness))
                IsGuidedAccessSessionActive: \(Device.current.isGuidedAccessSessionActive ? "Yes" : "No")
                BatteryState: \(Device.current.batteryState!)
                BatteryLevel: \(String(format: "%d", Device.current.batteryLevel!))
                VolumeTotalCapacity: \(String(format: "%d", Device.volumeTotalCapacity!))
                VolumeAvailableCapacity: \(String(format: "%d", Device.volumeAvailableCapacity!))
                VolumeAvailableCapacityForImportantUsage: \(volumeAvailableCapacityForImportantUsageString)
                VolumeAvailableCapacityForOpportunisticUsage: \(volumeAvailableCapacityForOpportunisticUsageString)
                Volumes: \(volumesString)
                ApplePencilSupport: \(String(format: "%@", supportApplePencilString))
                HasCamera: \(Device.current.hasCamera ? "Yes" : "No")
                HasNormalCamera: \(Device.current.hasWideCamera ? "Yes" : "No")
                HasWideCamera: \(Device.current.hasWideCamera ? "Yes" : "No")
                HasTelephotoCamera: \(Device.current.hasTelephotoCamera ? "Yes" : "No")
                HasUltraWideCamera: \(Device.current.hasUltraWideCamera ? "Yes" : "No")
                IsJailBroken: \(UIDevice.pt.isJailBroken ? "Yes" : "No")
                """

        print(systemText)
    }
    
    func displayReport() {
        
        Task { @MainActor [self] in

            let safeAreaInsets = PTUtils.getCurrentVC()?.view.safeAreaInsets ?? .zero
            
            print(
                  """
                  Screen Size:       \(UIScreen.main.bounds.size)
                  Corner Radius:     \(UIScreen.main.value(forKey: "_displ" + "ayCorn" + "erRa" + "dius") as! CGFloat)
                  Screen Scale:      \(UIScreen.main.scale)
                  Max Frame Rate:    \(UIScreen.main.maximumFramesPerSecond) Hz
                  Brightness:        \(String(format: "%.2f", UIScreen.main.brightness))
                  
                  Safe Area Insets:  top:    \(String(describing: safeAreaInsets.top))
                                     left:   \(String(describing: safeAreaInsets.left))
                                     bottom: \(String(describing: safeAreaInsets.bottom))
                                     right:  \(String(describing: safeAreaInsets.right))
                  """
            )
        }
    }
}

public class PTTerminal:PFloatingButton {
    public var systemText : PTInvertedTextView?
    public lazy var menuButton = ConsoleMenuButton()

    private lazy var textStorage: NSTextStorage? = {
        systemText?.textStorage
    }()
    
    public override init(inView superview: UIView?, frame: CGRect) {
        super.init(inView: superview, frame: frame)
        backgroundColor = .black
        draggable = true
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.5
        layerShadowOffset = CGSize(width: 0, height: 2)
        layer.cornerRadius = 22
        tag = SystemLogViewTag
        layer.cornerCurve = .continuous

        let borderView = UIView()
        borderView.layer.borderWidth = borderLine
        borderView.layer.borderColor = UIColor.randomColor.cgColor
        borderView.layer.cornerRadius = (layer.cornerRadius) + 1
        borderView.layer.cornerCurve = .continuous
        borderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(borderView)
        borderView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
        
        systemText = PTInvertedTextView()
        systemText?.isEditable = false
        systemText?.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        systemText?.isSelectable = false
        systemText?.showsVerticalScrollIndicator = false
        systemText?.contentInsetAdjustmentBehavior = .never
        systemText?.backgroundColor = .clear
        addSubview(systemText!)
        systemText?.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview().inset(borderLine * 4)
        }
        systemText?.layer.cornerRadius = (layer.cornerRadius) - 2
        systemText?.layer.cornerCurve = .continuous

        
        menuButton = ConsoleMenuButton()
        menuButton.backgroundColor = UIColor(white: 0.2, alpha: 0.95)
        menuButton.setImage(UIImage(.ellipsis).withConfiguration(UIImage.SymbolConfiguration(pointSize: 17)), for: .normal)
        menuButton.imageView?.contentMode = .scaleAspectFit
        menuButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        addSubview(menuButton)
        menuButton.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(40)
            make.right.bottom.equalToSuperview().inset(borderLine)
        }
        menuButton.viewCorner(radius: diameter / 2)
        
        menuButton.tintColor = UIColor(white: 1, alpha: 0.75)
    }
        
    public override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        systemText?.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview().inset(borderLine * 4)
        }

        menuButton.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(40)
            make.right.bottom.equalToSuperview().inset(borderLine)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // 给系统一个明确的形状，杜绝离屏渲染！
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: layer.cornerRadius
        ).cgPath
        
        // 你原来的布局代码
        systemText?.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview().inset(borderLine * 4)
        }
    }
    
    var fontColor: UIColor = UIColor(hexString: PTCoreUserDefultsWrapper.shared.LocalConsoleCurrentFontColor)!
    var fontSize: CGFloat = PTCoreUserDefultsWrapper.shared.LocalConsoleCurrentFontSize

    public func setAttributedText(_ string: String) {
        let att:ASAttributedString =  ASAttributedString("\(string)",.paragraph(.lineSpacing(5),.headIndent(7)),.font(.systemFont(ofSize: fontSize, weight: .semibold, design: .monospaced)),.foreground(fontColor))

        systemText?.attributed.text = att
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var currentAttributes: [NSAttributedString.Key: Any] {
        [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold, design: .monospaced),
            .foregroundColor: fontColor
        ]
    }
    
    public func appendLog(_ item: PTLogBuffer.LogItem) {
        guard let textStorage = systemText?.textStorage else { return }
        
        let attr = NSAttributedString(
            string: item.text,
            attributes: currentAttributes
        )
        
        // 使用 beginEditing 和 endEditing 将多次重绘合并为一次
        textStorage.beginEditing()
        textStorage.append(attr)
        
        // 🔴 关键性能保护：防止 TextView 内存无限暴涨！
        // 即使 Buffer 限制了 50000 条，UITextView 的渲染层如果超过几万行一样会卡死
        let maxCharacterCount = 100_000
        if textStorage.length > maxCharacterCount {
            let overage = textStorage.length - maxCharacterCount
            // 截断头部最旧的日志
            textStorage.deleteCharacters(in: NSRange(location: 0, length: overage))
        }
        
        textStorage.endEditing()
        
        scrollToBottom()
    }
    
    private func scrollToBottom() {
        guard let textView = systemText else { return }
        
        let offsetY = textView.contentSize.height - textView.bounds.height
        if offsetY > 0 {
            textView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        }
    }
}

extension String {
    func stringAfterFirstOccurenceOf(delimiter: String) -> String? {
       guard let upperIndex = (self.range(of: delimiter)?.upperBound) else { return nil }
       let trailingString: String = .init(self.suffix(from: upperIndex))
       return trailingString
    }
}

extension UIDevice {
    var hasNotch: Bool {
        return (AppWindows?.safeAreaInsets.bottom ?? 0) > 0
    }
}

extension UITextView {
    
    var pt_isEmpty: Bool {
        return self.textStorage.length == 0
    }
    
    var pt_fullText: String {
        return textStorage.string
    }
    
    var pt_isVisuallyEmpty: Bool {
        textStorage.string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }
}
