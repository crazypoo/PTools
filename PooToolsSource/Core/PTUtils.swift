//
//  PTUtils.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers
import Kingfisher

// English: These MainActor hooks let optional UI integrations extend Core without creating a reverse module dependency.
// Español: Estos hooks de MainActor permiten ampliar Core con integraciones UI opcionales sin crear una dependencia inversa entre módulos.
// 中文：这些 MainActor 钩子让可选 UI 集成扩展 Core，同时避免形成反向模块依赖。
@MainActor
public enum PTUIKitRuntimeHooks {
    public static var makeApplicationWindow: ((UIWindowScene) -> UIWindow?)?
    public static var consoleVisibilityHandler: ((Bool) -> Void)?
    public static var restoreConsoleState: (() -> Void)?
    public static var settingsBundleHandler: (() -> Void)?
    public static var webImageOptionsProvider: ((Int?, TimeInterval?) -> KingfisherOptionsInfo)?
    public static var interceptPush: ((UIViewController, PTActionTask?) -> Bool)?
    public static var shouldTrackViewBorders: (() -> Bool)?
    public static var shouldPreserveContextMenuOrder: ((UIMenu) -> Bool)?
    public static var presentationWillBegin: (() -> Void)?
    public static var presentationDidComplete: (() -> Void)?
    public static var controllerTransitionDidComplete: (() -> Void)?
    // English: Debug can receive lifecycle snapshots without making Core depend on a Debug collector.
    // Español: Debug puede recibir snapshots del ciclo de vida sin que Core dependa de un collector de Debug.
    // 中文：Debug 可以接收生命周期快照，同时 Core 不依赖 Debug Collector。
    public static var controllerLifecycleHandler: ((String, String) -> Void)?
}

// English: Describes the visual surface policy shared by Core UI components.
// Español: Describe la política de superficies visuales compartida por los componentes UI de Core.
// 中文：描述 Core UI 组件共享的视觉表面策略。
public enum PTVisualStyle: String, CaseIterable, Equatable, Hashable, Sendable {
    case automatic
    case classic
    case material
    case glass
}

@MainActor
public enum PTVisualStyleResolver {
    // English: Creates the best supported effect while respecting Reduce Transparency and iOS 17 fallback.
    // Español: Crea el efecto compatible más adecuado respetando Reducir transparencia y la alternativa de iOS 17.
    // 中文：在遵循“降低透明度”的同时创建当前系统支持的效果，并保留 iOS 17 回退。
    public static func makeEffect(for style: PTVisualStyle,
                                  blurStyle: UIBlurEffect.Style = .systemMaterial,
                                  interactive: Bool = false) -> UIVisualEffect? {
        guard style != .classic, !UIAccessibility.isReduceTransparencyEnabled else {
            return nil
        }

        #if compiler(>=6.2)
        if #available(iOS 26.0, *), (style == .glass || style == .automatic) {
            let effect = UIGlassEffect(style: .regular)
            effect.isInteractive = interactive
            return effect
        }
        #endif

        return UIBlurEffect(style: blurStyle)
    }

    // English: Applies an effect or a dynamic opaque fallback without changing the view hierarchy.
    // Español: Aplica un efecto o una alternativa opaca dinámica sin cambiar la jerarquía de vistas.
    // 中文：在不改变视图层级的情况下应用效果，或切换到动态不透明回退背景。
    public static func apply(to effectView: UIVisualEffectView,
                             style: PTVisualStyle = .automatic,
                             blurStyle: UIBlurEffect.Style = .systemMaterial,
                             fallbackColor: UIColor = .systemBackground,
                             interactive: Bool = false) {
        let effect = makeEffect(for: style, blurStyle: blurStyle, interactive: interactive)
        effectView.effect = effect
        effectView.backgroundColor = effect == nil
            ? fallbackColor.resolvedColor(with: effectView.traitCollection)
            : .clear
    }
}

