//
//  PTUtils.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

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

@MainActor public func deviceSafeAreaInsets() -> UIEdgeInsets {
    return AppWindows?.safeAreaInsets ?? .zero
}

// Scene-aware window resolution shared by UI helpers.
// Resolución de ventanas consciente de la escena y compartida por las utilidades de UI.
// 供 UI 辅助方法共用的场景感知窗口解析入口。
@MainActor
public enum PTSceneContext {
    public static func activeWindow(in scene: UIWindowScene? = nil) -> UIWindow? {
        let scenes: [UIWindowScene]
        if let scene {
            scenes = [scene]
        } else {
            var foregroundActiveScenes = [UIWindowScene]()
            var foregroundInactiveScenes = [UIWindowScene]()
            for connectedScene in UIApplication.shared.connectedScenes {
                guard let windowScene = connectedScene as? UIWindowScene else { continue }
                switch windowScene.activationState {
                case .foregroundActive:
                    foregroundActiveScenes.append(windowScene)
                case .foregroundInactive:
                    foregroundInactiveScenes.append(windowScene)
                case .background, .unattached:
                    continue
                @unknown default:
                    foregroundInactiveScenes.append(windowScene)
                }
            }
            scenes = foregroundActiveScenes + foregroundInactiveScenes
        }

        var windows = [UIWindow]()
        for windowScene in scenes {
            windows.append(contentsOf: windowScene.windows)
        }

        for window in windows where window.isKeyWindow && window.windowLevel == .normal && window.rootViewController != nil {
            return window
        }
        for window in windows where window.windowLevel == .normal && window.rootViewController != nil {
            return window
        }
        for window in windows where window.isKeyWindow && window.rootViewController != nil {
            return window
        }
        for windowScene in scenes {
            if let sceneWindow = (windowScene.delegate as? PTWindowSceneDelegate)?.window {
                return sceneWindow
            }
        }
        // Never call the public AppWindows adapter from this resolver; that would recurse.
        // Nunca llames al adaptador público AppWindows desde este resolvedor; provocaría una recursión.
        // 解析器不能回调公共的 AppWindows 适配器，否则会形成递归。
        return nil
    }

    public static func currentViewController(in scene: UIWindowScene? = nil) -> UIViewController? {
        guard let rootViewController = activeWindow(in: scene)?.rootViewController else {
            return nil
        }
        return PTUtils.getCurrentVC(from: rootViewController)
    }
}

// Shared bridge for UI work scheduled from any execution context.
// Puente compartido para programar trabajo de UI desde cualquier contexto de ejecución.
// 统一从任意执行上下文调度 UI 操作的桥接入口。
public enum PTMainActorBridge {
    @discardableResult
    public static func perform(_ operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            guard !Task.isCancelled else { return }
            operation()
        }
    }

    @discardableResult
    public static func after(_ delay: TimeInterval,
                             operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            guard delay.isFinite, delay >= 0 else { return }
            let boundedDelay = min(delay, TimeInterval(UInt64.max) / 1_000_000_000)
            do {
                try await Task.sleep(nanoseconds: UInt64(boundedDelay * 1_000_000_000))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            operation()
        }
    }

    @discardableResult
    public static func cancellableAfter(_ delay: TimeInterval,
                                        operation: @escaping @MainActor @Sendable () -> Void) -> Task<Void, Never> {
        after(delay, operation: operation)
    }
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

    /// 按当前场景和窗口层级选择业务窗口，避免误选调试悬浮窗。
    @MainActor private class func activeWindow() -> UIWindow? {
        PTSceneContext.activeWindow()
    }
    
    @MainActor class func getCurrentVC() -> UIViewController? {
        guard let root = activeWindow()?.rootViewController else { return nil }
        return getCurrentVC(from: root)
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
        let root = base ?? activeWindow()?.rootViewController
        guard let root else { return nil }
        return getCurrentVC(from: root)
    }
    
    // MARK: - Root Controller
    @MainActor class func getRootViewController() -> UIViewController? {
        return activeWindow()?.rootViewController
    }
    
    //MARK: - 需要注册的时候传入一个导航包含的控制器
    @MainActor class func setRootViewController(_ navController: UIViewController) {
        activeWindow()?.rootViewController = navController
    }
    
    // MARK: - 活躍 VC
    @MainActor class func getActivityViewController() -> UIViewController? {
        guard let rootVC = activeWindow()?.rootViewController else { return nil }
        return getCurrentVC(from: rootVC)
    }

    @MainActor class func visibleVC() -> UIViewController? {
        return getActivityViewController()
    }

    // Configure console window.
    @MainActor class func fetchWindow() -> UIWindow? {
        activeWindow()
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
#if POOTOOLS_DEBUG
        let share = LocalConsole.shared
        if share.isVisiable {
            let nav = PTBaseNavControl(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            PTUtils.getCurrentVC()?.present(nav, animated: true, completion: {
                completion?()
                SwizzleTool.swizzleDidAddSubview {
                    // Configure console window.
                    Task { @MainActor in
                        if let currentVC = PTUtils.getCurrentVC(),let findMask = share.maskView {
                            currentVC.view.window?.bringSubviewToFront(findMask)
                        }
                    }
                }
            })

        } else {
            push(vc)
        }
#else
        push(vc)
#endif
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
        guard let root = activeWindow()?.rootViewController else { return }
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
    @objc public func swizzled_reverses_Action_Order() -> Bool {
        if let menu = self.value(forKey: "displayed" + "Menu") as? UIMenu,
           menu.title == "Debug" || menu.title == "User" + "Defaults" {
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
        // 1. 获取私有类
        guard let targetClass = NSClassFromString("_" + "UI" + "Context" + "Menu" + "List" + "View") else {
            PTNSLogConsole("Swizzle Error: 找不到 _UIContextMenuListView 类")
            return
        }
        Swizzle(targetClass) {
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
        Swizzle(UIWindow.self) {
            #selector(UIWindow.didAddSubview(_:)) <-> #selector(UIWindow.swizzled_did_add_subview(_:))
        }
        
        isDidAddSubviewSwizzled = true
        PTNSLogConsole("✅ UIWindow didAddSubview Swizzle 成功")
    }
}
