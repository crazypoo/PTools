//
//  PTUtils.swift
//  Diou
//
//  Created by ken lam on 2021/10/8.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import AVFoundation
import SwiftDate
import SwifterSwift

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

@inline(__always) private func isIPhoneXSeries() -> Bool {
    var iPhoneXSeries = false
    if UIDevice.current.userInterfaceIdiom != .phone {
        return iPhoneXSeries
    }

    let mainWindow:UIView = AppWindows!
    if (mainWindow.safeAreaInsets.bottom) > 0.0 {
        iPhoneXSeries = true
    }

    return iPhoneXSeries
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

public func deviceSafeAreaInsets() -> UIEdgeInsets {
    var insets: UIEdgeInsets = .zero
    insets = AppWindows?.safeAreaInsets ?? .zero
    return insets
}

public func PTIVarList(_ className:String) -> [String] {
    var listName = [String]()
    var count : UInt32 = 0
    let list = class_copyIvarList(NSClassFromString(className), &count)
    for i in 0..<Int(count) {
        let ivar = list![i]
        let name = ivar_getName(ivar)
        let type = ivar_getTypeEncoding(ivar)
        PTNSLogConsole("\(String(cString: name!) + "<---->" + String(cString: type!))",levelType: PTLogMode,loggerType: .Utils)
        listName.append(String(cString: name!))
    }
    free(list)
    return listName
}

public func PTPropertyList(_ classString: String) -> [String] {
    var propertyListName = [String]()
    var count : UInt32 = 0
    let list = class_copyPropertyList(NSClassFromString(classString), &count)
    for i in 0..<Int(count) {
        let property: objc_property_t = list![i]
        let name = property_getName(property)
        let type = property_getAttributes(property)
        PTNSLogConsole("\(String(cString: name) + "<---->" + String(cString: type!))",levelType: PTLogMode,loggerType: .Utils)
        guard let propertyName = NSString(utf8String: name) as String? else {
            PTNSLogConsole("Couldn't unwrap property name for \(property)",levelType: PTLogMode,loggerType: .Utils)
            break
        }
        propertyListName.append(propertyName)
    }
    free(list)
    return propertyListName
}

public func PTMethodsList(_ classString: String) -> [Selector] {
    var methodNum: UInt32 = 0
    var list = [Selector]()
    let methods = class_copyMethodList(NSClassFromString(classString), &methodNum)
    for index in 0..<numericCast(methodNum) {
        if let met = methods?[index] {
            let selector = method_getName(met)
            PTNSLogConsole("\(classString)的方法：\(selector)",levelType: PTLogMode,loggerType: .Utils)
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
    public class func maxOne<T:Comparable>( _ seq:[T]) -> T {

        assert(seq.count>0)
        return seq.reduce(seq[0]){
            max($0, $1)
        }
    }
                        
    //MARK: 这个方法可以用于UITextField中,检测金额输入
    public class func isValidAmountInput(text:NSString,
                                          range:NSRange,
                                          replacementString:NSString) -> Bool {
        let updatedLength = text.length - range.length + replacementString.length
        guard updatedLength <= 20 else { return false }
        let result = text.replacingCharacters(in: range, with: replacementString as String)
        return result.isMoneyString()
    }
            
    // MARK: - 輸出 URL (影片)
    public class func outputURL() -> URL {
        let documentsDirectory = FileManager.pt.CachesDirectory()
        let fileName = "\(Date().getTimeStamp()).mp4"
        let outputURL = documentsDirectory.appendingPathComponent(fileName)
        if #available(iOS 16.0, *) {
            return URL(filePath: outputURL)
        } else {
            return URL(fileURLWithPath: outputURL)
        }
    }
    
    /// 字符串转类
    public class func classFromString(_ className:String) -> AnyClass? {
        guard var name = Bundle.main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String else {
            return nil
        }
        name = name.replacingOccurrences(of: "-", with: "_")
        return NSClassFromString("\(name).\(className)")
    }
    
    // MARK: - 監聽截圖事件
    public static func observeScreenshot(_ action: @escaping (Notification) -> Void) {
        // http://stackoverflow.com/questions/13484516/ios-detection-of-screenshot
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: .main, using: action)
    }
    
    // MARK: - 強制退出 App
    public static func exitApp(){
        abort()
    }
}

public extension PTUtils {
    // MARK: - 當前畫面 VC
    class func getCurrentVC(from rootVC:UIViewController) -> UIViewController {
        switch rootVC {
        case let tabBar as UITabBarController:
            return getCurrentVC(from: tabBar.selectedViewController ?? tabBar)
        case let nav as UINavigationController:
            return getCurrentVC(from: nav.visibleViewController ?? nav)
        case let presentedVC where presentedVC.presentedViewController != nil:
            return getCurrentVC(from: presentedVC.presentedViewController!)
        default:
            return rootVC
        }
    }
    
    class func getCurrentVC() -> UIViewController {
        let root = AppWindows?.rootViewController ?? UIViewController()
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
    class func getTopViewController(_ base: UIViewController? = nil) -> UIViewController? {
        let baseVC = base ?? AppWindows?.rootViewController
        guard let vc = baseVC else { return nil }

        if let nav = vc as? UINavigationController {
            return getTopViewController(nav.topViewController)
        } else if let tab = vc as? UITabBarController {
            return getTopViewController(tab.selectedViewController)
        } else if let presented = vc.presentedViewController {
            return getTopViewController(presented)
        } else {
            return vc
        }
    }
    
    // MARK: - Root Controller
    class func getRootViewController() -> UIViewController? {
        return AppWindows?.rootViewController
    }
    
    //MARK: - 需要注册的时候传入一个导航包含的控制器
    class func setRootViewController(_ navController: UIViewController) {
#if DEBUG
        assert(navController is UINavigationController, "Root 必須是 UINavigationController")
#endif
        AppWindows?.rootViewController = navController
    }
    
    // MARK: - 活躍 VC
    class func getActivityViewController() -> UIViewController? {
        guard let rootVC = AppWindows?.rootViewController else {
            return nil
        }
        
        var current = rootVC
        while let presented = current.presentedViewController {
            current = presented
        }
        return current
    }

    class func visibleVC() -> UIViewController? {
        if let nav = getActivityViewController() as? UINavigationController {
            return nav.visibleViewController
        }
        return getActivityViewController()
    }

    // Configure console window.
    class func fetchWindow() -> UIWindow? {
        if #available(iOS 15.0, *) {
            let windowScene = UIApplication.shared
                .connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .first
            
            if let windowScene = windowScene as? UIWindowScene, let keyWindow = windowScene.keyWindow {
                return keyWindow
            }
            return nil
        } else {
            return UIApplication.shared.windows.first
        }
    }
                        
    class dynamic func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return topMost(of: presentedViewController)
        }

        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return topMost(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return topMost(of: visibleViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
           pageViewController.viewControllers?.count == 1 {
            return topMost(of: pageViewController.viewControllers?.first)
        }
        return viewController
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
    
    class func isViewAddedToWindow(ofType type: AnyClass) -> Bool {
        AppWindows?.subviews.contains { $0.isKind(of: type) } ?? false
    }
}

//MARK: Translation
public extension PTUtils {
    
    class func push(_ vc: UIViewController) {
        guard let current = getActivityViewController() else { return }
        let nav = (current as? UINavigationController) ?? findFirstNavController(responder: current)
        vc.hidesBottomBarWhenPushed = true
        nav?.pushViewController(vc, animated: true)
    }

    class func modal(_ vc: UIViewController) {
        guard let current = getActivityViewController() else { return }
        guard vc.presentedViewController == nil else { return }

        vc.modalTransitionStyle = .coverVertical
        vc.modalPresentationStyle = .fullScreen

        current.present(vc, animated: true, completion: nil)
    }

    class func popToVC(ofType type: UIViewController.Type) {
        guard let nav = getTopViewController()?.navigationController else { return }
        if let target = nav.viewControllers.last(where: { $0.isKind(of: type) }) {
            nav.popToViewController(target, animated: true)
        } else {
            nav.popViewController(animated: true)
        }
    }

    //MARK: - 跳转到首页
    class func popToRootVC() {
        getTopViewController()?.navigationController?.popToRootViewController(animated: true)
    }

    class func returnFrontVC() {
        let vc = PTUtils.getCurrentVC()
        if vc.presentingViewController != nil {
            vc.dismiss(animated: true, completion: nil)
        } else {
            vc.navigationController?.popViewController(animated: true, nil)
        }
    }

    @MainActor class func pt_pushViewController(_ vc:UIViewController,completion:PTActionTask? = nil) {
#if POOTOOLS_DEBUG
        let share = LocalConsole.shared
        if share.isVisiable {
            let nav = PTBaseNavControl(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            PTUtils.getCurrentVC().present(nav, animated: true, completion: {
                if completion != nil {
                    completion!()
                }
                SwizzleTool().swizzleDidAddSubview {
                    // Configure console window.
                    if share.maskView != nil {
                        PTUtils.fetchWindow()!.bringSubviewToFront(share.maskView!)
                    }
                    if share.terminal != nil {
                        PTUtils.fetchWindow()?.bringSubviewToFront(share.terminal!)
                    }
                }
            })

        } else {
            PTUtils.getCurrentVC().navigationController?.pushViewController(vc)
        }
#else
        PTUtils.getCurrentVC().navigationController?.pushViewController(vc)
#endif
    }
    
    class func modalDismissBeforePush(_ vc: UIViewController) {
        if let visiableVC = PTUtils.getTopViewController(nil), visiableVC.presentingViewController != nil {
            visiableVC.dismiss(animated: false) {
                push(vc)
            }
        } else {
            push(vc)
        }
    }
    
    class func pusbWindowNavRoot(_ vc: UIViewController) {
        if let app = UIApplication.shared.delegate, let window = app.window {
            if let rootVC = window?.rootViewController {
                if let nav: UINavigationController = rootVC as? UINavigationController {
                    nav.pushViewController(vc, animated: true)
                } else {
                    getTopViewController(nil)?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}

//MARK: OC-FUNCTION
public extension PTUtils {
    class func oc_isiPhoneSeries()->Bool {
        isIPhoneXSeries()
    }
}

public class SwizzleTool: NSObject {
    
    /// Ensure context menus always show in a non reversed order.
    public func swizzleContextMenuReverseOrder() {
        guard let originalMethod = class_getInstanceMethod(NSClassFromString("_" + "UI" + "Context" + "Menu" + "List" + "View").self, NSSelectorFromString("reverses" + "Action" + "Order")),
              let swizzledMethod = class_getInstanceMethod(SwizzleTool.self, #selector(swizzled_reverses_Action_Order))
        else { PTNSLogConsole("Swizzle Error Occurred"); return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

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
    
    public static var swizzledDidAddSubviewClosure: PTActionTask?
    public static var pauseDidAddSubviewSwizzledClosure: Bool = false
    
    public func swizzleDidAddSubview(_ closure: @escaping PTActionTask) {
        guard let originalMethod = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.didAddSubview(_:))),
              let swizzledMethod = class_getInstanceMethod(SwizzleTool.self, #selector(swizzled_did_add_subview(_:)))
        else { PTNSLogConsole("Swizzle Error Occurred"); return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        
        Self.swizzledDidAddSubviewClosure = closure
    }

    @MainActor @objc public func swizzled_did_add_subview(_ subview: UIView) {
        guard !Self.pauseDidAddSubviewSwizzledClosure else { return }
        
        if let closure = Self.swizzledDidAddSubviewClosure {
            closure()
        }
    }
}