@MainActor
public enum PTUIAccessibility {
    // English: Reads the current system accessibility settings at the point of use.
    // Español: Lee la configuración de accesibilidad del sistema en el momento de uso.
    // 中文：在使用时读取系统当前的辅助功能设置，避免缓存过期状态。
    public static var reduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    public static var reduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    // English: Scales an existing font through Dynamic Type while preserving its family and weight.
    // Español: Escala una fuente existente mediante Dynamic Type conservando su familia y peso.
    // 中文：通过 Dynamic Type 缩放现有字体，同时保留字体族和字重。
    public static func scaledFont(_ font: UIFont, maximumPointSize: CGFloat? = nil) -> UIFont {
        guard font.pointSize.isFinite, font.pointSize > 0 else { return font }
        if let maximumPointSize, maximumPointSize.isFinite, maximumPointSize > 0 {
            return UIFontMetrics.default.scaledFont(for: font, maximumPointSize: maximumPointSize)
        }
        return UIFontMetrics.default.scaledFont(for: font)
    }

    // English: Applies Dynamic Type to a label without replacing custom text or layout constraints.
    // Español: Aplica Dynamic Type a una etiqueta sin reemplazar su texto ni sus restricciones.
    // 中文：为标签启用 Dynamic Type，不改变现有文本和布局约束。
    public static func applyDynamicType(to label: UILabel,
                                        font: UIFont,
                                        maximumPointSize: CGFloat? = nil) {
        label.font = scaledFont(font, maximumPointSize: maximumPointSize)
        label.adjustsFontForContentSizeCategory = true
    }

    // English: Applies Dynamic Type to a button title label.
    // Español: Aplica Dynamic Type a la etiqueta de título de un botón.
    // 中文：为按钮标题标签启用 Dynamic Type。
    public static func applyDynamicType(to button: UIButton,
                                        font: UIFont,
                                        maximumPointSize: CGFloat? = nil) {
        guard let titleLabel = button.titleLabel else { return }
        applyDynamicType(to: titleLabel, font: font, maximumPointSize: maximumPointSize)
    }

    // English: Returns zero when motion reduction is enabled so callers can keep state transitions intact.
    // Español: Devuelve cero cuando se reduce el movimiento para conservar las transiciones de estado.
    // 中文：开启“减弱动态效果”时返回零，调用方仍可保持状态切换逻辑完整。
    public static func animationDuration(_ duration: TimeInterval) -> TimeInterval {
        guard !reduceMotionEnabled, duration.isFinite else { return 0 }
        return max(0, duration)
    }
}

/*
 ░░░░░░░░░▄░░░░░░░░░░░░░░▄░░░░
 ░░░░░░░░▌▒█░░░░░░░░░░░▄▀▒▌░░░
 ░░░░░░░░▌▒▒█░░░░░░░░▄▀▒▒▒▐░░░
 ░░░░░░░▐▄▀▒▒▀▀▀▀▄▄▄▀▒▒▒▒▒▐░░░
 ░░░░░▄▄▀▒░▒▒▒▒▒▒▒▒▒█▒▒▄█▒▐░░░
 ░░░▄▀▒▒▒░░░▒▒▒░░░▒▒▒▀██▀▒▌░░░
 ░░▐▒▒▒▄▄▒▒▒▒░░░▒▒▒▒▒▒▒▀▄▒▒▌░░
 ░░▌░░▌█▀▒▒▒▒▒▄▀█▄▒▒▒▒▒▒▒█▒▐░░
 ░▐░░░▒▒▒▒▒▒▒▒▌██▀▒▒░░░▒▒▒▀▄▌░
 ░▌░▒▄██▄▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▌░
 ▀▒▀▐▄█▄█▌▄░▀▒▒░░░░░░░░░░▒▒▒▐░
 ▐▒▒▐▀▐▀▒░▄▄▒▄▒▒▒▒▒▒░▒░▒░▒▒▒▒▌
 ▐▒▒▒▀▀▄▄▒▒▒▄▒▒▒▒▒▒▒▒░▒░▒░▒▒▐░
 ░▌▒▒▒▒▒▒▀▀▀▒▒▒▒▒▒░▒░▒░▒░▒▒▒▌░
 ░▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▒▄▒▒▐░░
 ░░▀▄▒▒▒▒▒▒▒▒▒▒▒░▒░▒░▒▄▒▒▒▒▌░░
 ░░░░▀▄▒▒▒▒▒▒▒▒▒▒▄▄▄▀▒▒▒▒▄▀░░░
 ░░░░░░▀▄▄▄▄▄▄▀▀▀▒▒▒▒▒▄▄▀░░░░░
 ░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▀▀░░░░░░░░
 */

