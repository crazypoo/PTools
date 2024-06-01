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

    let mainWindow:UIView = UIApplication.shared.delegate!.window!!
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
    case UNKNOW
}

@objc public enum GradeType:Int {
    case normal
    case TenThousand
    case HundredMillion
}

public func deviceSafeAreaInsets() -> UIEdgeInsets {
    var insets: UIEdgeInsets = .zero
    
    if #available(iOS 11, *) {
        insets = AppWindows?.safeAreaInsets ?? .zero
    }
    
    return insets
}

public func PTIVarList(_ className:String) {
    var count : UInt32 = 0
    let list = class_copyIvarList(NSClassFromString(className), &count)
    for i in 0..<Int(count) {
        let ivar = list![i]
        let name = ivar_getName(ivar)
        let type = ivar_getTypeEncoding(ivar)
        PTNSLogConsole("\(String(cString: name!) + "<---->" + String(cString: type!))",levelType: PTLogMode,loggerType: .Utils)
    }
}

public func PTPropertyList(_ classString: String) {
    var count : UInt32 = 0
    let list = class_copyPropertyList(NSClassFromString(classString), &count)
    for i in 0..<Int(count) {
        let property = list![i]
        let name = property_getName(property)
        let type = property_getAttributes(property)
        PTNSLogConsole("\(String(cString: name) + "<---->" + String(cString: type!))",levelType: PTLogMode,loggerType: .Utils)
    }
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
    open var timer:DispatchSourceTimer?
    
    @available(iOS, introduced: 2.0, deprecated: 13.0, message: "這個方法在iOS13之後不能使用了")
    public class func showNetworkActivityIndicator(_ show:Bool) {
        PTGCDManager.gcdMain {
            UIApplication.shared.isNetworkActivityIndicatorVisible = show
        }
    }
                
    public class func getCurrentVCFrom(rootVC:UIViewController)->UIViewController {
        var currentVC : UIViewController?
        
        if rootVC is UITabBarController {
            currentVC = PTUtils.getCurrentVCFrom(rootVC: (rootVC as! UITabBarController).selectedViewController!)
        } else if rootVC is UINavigationController {
            currentVC = PTUtils.getCurrentVCFrom(rootVC: (rootVC as! UINavigationController).visibleViewController!)
        } else {
            currentVC = rootVC
        }
        return currentVC!
    }
    
    public class func getCurrentVC(anyClass:UIViewController = UIViewController())->UIViewController {
        let currentVC = PTUtils.getCurrentVCFrom(rootVC: (AppWindows?.rootViewController ?? anyClass))
        return currentVC
    }
    
    //MARK: 获取导航栏
    private class func getFirstNavigationControllerContainer(responder: UIResponder?) -> UIViewController? {
        var returnResponder: UIResponder? = responder
        while returnResponder != nil {
            if returnResponder!.isKind(of: UIViewController.self) {
                
                if (returnResponder! as? UIViewController)!.navigationController != nil {
                    return returnResponder! as? UIViewController
                }
            }
            returnResponder = returnResponder!.next
        }
        return nil
    }

    public class func getTopViewController(_ currentVC: UIViewController?) -> UIViewController? {
        
        guard let rootVC = AppWindows?.rootViewController else {
            return nil
        }
        let topVC = currentVC ?? rootVC
        
        switch topVC {
        case is UITabBarController:
            if let top = (topVC as! UITabBarController).selectedViewController {
                return getTopViewController(top)
            } else {
                return nil
            }
            
        case is UINavigationController:
            if let top = (topVC as! UINavigationController).topViewController {
                return getTopViewController(top)
            } else {
                var navVC: UINavigationController?
                navVC = getFirstNavigationControllerContainer(responder: currentVC) as? UINavigationController
                return navVC
            }
            
        default:
            return topVC.presentedViewController ?? topVC
        }
    }
    
    //MARK: 获取根控制器
    public class func getRootViewController() -> UIViewController? {
        
        var vc: UIViewController?
        
        let windows: [UIWindow] = UIApplication.shared.windows
        var activeWindow: UIWindow?
        
        for window in windows {
            if window.windowLevel == UIWindow.Level.normal {
                activeWindow = window
                break
            }
        }
        
        if activeWindow?.rootViewController != nil {
            vc = activeWindow!.rootViewController
        }
        return vc
    }

    public class func push(_ vc: UIViewController) {
        
        guard let currentVC = getActivityViewController() else {
            return
        }
        if currentVC is UITabBarController {
            vc.hidesBottomBarWhenPushed = true
            getTopViewController(nil)?.navigationController?.pushViewController(vc, animated: true)
        } else {
            PTGCDManager.gcdMain {
                var navVC: UINavigationController?
                if  currentVC.isKind(of: UINavigationController.self) == true {
                    navVC = currentVC as? UINavigationController
                } else {
                    navVC = getFirstNavigationControllerContainer(responder: currentVC) as? UINavigationController
                }
                vc.hidesBottomBarWhenPushed = true
                navVC?.pushViewController(vc, animated: true)
            }
        }
    }
    
    public class func modal(_ vc: UIViewController) {
        
        guard let currentVC = getActivityViewController() else {
            return
        }
        
        PTGCDManager.gcdMain {
            vc.modalTransitionStyle = UIModalTransitionStyle.coverVertical
            vc.modalPresentationStyle = .fullScreen
            // 防止单例的视图控制器
            guard vc.presentedViewController == nil else {return}
            guard vc.isBeingPresented == false else {return}
            
            // 不同视图控制器，先隐藏旧的，再展示新的
            if (currentVC.presentationController) != nil {
                currentVC.presentedViewController?.dismiss(animated: false, completion: nil)
            }
            
            currentVC.pt_present(vc, animated: true, completion: nil)
        }
    }
    
    public class func popToTargetVC(vcClass: UIViewController.Type) {
        
        let navVC: UINavigationController? = getTopViewController(nil)?.navigationController
        
        guard let targetVC = navVC?.viewControllers.filter({ $0.isKind(of: vcClass) }).last else {
            navVC?.popViewController(animated: true)
            return
        }
        
        PTGCDManager.gcdMain {
            navVC?.popToViewController(targetVC, animated: true)
        }
    }
    
    //MARK: - 跳转到首页
    public class func popToRootVC() {
        getTopViewController(nil)?.navigationController?.popToRootViewController(animated: true)
    }
    
    //MARK: - 需要注册的时候传入一个导航包含的控制器
    public class func windowRoot(nav: UIViewController) {
        if  nav.isKind(of: UINavigationController.self) == true {
            AppWindows?.rootViewController = nav
        } else {
#if DEBUG
            assertionFailure("传入对象必须是导航控制器")
#endif
        }
    }
    
    // Configure console window.
    public class func fetchWindow() -> UIWindow? {
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
    
    public class func modalDismissBeforePush(_ vc: UIViewController) {
        if let visiableVC = PTUtils.getTopViewController(nil), visiableVC.presentingViewController != nil {
            visiableVC.dismiss(animated: false) {
                push(vc)
            }
        } else {
            push(vc)
        }
    }
    
    public class func pusbWindowNavRoot(_ vc: UIViewController) {
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
    
    //MARK: - 判断某视图是否已经在window 上
    public class func ifAddToWindow(view: AnyClass) -> Bool {
        let res = AppWindows!.subviews.filter { (subView: UIView) -> Bool in
            subView.isKind(of: view.self)
        }
        return res.count > 0
    }
    
    //MARK: - 获取活跃VC
    public class func getActivityViewController() -> UIViewController? {
        
        var viewController: UIViewController?
        let windows: [UIWindow] = UIApplication.shared.windows
        var activeWindow: UIWindow?
        
        for window in windows {
            if window.windowLevel == UIWindow.Level.normal {
                activeWindow = window
                break
            }
        }
        
        if activeWindow != nil && activeWindow!.subviews.count > 0 {
            let frontView: UIView = activeWindow!.subviews.last!
            var nextResponder: UIResponder? = frontView.next
            
            while nextResponder!.isKind(of: UIWindow.self) == false {
                if nextResponder!.isKind(of: UIViewController.self) {
                    viewController = nextResponder as! UIViewController?
                    break
                } else {
                    nextResponder = nextResponder!.next
                }
            }
            
            if nextResponder!.isKind(of: UIViewController.self) {
                viewController = nextResponder as! UIViewController?
            } else {
                viewController = activeWindow!.rootViewController
            }
            
            while  viewController!.presentedViewController != nil {
                viewController =  viewController!.presentedViewController
            }
        }
        
        return viewController
    }
    
    //MARK: 获取当前正在显示的UIViewController，而不是NavigationController
    public class func visibleVC() -> UIViewController? {
        let viewController = getActivityViewController()
        if viewController?.isKind(of: UINavigationController.self) == true {
            let nav: UINavigationController = viewController as! UINavigationController
            return nav.visibleViewController
        }
        return viewController
    }
        
    public class func returnFrontVC() {
        let vc = PTUtils.getCurrentVC()
        if vc.presentingViewController != nil {
            vc.dismiss(animated: true, completion: nil)
        } else {
            vc.navigationController?.popViewController(animated: true, nil)
        }
    }
    
    open class dynamic func topMost(of viewController: UIViewController?) -> UIViewController? {
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
    
    public class func cgBaseBundle()->Bundle {
        let bundle = Bundle.init(for: self)
        return bundle
    }
                
    //MARK: 获取一个输入内最大的一个值
    ///获取一个输入内最大的一个值
    class open func maxOne<T:Comparable>( _ seq:[T]) -> T {

        assert(seq.count>0)
        return seq.reduce(seq[0]){
            max($0, $1)
        }
    }
                
    //MARK: 找出某view的superview
    ///找出某view的superview
    class open func findSuperViews(view:UIView)->[UIView] {
        var temp = view.superview
        let result = NSMutableArray()
        while temp != nil {
            result.add(temp!)
            temp = temp!.superview
        }
        return result as! [UIView]
    }
    
    //MARK: 找出某views的superview
    ///找出某views的superview
    class open func findCommonSuperView(firstView:UIView,
                                        other:UIView)->[UIView] {
        let result = NSMutableArray()
        let sOne = findSuperViews(view: firstView)
        let sOther = findSuperViews(view: other)
        var i = 0
        while i < min(sOne.count, sOther.count) {
            if sOne == sOther {
                result.add(sOne)
                i += 1
            } else {
                break
            }
        }
        return result as! [UIView]
    }
        
    //MARK: 这个方法可以用于UITextField中,检测金额输入
    class open func textInputAmoutRegex(text:NSString,
                                        range:NSRange,
                                        replacementString:NSString)->Bool {
        let len = (range.length > 0) ? (text.length - range.length) : (text.length + replacementString.length)
        if len > 20 {
            return false
        }
        let str = NSString(format: "%@%@", text,replacementString)
        return (str as String).isMoneyString()
    }
    
    //MARK: 查找某字符在字符串的位置
    class open func rangeOfSubString(fullStr:NSString,
                                     subStr:NSString)->[String] {
        var rangeArray = [String]()
        for i in 0..<fullStr.length {
            let temp:NSString = fullStr.substring(with: NSMakeRange(i, subStr.length)) as NSString
            if temp.isEqual(to: subStr as String) {
                let range = NSRange(location: i, length: subStr.length)
                rangeArray.append(NSStringFromRange(range))
            }
        }
        return rangeArray
    }
    
    class open func pt_pushViewController(_ vc:UIViewController,completion:PTActionTask? = nil) {
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
    
    class public func outputURL()->URL {
        let documentsDirectory = FileManager.pt.CachesDirectory()
        let outputURL = documentsDirectory.appendingPathComponent("\(Date().getTimeStamp()).mp4")
        if #available(iOS 16.0, *) {
            return URL(filePath: outputURL)
        } else {
            return URL(fileURLWithPath: outputURL)
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
        else { Swift.print("Swizzle Error Occurred"); return }
        
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
    
    public static var swizzledDidAddSubviewClosure: (() -> Void)?
    public static var pauseDidAddSubviewSwizzledClosure: Bool = false
    
    public func swizzleDidAddSubview(_ closure: @escaping () -> Void) {
        guard let originalMethod = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.didAddSubview(_:))),
              let swizzledMethod = class_getInstanceMethod(SwizzleTool.self, #selector(swizzled_did_add_subview(_:)))
        else { Swift.print("Swizzle Error Occurred"); return }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
        
        Self.swizzledDidAddSubviewClosure = closure
    }

    @objc public func swizzled_did_add_subview(_ subview: UIView) {
        guard !Self.pauseDidAddSubviewSwizzledClosure else { return }
        
        if let closure = Self.swizzledDidAddSubviewClosure {
            closure()
        }
    }
}