//lipo -create xxxxxxxx/xxxxxxxxx(真机) xxxxxxxxx/xxxxxxxxx(模拟器) -output (输出路径)
/*
 //MARK: 测试须要用到的
 pod 'FLEX', :configurations => ['Debug']
 pod 'InAppViewDebugger', :configurations => ['Debug']
 pod 'LookinServer', :configurations => ['Debug']
 pod 'LifetimeTracker', :configurations => ['Debug']
 pod 'WoodPeckeriOS', :configurations => ['Debug']
 pod "HyperioniOS/Core", :configurations => ['Debug']
 pod 'HyperioniOS/AttributesInspector', :configurations => ['Debug'] # Optional plugin
 pod 'HyperioniOS/Measurements', :configurations => ['Debug'] # Optional plugin
 pod 'HyperioniOS/SlowAnimations', :configurations => ['Debug'] # Optional plugin
 */

@MainActor
public struct PTTimerBox {
    let timer: Timer
}

let GlobalVideoExts: Set<String> = ["mp4","mov","m4v","avi","mkv","3gp","webm"]

// Fast URL media classification for local and remote resources.
// Clasificación rápida del tipo multimedia de recursos locales y remotos.
// 快速判断本地和远程资源的媒体类型。
extension URL {
    var pt_isVideoResource: Bool {
        let pathExtension = pathExtension.lowercased()
        if GlobalVideoExts.contains(pathExtension) {
            return true
        }

        guard let type = UTType(filenameExtension: pathExtension) else { return false }
        return type.conforms(to: .movie) || type.conforms(to: .video)
    }
}

@objc public enum PTUrlStringVideoType:Int {
    case MP4
    case MOV
    case ThreeGP
    case UNKNOW
}

@objc public enum PTAboutImageType:Int {
    case JPEG
    case JPEG2000
    case PNG
    case GIF
    case TIFF
    case WEBP
    case BMP
    case ICO
    case ICNS
    case HEIC
    case UNKNOW
}

@objc public enum GradeType:Int {
    case normal
    case TenThousand
    case HundredMillion
}

public func PTIVarList(_ className:String) -> [String] {
    var listName = [String]()
    var count : UInt32 = 0
    let list = class_copyIvarList(NSClassFromString(className), &count)
    
    if let safeList = list {
        for i in 0..<Int(count) {
            let ivar = safeList[i]
            let name = ivar_getName(ivar)
            if let findName = name {
                listName.append(String(cString: findName))
            }
            if let type = ivar_getTypeEncoding(ivar),let findName = name {
                PTNSLogConsole("\(String(cString: findName) + "<---->" + String(cString: type))",loggerType: .utils)
            }
        }
        free(safeList)
    }
    return listName
}

public func PTPropertyList(_ classString: String) -> [String] {
    var propertyListName = [String]()
    var count : UInt32 = 0
    let list = class_copyPropertyList(NSClassFromString(classString), &count)
    guard let safeList = list else { return propertyListName }

    for i in 0..<Int(count) {
        let property: objc_property_t = safeList[i]
        let name = property_getName(property)
        
        if let type = property_getAttributes(property) {
            PTNSLogConsole("\(String(cString: name) + "<---->" + String(cString: type))",loggerType: .utils)
        }
        guard let propertyName = NSString(utf8String: name) as String? else {
            PTNSLogConsole("Couldn't unwrap property name for \(property)",loggerType: .utils)
            break
        }
        propertyListName.append(propertyName)
    }
    free(safeList)
    return propertyListName
}

public func PTMethodsList(_ classString: String) -> [Selector] {
    var methodNum: UInt32 = 0
    var list = [Selector]()
    let methods = class_copyMethodList(NSClassFromString(classString), &methodNum)
    for index in 0..<numericCast(methodNum) {
        if let met = methods?[index] {
            let selector = method_getName(met)
            PTNSLogConsole("\(classString)的方法：\(selector)",loggerType: .utils)
            // list.append(met)
            list.append(selector)
        }
    }
    free(methods)
    return list
}

/// 判断一个类是否是自定义类
///
/// - Parameters:
///   - cls: AnyClass
/// - Returns: 自定义类返回true,系统类返回false
public func checkCustomClass(for cls: AnyClass) -> Bool {
    let bundle = Bundle(for: cls)
    return bundle == .main
}

public typealias PTImageLoadHandler = (_ error:Error?,_ sourceURL:URL?,_ image:UIImage?) -> Void

@MainActor
@objcMembers
public class PTUtils: NSObject {
        
    public static let share = PTUtils()
    public var timer: DispatchSourceTimer?

    // MARK: - Bundle
    ///- Bundle
    public class func cgBaseBundle()->Bundle {
        return Bundle(for: self)
    }
                
    //MARK: 获取一个输入内最大的一个值
    ///获取一个输入内最大的一个值
    public class func maxOne<T:Comparable>( _ seq:[T]) -> T? {
        return seq.max()
    }
                        
    //MARK: 这个方法可以用于UITextField中,检测金额输入
    public class func isValidAmountInput(text:NSString,
                                          range:NSRange,
                                          replacementString:NSString) -> Bool {
        guard range.location >= 0,
              range.length >= 0,
              range.location <= text.length,
              range.length <= text.length - range.location else {
            return false
        }
        let updatedLength = text.length - range.length + replacementString.length
        guard updatedLength <= 20 else { return false }
        let result = text.replacingCharacters(in: range, with: replacementString as String)
        return result.isMoneyString()
    }
            
    // MARK: - 輸出 URL (影片)
    public class func outputURL() -> URL {
        let documentsDirectory = FileManager.pt.CachesDirectory()
        let fileName = "PTVideo_\(UUID().uuidString).mp4"
        // Convert the legacy String path to URL before appending the file name.
        // Convierte la ruta String heredada a URL antes de añadir el nombre del archivo.
        // 先把旧版 String 路径转换成 URL，再追加文件名。
        let cacheDirectoryURL = URL(fileURLWithPath: documentsDirectory, isDirectory: true)
        return cacheDirectoryURL.appendingPathComponent(fileName, isDirectory: false)
    }
    
    /// 字符串转类
    public class func classFromString(_ className:String) -> AnyClass? {
        if let cls = NSClassFromString(className) {
            return cls
        }
        guard var name = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String else {
            return nil
        }
        name = name.replacingOccurrences(of: "-", with: "_")
        return NSClassFromString("\(name).\(className)")
    }
    
    // MARK: - 監聽截圖事件
    @discardableResult // 允许调用方忽略返回值（如果他们有其他方式管理）
    public static func observeScreenshot(_ action: @Sendable @escaping (Notification) -> Void) -> NSObjectProtocol {
        // http://stackoverflow.com/questions/13484516/ios-detection-of-screenshot
        return NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: .main, using: action)
    }
    
    // MARK: - 強制退出 App
    public static func exitApp(){
        abort()
    }
}

public extension PTUtils {
    // MARK: - 當前畫面 VC
    class func getCurrentVC(from rootVC:UIViewController) -> UIViewController {
        var visited = Set<ObjectIdentifier>()
        return resolveCurrentViewController(from: rootVC, visited: &visited)
    }

    /// 统一解析当前控制器，避免不同入口各自维护一套层级判断。
    private class func resolveCurrentViewController(from viewController: UIViewController,
                                                     visited: inout Set<ObjectIdentifier>) -> UIViewController {
        guard visited.insert(ObjectIdentifier(viewController)).inserted else {
            return viewController
        }

        if let presented = viewController.presentedViewController,
           !presented.isBeingDismissed {
            return resolveCurrentViewController(from: presented, visited: &visited)
        }

        if let sheet = viewController as? PTSheetViewController {
            return resolveCurrentViewController(from: sheet.childViewController, visited: &visited)
        }

        if let sideMenu = viewController as? PTSideMenuControl,
           let content = sideMenu.contentViewController {
            return resolveCurrentViewController(from: content, visited: &visited)
        }

        if let tabBar = viewController as? UITabBarController,
           let selected = tabBar.selectedViewController {
            return resolveCurrentViewController(from: selected, visited: &visited)
        }

        if let navigationController = viewController as? UINavigationController,
           let visible = navigationController.visibleViewController {
            return resolveCurrentViewController(from: visible, visited: &visited)
        }

        if let pageController = viewController as? UIPageViewController,
           let visible = pageController.viewControllers?.first {
            return resolveCurrentViewController(from: visible, visited: &visited)
        }

        return viewController
    }

    @MainActor class func getCurrentVC() -> UIViewController? {
        PTSceneContext.currentViewController()
    }
    
    // MARK: - Navigation Controller 查找
    fileprivate class func findFirstNavController(responder: UIResponder?) -> UINavigationController? {
        var responder = responder
        while let next = responder?.next {
            if let vc = next as? UIViewController, let nav = vc.navigationController {
                return nav
            }
            responder = next
        }
        return nil
    }

    // MARK: - 取得頂部控制器
    @MainActor class func getTopViewController(_ base: UIViewController? = nil) -> UIViewController? {
        let root = base ?? PTSceneContext.rootViewController()
        guard let root else { return nil }
        return getCurrentVC(from: root)
    }
    
    // MARK: - Root Controller
    @MainActor class func getRootViewController() -> UIViewController? {
        PTSceneContext.rootViewController()
    }
    
    //MARK: - 需要注册的时候传入一个导航包含的控制器
    @MainActor class func setRootViewController(_ navController: UIViewController) {
        PTSceneContext.activeWindow()?.rootViewController = navController
    }
    
    // MARK: - 活躍 VC
    @MainActor class func getActivityViewController() -> UIViewController? {
        PTSceneContext.currentViewController()
    }

    @MainActor class func visibleVC() -> UIViewController? {
        PTSceneContext.currentViewController()
    }

    // Configure console window.
    @MainActor class func fetchWindow() -> UIWindow? {
        PTSceneContext.activeWindow()
    }
                        
    class dynamic func topMost(of viewController: UIViewController?) -> UIViewController? {
        guard let viewController else { return nil }
        var visited = Set<ObjectIdentifier>()
        return resolveCurrentViewController(from: viewController, visited: &visited)
    }
}

public extension PTUtils {
    
    class func findSuperviews(of view: UIView) -> [UIView] {
        var superviews: [UIView] = []
        var current = view.superview
        while let view = current {
            superviews.append(view)
            current = view.superview
        }
        return superviews
    }

    class func findCommonSuperviews(view1: UIView, view2: UIView) -> [UIView] {
        let views1 = Set(findSuperviews(of: view1))
        let views2 = findSuperviews(of: view2)
        return views2.filter { views1.contains($0) }
    }
    
    @MainActor class func isViewAddedToWindow(ofType type: AnyClass) -> Bool {
        AppWindows?.subviews.contains { $0.isKind(of: type) } ?? false
    }
}

//MARK: Translation
public extension PTUtils {
    
    @MainActor class func push(_ vc: UIViewController) {
        guard let current = getCurrentVC(),
              let nav = current.navigationController,
              nav.transitionCoordinator == nil,
              !nav.viewControllers.contains(where: { $0 === vc }) else { return }
        vc.hidesBottomBarWhenPushed = true
        nav.pushViewController(vc, animated: true)
    }

    @MainActor class func modal(_ vc: UIViewController,
                     presentationStyle: UIModalPresentationStyle = .fullScreen,
                     transitionStyle: UIModalTransitionStyle = .coverVertical) {
        
        guard let current = getCurrentVC(),
              current.presentedViewController == nil,
              vc.presentingViewController == nil else { return }

        // 优先使用传递进来的样式
        vc.modalTransitionStyle = transitionStyle
        vc.modalPresentationStyle = presentationStyle

        current.present(vc, animated: true, completion: nil)
    }

    @MainActor class func popToVC(ofType type: UIViewController.Type) {
        guard let nav = getTopViewController()?.navigationController else { return }
        if let target = nav.viewControllers.last(where: { $0.isKind(of: type) }) {
            nav.popToViewController(target, animated: true)
        } else {
            nav.popViewController(animated: true)
        }
    }

    //MARK: - 跳转到首页
    @MainActor class func popToRootVC() {
        getTopViewController()?.navigationController?.popToRootViewController(animated: true)
    }

    @MainActor class func returnFrontVC() {
        guard let vc = getCurrentVC() else { return }
        if vc.presentingViewController != nil {
            vc.dismiss(animated: true)
        } else if let nav = vc.navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        }
    }

    @MainActor class func pt_pushViewController(_ vc:UIViewController,completion:PTActionTask? = nil) {
        if PTUIKitRuntimeHooks.interceptPush?(vc, completion) == true {
            return
        }
        push(vc)
    }
    
    @MainActor class func modalDismissBeforePush(_ vc: UIViewController) {
        if let visiableVC = PTUtils.getTopViewController(nil), visiableVC.presentingViewController != nil {
            visiableVC.dismiss(animated: false) {
                push(vc)
            }
        } else {
            push(vc)
        }
    }
    
    @MainActor class func pusbWindowNavRoot(_ vc: UIViewController) {
        guard let root = PTSceneContext.rootViewController() else { return }
        if let nav = root as? UINavigationController,
           nav.transitionCoordinator == nil {
            nav.pushViewController(vc, animated: true)
        } else {
            push(vc)
        }
    }
}

public extension PTUtils {
    @MainActor static func compareVersionWithServerVersion(_ version: String) -> ComparisonResult {
        let currentVersion = kAppVersion ?? "0.0.0"
        return currentVersion.compare(version,options: .numeric)
    }
}

//MARK: OC-FUNCTION
public extension PTUtils {
    class func oc_isiPhoneSeries() -> Bool {
        Gobal_device_info.isFaceIDCapable
    }
}

// MARK: - 1. 目标类的扩展 (存放 Swizzled 方法)

extension UIView {
    /// 配合 _UIContextMenuListView 的替换方法
    /// 因为 _UIContextMenuListView 是私有类，它继承自 UIView，
    /// 将方法写在 UIView 的 extension 中，Runtime 就能顺利通过 class_getInstanceMethod 找到它。
    @MainActor @objc public func swizzled_reverses_Action_Order() -> Bool {
        if let menu = self.value(forKey: "displayed" + "Menu") as? UIMenu,
           PTUIKitRuntimeHooks.shouldPreserveContextMenuOrder?(menu) == true {
            return false
        }

        if let orig = self.value(forKey: "_" + "reverses" + "Action" + "Order") as? Bool {
            return orig
        }
        
        return false
    }
}

extension UIWindow {
    /// 配合 UIWindow 的替换方法
    @MainActor @objc public func swizzled_did_add_subview(_ subview: UIView) {
        if !SwizzleTool.pauseDidAddSubviewSwizzledClosure {
            if let closure = SwizzleTool.swizzledDidAddSubviewClosure {
                closure()
            }
        }
    }
}

@MainActor
public class SwizzleTool: NSObject {
    
    public static var swizzledDidAddSubviewClosure: PTActionTask?
    public static var pauseDidAddSubviewSwizzledClosure: Bool = false

    // 为了防止重复执行 Swizzle，可以使用一个静态标记或 dispatch_once (在 Swift 中通常用静态属性的惰性初始化实现)
    private static var isContextMenuSwizzled = false
    private static var isDidAddSubviewSwizzled = false

    /// 确保上下文菜单始终以非反转顺序显示
    public static func swizzleContextMenuReverseOrder() {
        guard !isContextMenuSwizzled else { return }
        // 1. 获取私有类
        guard let targetClass = NSClassFromString("_" + "UI" + "Context" + "Menu" + "List" + "View") else {
            PTNSLogConsole("Swizzle Error: 找不到 _UIContextMenuListView 类")
            return
        }
        Swizzle(targetClass, owner: "core.context-menu") {
            NSSelectorFromString("reverses" + "Action" + "Order") <-> #selector(UIView.swizzled_reverses_Action_Order)
        }
        isContextMenuSwizzled = true
               
        PTNSLogConsole("✅ ContextMenu Swizzle 成功")
    }
    
    
    public static func swizzleDidAddSubview(_ closure: @escaping PTActionTask) {
        // 保存闭包
        Self.swizzledDidAddSubviewClosure = closure
        guard !isDidAddSubviewSwizzled else { return }
        
        // 使用你的全局 Swizzle 语法
        Swizzle(UIWindow.self, owner: "core.window-subview") {
            #selector(UIWindow.didAddSubview(_:)) <-> #selector(UIWindow.swizzled_did_add_subview(_:))
        }
        
        isDidAddSubviewSwizzled = true
        PTNSLogConsole("✅ UIWindow didAddSubview Swizzle 成功")
    }
}
