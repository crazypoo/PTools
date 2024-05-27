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
}

extension UIImage {
    static func resizeImage()->UIImage {
        if #available(iOS 14.0, *) {
            return UIImage(.arrow.upBackwardAndArrowDownForward).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        } else {
            return UIImage(.arrow).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }
    static let shareImage = UIImage(.square.andArrowUp).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let copyImage = UIImage(.doc.onDocFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static func clearImage()->UIImage {
        if #available(iOS 15.0, *) {
            return UIImage(.delete.backward).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        } else {
            return UIImage(.delete).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }
    static func userDefaultsImage()->UIImage {
        if #available(iOS 14.0, *) {
            return UIImage(.doc.badgeGearshape).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        } else {
            return UIImage(.doc.onDoc).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }
    static func colorImage()->UIImage {
        if #available(iOS 14.0, *) {
            return UIImage(.paintpalette).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        } else {
            return UIImage(.paintbrush).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }
    static func rulerImage()->UIImage {
        if #available(iOS 14.0, *) {
            return UIImage(.ruler).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        } else {
            return UIImage(.f.cursive).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }
    static let docImage = UIImage(.doc).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let dev3thPartyImage = UIImage(.plus.magnifyingglass).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static func maskImage()->UIImage {
        if #available(iOS 15.0, *) {
            return UIImage(.theatermasks).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        } else {
            return UIImage(.bookmark).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }
    static let maskBubbleImage = UIImage(systemName: "bubble.right")!.withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static func viewFrameImage()->UIImage {
        if #available(iOS 15.0, *) {
            return UIImage(.square.insetFilled).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        } else {
            return UIImage(systemName: "rectangle.3.offgrid")!.withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }
    static func cpuImage()->UIImage {
        if #available(iOS 14.0, *) {
            return UIImage(.cpu).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        } else {
            return UIImage(.heart.circle).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }
    static func displayImage()->UIImage {
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
    static func respringImage()->UIImage {
        if #available(iOS 14.0, *) {
            return UIImage(.arrowtriangle.backward).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        } else {
            return UIImage(.arrowtriangle).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
        }
    }
    static let debugImage = UIImage(.ant).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let performanceImage = UIImage(.eyeglasses).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let crashLogImage = UIImage(.exclamationmark.triangleFill).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
    static let networkImage = UIImage(.globe).withTintColor(PTDarkModeOption.colorLightDark(lightColor: .black, darkColor: .white))
}

class ConsoleWindow: UIWindow {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if let hitView = super.hitTest(point, with: event) {
            return hitView.isKind(of: ConsoleWindow.self) ? nil : hitView
        }
        return super.hitTest(point, with: event)
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

public typealias PTLocalConsoleBlock = (_ actionType:LocalConsoleActionType,_ debug:Bool,_ logUrl:URL)->Void

@objcMembers
public class LocalConsole: NSObject {
    public static let shared = LocalConsole()
            
    public var flex:PTActionTask?
    public var watchViews:PTActionTask?
    public var closeAllOutsideFunction:PTActionTask?
    public var leakCallback: ((PTPerformanceLeak) -> Void)?

    public var isVisiable:Bool = PTCoreUserDefultsWrapper.AppDebugMode {
        didSet {
            guard oldValue != isVisiable else { return }
            PTCoreUserDefultsWrapper.AppDebugMode = isVisiable
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
                if PTCoreUserDefultsWrapper.AppDebbugMark {
                    maskOpenFunction()
                }
                
                commitTextChanges(requestMenuUpdate: true)
                watcherInit()
            } else {
                PTNetworkHelper.shared.disable()
                UIViewPropertyAnimator(duration: 0.4, dampingRatio: 1) { [self] in
                    terminal!.transform = .init(scaleX: 0.9, y: 0.9)
                }.startAnimation()
                
                UIViewPropertyAnimator(duration: 0.3, dampingRatio: 1) { [self] in
                    terminal!.alpha = 0
                    cleanSystemLogView()
                }.startAnimation()
            }
        }
    }
    
    public func setAttFontSize(@PTClampedProperyWrapper(range:LocalConsoleFontMin...LocalConsoleFontMax) fontSizes:CGFloat) {
        PTCoreUserDefultsWrapper.LocalConsoleCurrentFontSize = fontSizes
        terminal!.fontSize = fontSizes
        terminal!.setAttributedText(currentText)
    }
    
    public func setAttFontColor(color:UIColor) {
        terminal!.fontColor = color
        terminal!.setAttributedText(currentText)
    }
    
    public var terminal:PTTerminal?
    public var maskView:PTDevMaskView?

    fileprivate let userdefaultShares = PTUserDefaultKeysAndValues.shares
    public var showAllUserDefaultsKeys = false {
        didSet {
            userdefaultShares.showAllUserDefaultsKeys = showAllUserDefaultsKeys
        }
    }

    var currentText: String = "" {
        didSet {
            PTGCDManager.gcdMain {
                self.setLog()
                if self.isVisiable {
                    UIView.performWithoutAnimation {
                        self.commitTextChanges(requestMenuUpdate: oldValue == "" || (oldValue != "" && self.currentText == ""))
                    }
                }
            }
        }
    }
    
    func commitTextChanges(requestMenuUpdate menuUpdateRequested: Bool) {
        if menuUpdateRequested {
            // Update the context menu to show the clipboard/clear actions.
            if #available(iOS 15, *) {
                terminal!.menuButton.menu = makeMenu()
            }
        }
    }
    
    lazy var feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    var debugBordersEnabled = false {
        didSet {
            
            UIView.swizzleDebugBehaviour_UNTRACKABLE_TOGGLE()
            
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
            
            for window in UIApplication.shared.windows {
                allViews.append(contentsOf: subviewsRecursive(in: window))
            }
            allViews.forEach {
                let tracker = BorderManager(view: $0)
                GLOBAL_BORDER_TRACKERS.append(tracker)
                tracker.activate()
            }
        }
    }

    private override init() {
        super.init()
        
        if isVisiable {
            createSystemLogView()
            if PTCoreUserDefultsWrapper.AppDebbugMark {
                maskOpenFunction()
            }
            
            watcherInit()
        } else {
            cleanSystemLogView()
        }
    }
    
    private func watcherInit() {
        UIView.swizzleMethods()
        UIWindow.db_swizzleMethods()
        URLSessionConfiguration.swizzleMethods()
        UIViewController.lvcdSwizzleLifecycleMethods()
        StdoutCapture.startCapturing()
        StderrCapture.startCapturing()
        StderrCapture.syncData()
        PTNetworkHelper.shared.enable()
        PTLaunchTimeTracker.measureAppStartUpTime()
        PTCrashManager.register()
        PTPerformanceLeakDetector.delay = 1
        PTPerformanceLeakDetector.callback = leakCallback
    }
    
    public func cleanSystemLogView() {
        terminal?.removeFromSuperview()
        terminal = nil
        closeAllFunction()
    }
    
    func setLog() {
        if terminal!.systemText!.contentOffset.y > (terminal!.systemText!.contentSize.height - terminal!.systemText!.bounds.size.height - 20) {
            terminal!.systemText?.pendingOffsetChange = true
        }
        
        terminal!.systemText?.text = currentText
        terminal!.setAttributedText(currentText)
        PTGCDManager.gcdAfter(time: 0.2) {
            self.terminal!.systemText!.contentOffset.y = self.terminal!.systemText!.contentSize.height
        }
    }
        
    var temporaryKeyboardHeightValueTracker: CGFloat?
    // MARK: Handle keyboard show/hide.
    private var keyboardHeight: CGFloat? = nil {
        didSet {
            temporaryKeyboardHeightValueTracker = oldValue
            
            if possibleEndpoints.count > 2, terminal!.center != possibleEndpoints[0] && terminal!.center != possibleEndpoints[1] {
                let nearestTargetPosition = nearestTargetTo(terminal!.center, possibleTargets: possibleEndpoints.suffix(2))
                
                UIViewPropertyAnimator(duration: 0.55, dampingRatio: 1) {
                    self.terminal!.center = nearestTargetPosition
                }.startAnimation()
            }
            
            temporaryKeyboardHeightValueTracker = keyboardHeight
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

    var possibleEndpoints: [CGPoint] {
        let screenSize = AppWindows!.frame.size
        
        // Must check for portrait mode manually here. UIDevice was reporting orientation incorrectly before.
        let isPortraitNotchedPhone = UIDevice.current.hasNotch && AppWindows!.frame.size.width < AppWindows!.frame.size.height
        
        // Fix incorrect reported orientation on phone.
        let isLandscapePhone = UIDevice.current.userInterfaceIdiom == .phone && AppWindows!.frame.width > AppWindows!.frame.height
        
        let isLandscapeLeftNotchedPhone = UIDevice.current.orientation == .landscapeLeft
        && UIDevice.current.userInterfaceIdiom == .phone
        && UIDevice.current.hasNotch
        && isLandscapePhone
        
        let isLandscapeRightNotchedPhone = UIDevice.current.orientation == .landscapeRight
        && UIDevice.current.userInterfaceIdiom == .phone
        && UIDevice.current.hasNotch
        && isLandscapePhone
        
        let safeAreaInsets = PTUtils.getCurrentVC().view.safeAreaInsets
        
        let leftEndpointX = consoleSize.width / 2 + safeAreaInsets.left + (isLandscapePhone ? 4 : 12) + (isLandscapeRightNotchedPhone ? -16 : 0)
        let rightEndpointX = screenSize.width - (consoleSize.width / 2 + safeAreaInsets.right) - (isLandscapePhone ? 4 : 12) + (isLandscapeLeftNotchedPhone ? 16 : 0)
        let topEndpointY = consoleSize.height / 2 + safeAreaInsets.top + 12 + (isPortraitNotchedPhone ? -10 : 0)
        let bottomEndpointY = screenSize.height - consoleSize.height / 2 - (keyboardHeight ?? safeAreaInsets.bottom) - 12 + (isLandscapePhone ? 10 : 0)
        
        if consoleSize.width < screenSize.width - 112 {
            // Four endpoints, one for each corner.
            var endpoints = [
                CGPoint(x: leftEndpointX, y: topEndpointY),
                CGPoint(x: rightEndpointX, y: topEndpointY),
                CGPoint(x: leftEndpointX, y: bottomEndpointY),
                CGPoint(x: rightEndpointX, y: bottomEndpointY),
            ]
            
            if terminal!.frame.minX <= 0 {
                
                // Left edge endpoints.
                endpoints = [endpoints[0], endpoints[2]]
                
                // Left edge hiding endpoints.
                if !isLandscapeLeftNotchedPhone {
                    if terminal!.center.y < (screenSize.height - (temporaryKeyboardHeightValueTracker ?? 0)) / 2 {
                        endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28, y: endpoints[0].y))
                    } else {
                        endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28, y: endpoints[1].y))
                    }
                }
            } else if terminal!.frame.maxX >= screenSize.width {
                
                // Right edge endpoints.
                endpoints = [endpoints[1], endpoints[3]]
                
                // Right edge hiding endpoints.
                if !isLandscapeRightNotchedPhone {
                    if terminal!.center.y < (screenSize.height - (temporaryKeyboardHeightValueTracker ?? 0)) / 2 {
                        endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28, y: endpoints[0].y))
                    } else {
                        endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28, y: endpoints[1].y))
                    }
                }
            }
            
            return endpoints
            
        } else {
            // Two endpoints, one for the top, one for the bottom..
            var endpoints = [
                CGPoint(x: screenSize.width / 2, y: topEndpointY),
                CGPoint(x: screenSize.width / 2, y: bottomEndpointY)
            ]
            
            if terminal!.frame.minX <= 0 {
                
                // Left edge hiding endpoints.
                if terminal!.center.y < (screenSize.height - (temporaryKeyboardHeightValueTracker ?? 0)) / 2 {
                    endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28, y: endpoints[0].y))
                } else {
                    endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28, y: endpoints[1].y))
                }
            } else if terminal!.frame.maxX >= screenSize.width {
                
                // Right edge hiding endpoints.
                if terminal!.center.y < (screenSize.height - (temporaryKeyboardHeightValueTracker ?? 0)) / 2 {
                    endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28, y: endpoints[0].y))
                } else {
                    endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28, y: endpoints[1].y))
                }
            }
            
            return endpoints
        }
    }
    
    let defaultConsoleSize = CGSize(width: systemLog_base_width, height: systemLog_base_height)

    /// The fixed size of the console view.
    lazy var consoleSize = defaultConsoleSize {
        didSet {
            terminal!.frame.size = consoleSize
                        
            // TODO: Snap to nearest position.
            
            PTCoreUserDefultsWrapper.PTLocalConsoleWidth = consoleSize.width
            PTCoreUserDefultsWrapper.PTLocalConsoleHeight = consoleSize.height
        }
    }

    func snapToCachedEndpoint() {
        let cachedConsolePosition = CGPoint(x: PTCoreUserDefultsWrapper.PTLocalConsoleX ?? possibleEndpoints.first!.x, y: PTCoreUserDefultsWrapper.PTLocalConsoleY ?? possibleEndpoints.first!.y)
        
        terminal!.center = cachedConsolePosition // Update console center so possibleEndpoints are calculated correctly.
        terminal!.center = nearestTargetTo(cachedConsolePosition, possibleTargets: possibleEndpoints)
    }
    
    fileprivate lazy var consoleWindow:PTBaseViewController = {
        let control = PTBaseViewController()
        control.view.backgroundColor = .clear
        return control
    }()

    public func createSystemLogView() {
        if terminal == nil {
            var contentView:Any!
            if #available(iOS 15, *) {
                AppWindows!.addSubviews([consoleWindow.view])
                AppWindows?.rootViewController?.addChild(consoleWindow)
                
                consoleWindow.view = PTBaseMaskView()
                consoleWindow.view.frame = AppWindows!.bounds
                
                SwizzleTool().swizzleContextMenuReverseOrder()

                SwizzleTool().swizzleDidAddSubview {
                    AppWindows!.bringSubviewToFront(self.consoleWindow.view)
                }

                contentView = consoleWindow.view as Any

            } else {
                contentView = AppWindows!
            }
            
            terminal = PTTerminal.init(view: contentView as Any, frame: CGRect.init(x: 0, y: CGFloat.kNavBarHeight_Total, width: PTCoreUserDefultsWrapper.PTLocalConsoleWidth ?? consoleSize.width, height:PTCoreUserDefultsWrapper.PTLocalConsoleHeight ?? consoleSize.height))
            terminal!.tag = SystemLogViewTag
            snapToCachedEndpoint()
            terminal!.dragEnd = {
                // After the PiP is thrown, determine the best corner and re-target it there.
                let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
                
                let projectedPosition = CGPoint(
                    x: self.terminal!.center.x + project(initialVelocity: self.terminal!.x, decelerationRate: decelerationRate),
                    y: self.terminal!.center.y + project(initialVelocity: self.terminal!.y, decelerationRate: decelerationRate)
                )
                
                let nearestTargetPosition = nearestTargetTo(projectedPosition, possibleTargets: self.possibleEndpoints)
                
                let relativeInitialVelocity = CGVector(
                    dx: relativeVelocity(forVelocity: self.terminal!.x, from: self.terminal!.center.x, to: nearestTargetPosition.x),
                    dy: relativeVelocity(forVelocity: self.terminal!.x, from: self.terminal!.center.y, to: nearestTargetPosition.y)
                )
                
                let timingParameters = UISpringTimingParameters(damping: 0.85, response: 0.45, initialVelocity: relativeInitialVelocity)
                let positionAnimator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
                positionAnimator.addAnimations { [self] in
                    self.terminal!.center = nearestTargetPosition
                }
                positionAnimator.startAnimation()
                PTCoreUserDefultsWrapper.PTLocalConsoleX = nearestTargetPosition.x
                PTCoreUserDefultsWrapper.PTLocalConsoleY = nearestTargetPosition.y
            }
            if #available(iOS 15, *) {
                terminal!.menuButton.showsMenuAsPrimaryAction = true
                terminal!.menuButton.menu = makeMenu()
            } else {
                terminal!.menuButton.addActionHandlers { sender in
                    self.feedbackGenerator.impactOccurred(intensity: 1)
                    /*
                            Title
                     */
                    let actionTitle = PTActionSheetTitleItem(title: .debug,image: UIImage.debugImage)
                            
                    /*
                            Destructives
                     */
                    let destructives_debugController = PTActionSheetItem(title: .debugController,titleColor: .systemRed,image: UIImage.debugControllerImage,itemAlignment: .left)
                    let destructives_terminateApp = PTActionSheetItem(title: .terminateApp,titleColor: .systemRed,image: UIImage.terminateAppImage,itemAlignment: .left)
                    let destructives_respring = PTActionSheetItem(title: .respring,titleColor: .systemRed,image: UIImage.respringImage(),itemAlignment: .left)
                    
                    /*
                            Content
                     */
                    var colorString = ""
                    if PTColorPickPlugin.share.showed {
                        colorString = .hideColorCheck
                    } else {
                        colorString = .showColorCheck
                    }
                    
                    var rulerString = ""
                    if PTViewRulerPlugin.share.showed {
                        rulerString = .hideRulerCheck
                    } else {
                        rulerString = .showRulerCheck
                    }
                    let content_resize = PTActionSheetItem(title: .resizeConsole,image: UIImage.resizeImage(),itemAlignment: .left)
                    let content_share = PTActionSheetItem(title: .shareText,image: UIImage.shareImage,itemAlignment: .left)
                    let content_copy = PTActionSheetItem(title: .copyText,image: UIImage.copyImage,itemAlignment: .left)
                    let content_clearConsole = PTActionSheetItem(title: .clearConsole,image: UIImage.clearImage(),itemAlignment: .left)
                    let content_userDefaults = PTActionSheetItem(title: .userDefaults,image: UIImage.userDefaultsImage(),itemAlignment: .left)
                    let content_network = PTActionSheetItem(title: .network,image: UIImage.networkImage,itemAlignment: .left)
                    let content_crashLog = PTActionSheetItem(title: .crashLog,image: UIImage.crashLogImage,itemAlignment: .left)
                    let content_performance = PTActionSheetItem(title: .Performance,image: UIImage.performanceImage,itemAlignment: .left)
                    let content_color = PTActionSheetItem(title: colorString,image: UIImage.colorImage(),itemAlignment: .left)
                    let content_ruler = PTActionSheetItem(title: rulerString,image: UIImage.rulerImage(),itemAlignment: .left)
                    let content_appDocument = PTActionSheetItem(title: .appDocument,image: UIImage.docImage,itemAlignment: .left)
                    let content_flex = PTActionSheetItem(title: .flex,image: UIImage.dev3thPartyImage,itemAlignment: .left)
                    let content_inapp = PTActionSheetItem(title: .inApp, image: UIImage.dev3thPartyImage,itemAlignment: .left)

                    var contentItems = [content_resize,content_share,content_copy,content_clearConsole,content_userDefaults,content_network,content_crashLog,content_performance,content_color,content_ruler,content_appDocument,content_flex,content_inapp]

                    var devMaskString = ""
                    var devMaskBubbleString = ""
                    if self.maskView != nil {
                        devMaskString = .devMaskClose
                        
                        if PTCoreUserDefultsWrapper.AppDebbugTouchBubble {
                            devMaskBubbleString = .devMaskBubbleClose
                        } else {
                            devMaskBubbleString = .devMaskBubbleOpen
                        }
                        let content_devMaskString = PTActionSheetItem(title: devMaskString,image: UIImage.maskImage(),itemAlignment: .left)
                        let content_devMaskBubbleString = PTActionSheetItem(title: devMaskBubbleString,image:  UIImage.maskBubbleImage,itemAlignment: .left)

                        contentItems.append(content_devMaskString)
                        contentItems.append(content_devMaskBubbleString)
                    } else {
                        devMaskString = .devMaskOpen
                        let content_devMaskString = PTActionSheetItem(title: devMaskString,image: UIImage.maskImage(),itemAlignment: .left)
                        contentItems.append(content_devMaskString)
                    }
                    
                    var viewFrameString = ""
                    if self.debugBordersEnabled {
                        viewFrameString = .showViewFrames
                    } else {
                        viewFrameString = .hideViewFrames
                    }
                    let content_viewFrameString = PTActionSheetItem(title: viewFrameString,image: UIImage.viewFrameImage(),itemAlignment: .left)
                    contentItems.append(content_viewFrameString)
                    let content_systemReport = PTActionSheetItem(title: .systemReport,image: UIImage.cpuImage(),itemAlignment: .left)
                    contentItems.append(content_systemReport)
                    let content_displayReport = PTActionSheetItem(title: .displayReport,image: UIImage.displayImage(),itemAlignment: .left)
                    contentItems.append(content_displayReport)

                    UIAlertController.baseCustomActionSheet(titleItem: actionTitle,destructiveItems: [destructives_debugController,destructives_terminateApp,destructives_respring], contentItems: contentItems) { sheet, index, title in
                        if title == .terminateApp {
                            self.terminateApplicationAction()
                        } else if title == .respring {
                            self.respringAction()
                        } else if title == .debugController {
                            self.debugControllerAction()
                        }
                    } otherBlock: { sheet, index, title in
                        if title == .shareText {
                            self.shareAction()
                        } else if title == .copyText {
                            self.copyTextAction()
                        } else if title == .resizeConsole {
                            self.resizeAction()
                        } else if title == .clearConsole {
                            self.clear()
                        } else if title == .userDefaults {
                            self.userdefaultAction()
                        } else if title == .Performance {
                            self.performanceControlOpen()
                        } else if title == .hideColorCheck || title == .showColorCheck {
                            self.colorAction()
                        } else if title == .hideRulerCheck || title == .showRulerCheck {
                            self.rulerAction()
                        } else if title == .appDocument {
                            self.documentAction()
                        } else if title == .flex {
                            self.flexAction()
                        } else if title == .inApp {
                            self.watchViewsAction()
                        } else if title == .devMaskClose || title == .devMaskOpen {
                            self.maskOpenFunction()
                        } else if title == .devMaskBubbleClose || title == .devMaskBubbleOpen {
                            self.maskOpenBubbleFunction()
                        } else if title == .hideViewFrames || title == .showViewFrames {
                            self.viewFramesAction()
                        } else if title == .systemReport {
                            self.systemReport()
                        } else if title == .displayReport {
                            self.displayReport()
                        } else if title == .crashLog {
                            self.crashLogControlOpen()
                        } else if title == .network {
                            self.networkWatcherOpen()
                        }
                    }
                }
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        }
    }
    
    var hasShortened = false
    
    public var isCharacterLimitDisabled = false
    public var isCharacterLimitWarningDisabled = false

    public func print(_ items: Any) {
        let result: String
        if currentText == "" {
            result = "\(items)"
        } else {
            result = currentText + "\n\(items)"
        }
        let _currentText: String = result

        // Cut down string if it exceeds 50,000 characters to keep text view running smoothly.
        if _currentText.count > 50000 && !isCharacterLimitDisabled {

            if !hasShortened && !isCharacterLimitWarningDisabled {
                hasShortened = true
                PTNSLogConsole("LocalConsole的内容已超过50000个字符。为了保持性能，LocalConsole减少了打印内容的开头部分。要禁用此行为，请将LocalConsole.shared.isCharacterLimitDisabled设置为true。要禁用此警告，请设置localconsole.share.ischaracterlimitwarningdisabled = true。",levelType: .Error,loggerType: .Log)
            }

            let shortenedString = String(_currentText.suffix(50000))
            currentText = shortenedString.stringAfterFirstOccurenceOf(delimiter: "\n") ?? shortenedString
        } else {
            currentText = _currentText
        }
    }
    
    public var menu: UIMenuElement? = nil {
        didSet {
            if #available(iOS 14.0, *) {
                terminal!.menuButton.menu = makeMenu()
            }
        }
    }
    
    @available(iOS 14.0, *)
    func makeMenu() -> UIMenu {
        let result: UIAction
        // Something here causes a crash < iOS 15. Fall back to copy text for iOS 15 and below.
        if #available(iOS 16, *) {
            result = UIAction(title: .shareText, image: UIImage.shareImage) { _ in
                self.shareAction()
            }
        } else {
            result = UIAction(title: .copyText, image: UIImage.copyImage) { _ in
                self.copyTextAction()
            }
        }
        let share: UIAction = result

        let resize = UIAction(title: .resizeConsole, image: UIImage.resizeImage()) { _ in
            self.resizeAction()
        }

        // If device is phone in landscape, disable resize controller.
        if UIDevice.current.userInterfaceIdiom == .phone && PTUtils.getCurrentVC().view.frame.width > PTUtils.getCurrentVC().view.frame.height {
            resize.attributes = .disabled
            if #available(iOS 15, *) {
                resize.subtitle = "Portrait Orientation Only"
            }
        }

        let clear = UIAction(title: .clearConsole, image: UIImage.clearImage(), attributes: .destructive) { _ in
            self.clear()
        }

        var debugActions: [UIMenuElement] = []

        if #available(iOS 15, *) {

            let deferredUserDefaultsList = UIDeferredMenuElement.uncached { completion in
                var actions: [UIAction] = []

                if self.userdefaultShares.keyAndValues().count == 0 {
                    actions.append(UIAction(title: "No Entries", attributes: .disabled, handler: { _ in }))
                } else {
                    self.userdefaultShares.keyAndValues().enumerated().forEach { index, value in
                        let action = UIAction(title: value.keys.first!, image: nil) { _ in

                            UIAlertController.base_alertVC(title: "Key\n" + value.keys.first!, msg: "\nValue\n" + "\(value.values.first!)", okBtns: ["Copy Value", "Clear Value", "Edit value"], cancelBtn: "Cancel", moreBtn: { index, title in
                                if title == "Copy Value" {
                                    "\(value.values.first!)".copyToPasteboard()
                                } else if title == "Clear Value" {
                                    UserDefaults.standard.removeObject(forKey: value.keys.first!)
                                } else if title == "Edit value" {
                                    UIAlertController.base_textfield_alertVC(title: "Edit\n" + value.keys.first!, okBtn: "⭕️", cancelBtn: "Cancel", placeHolders: [value.keys.first!], textFieldTexts: ["\(value.values.first!)"], keyboardType: [.default], textFieldDelegate: self) { result in
                                        let newValue = result.values.first
                                        UserDefaults.standard.setValue(newValue, forKey: value.keys.first!)
                                    }
                                }
                            })
                        }
                        action.subtitle = "\(value.values.first!)"
                        actions.append(action)
                    }

                    actions.append(
                            UIAction(title: "Clear Defaults", image: UIImage(.trash), attributes: .destructive, handler: { _ in
                                self.userdefaultShares.keyAndValues().enumerated().forEach { index, value in
                                    UserDefaults.standard.removeObject(forKey: value.keys.first!)
                                }
                            })
                    )
                }
                completion(actions)
            }

            let userDefaults = UIMenu(title: .userDefaults, image: UIImage.userDefaultsImage(), children: [deferredUserDefaultsList])

            debugActions.append(userDefaults)
        } else {
            let userDefaults = UIAction(title: .userDefaults, image: UIImage.userDefaultsImage()) { _ in
                self.userdefaultAction()
            }
            debugActions.append(userDefaults)
        }

        let network = UIAction(title: .network, image: UIImage.networkImage) { _ in
            self.networkWatcherOpen()
        }
        
        let crashLog = UIAction(title: .crashLog, image: UIImage.crashLogImage) { _ in
            self.crashLogControlOpen()
        }
        
        let performance = UIAction(title: .Performance, image: UIImage.performanceImage) { _ in
            self.performanceControlOpen()
        }
        
        let colorCheck = UIAction(title: PTColorPickPlugin.share.showed ? .hideColorCheck : .showColorCheck, image: UIImage.colorImage()) { _ in
            self.colorAction()
        }

        let ruler = UIAction(title: PTViewRulerPlugin.share.showed ? .hideRulerCheck : .showRulerCheck, image: UIImage.rulerImage()) { _ in
            self.rulerAction()
        }

        let document = UIAction(title: .appDocument, image: UIImage.docImage) { _ in
            self.documentAction()
        }

        let Flex = UIAction(title: .flex, image: UIImage.dev3thPartyImage) { _ in
            self.flexAction()
        }

        let InApp = UIAction(title: .inApp, image: UIImage.dev3thPartyImage) { _ in
            self.watchViewsAction()
        }

        if #available(iOS 15.0, *) {

            let deferredMaskList = UIDeferredMenuElement.uncached { completion in
                var actions: [UIAction] = []

                let maskOpen = UIAction(title: self.maskView != nil ? .devMaskClose : .devMaskOpen, image: UIImage.maskImage()) { _ in
                    self.maskOpenFunction()
                }
                actions.append(maskOpen)

                if self.maskView != nil {
                    let maskTouchBubble = UIAction(title: PTCoreUserDefultsWrapper.AppDebbugTouchBubble ? .devMaskBubbleClose : .devMaskBubbleOpen, image: UIImage.maskBubbleImage) { _ in
                        self.maskOpenBubbleFunction()
                    }
                    actions.append(maskTouchBubble)
                }

                completion(actions)
            }


            let masks = UIMenu(title: "Dev Mask", image: UIImage.maskImage(), children: [deferredMaskList])
            debugActions.append(masks)
        } else {
            let maskOpen = UIAction(title: maskView != nil ? .devMaskClose : .devMaskOpen, image: UIImage.maskImage()) { _ in
                self.maskOpenFunction()
            }
            debugActions.append(maskOpen)

            if maskView != nil {
                let maskTouchBubble = UIAction(title: PTCoreUserDefultsWrapper.AppDebbugTouchBubble ? .devMaskBubbleClose : .devMaskBubbleOpen, image: UIImage.maskBubbleImage) { _ in
                    self.maskOpenBubbleFunction()
                }
                debugActions.append(maskTouchBubble)
            }
        }

        let viewFrames = UIAction(title: debugBordersEnabled ? .showViewFrames : .hideViewFrames, image: UIImage.viewFrameImage()) { _ in
            self.viewFramesAction()
            self.terminal!.menuButton.menu = self.makeMenu()
        }

        let systemReport = UIAction(title: .systemReport, image: UIImage.cpuImage()) { _ in
            self.systemReport()
        }

        // Show the right glyph for the current device being used.
        let displayReport = UIAction(title: .displayReport, image: UIImage.displayImage()) { _ in
            self.displayReport()
        }

        let terminateApplication = UIAction(title: .terminateApp, image: UIImage.terminateAppImage, attributes: .destructive) { _ in
            self.terminateApplicationAction()
        }

        let respring = UIAction(title: .respring, image: UIImage.respringImage(), attributes: .destructive) { _ in
            self.respringAction()
        }

        let debugController = UIAction(title: .debugController, image: UIImage.debugControllerImage, attributes: .destructive) { _ in
            self.debugControllerAction()
        }

        debugActions.append(contentsOf: [network,crashLog,performance, colorCheck, ruler, document, viewFrames, systemReport, displayReport, Flex, InApp])
        let destructActions = [debugController, terminateApplication, respring]

        let debugMenu = UIMenu(
                title: .debug, image: UIImage.debugImage,
                children: [
                    UIMenu(title: "", options: .displayInline, children: debugActions),
                    UIMenu(title: "", options: .displayInline, children: destructActions),
                ]
        )

        var menuContent: [UIMenuElement] = []

        if !terminal!.systemText!.text.stringIsEmpty() {
            menuContent.append(contentsOf: [UIMenu(title: "", options: .displayInline, children: [share, resize])])
        } else {
            menuContent.append(UIMenu(title: "", options: .displayInline, children: [resize]))
        }

        menuContent.append(debugMenu)
        if let customMenu = menu {
            menuContent.append(customMenu)
        }

        if !terminal!.systemText!.text.stringIsEmpty() {
            menuContent.append(UIMenu(title: "", options: .displayInline, children: [clear]))
        }

        return UIMenu(title: "", children: menuContent)
    }

    var dynamicReportTimer: Timer? {
        willSet {
            timerInvalidationCounter = 0
            dynamicReportTimer?.invalidate()
        }
    }
    
    var timerInvalidationCounter = 0

    /// Clear text in the console view.
    public func clear() {
        currentText = ""
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
        let sheet = PTSheetViewController(controller: nav,sizes: [.percent(0.9)])
        let currentVC = PTUtils.getCurrentVC()
        if currentVC is PTSideMenuControl {
            let currentVC = (currentVC as! PTSideMenuControl).contentViewController
            if let presentedVC = currentVC?.presentedViewController {
                presentedVC.present(sheet, animated: true)
            } else {
                currentVC!.present(sheet, animated: true)
            }
        } else {
            if let presentedVC = PTUtils.getCurrentVC().presentedViewController {
                presentedVC.present(sheet, animated: true)
            } else {
                PTUtils.getCurrentVC().present(sheet, animated: true)
            }
        }
    }
    
    func maskOpenFunction() {
        if maskView != nil {
            PTCoreUserDefultsWrapper.AppDebbugMark = false
            maskView?.removeFromSuperview()
            maskView = nil
        } else {
            PTCoreUserDefultsWrapper.AppDebbugMark = true
            
            let maskConfig = PTDevMaskConfig()
            maskView = PTDevMaskView(config: maskConfig)
            maskView?.frame = AppWindows!.frame
            AppWindows?.addSubview(maskView!)
        }
    }
    
    func maskOpenBubbleFunction() {
        PTCoreUserDefultsWrapper.AppDebbugTouchBubble = !PTCoreUserDefultsWrapper.AppDebbugTouchBubble
        if maskView != nil {
            maskView!.showTouch = PTCoreUserDefultsWrapper.AppDebbugTouchBubble
        }
    }

    func closeAllFunction() {
        debugBordersEnabled = false
        PTViewRulerPlugin.share.hide()
        PTColorPickPlugin.share.close()
        PTDebugPerformanceToolKit.shared.floatingShow = false
        PTDebugPerformanceToolKit.shared.performanceClose()
        ResizeController.shared.isActive = false
        PTCoreUserDefultsWrapper.AppDebbugMark = false
        maskView?.removeFromSuperview()
        maskView = nil
        
        if closeAllOutsideFunction != nil {
            closeAllOutsideFunction!()
        }
    }

    func debugControllerAction() {
        let vc = PTDebugViewController()
        present(content: vc)
    }
    
    func copyTextAction() {
        terminal!.systemText!.text.copyToPasteboard()
    }
    
    func respringAction() {
        guard let window = UIApplication.shared.windows.first else { return }
        
        window.layer.cornerRadius = UIScreen.main.value(forKey: "_displ" + "ayCorn" + "erRa" + "dius") as! CGFloat
        window.layer.masksToBounds = true
        
        UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1) {
            window.transform = .init(scaleX: 0.96, y: 0.96)
            window.alpha = 0
        }.startAnimation()
        
        // Concurrently run these snapshots to decrease the time to crash.
        for _ in 0...1000 {
            PTGCDManager.gcdGobal(qosCls: .default) {

                // This will cause jetsam to terminate backboardd.
                while true {
                    window.snapshotView(afterScreenUpdates: false)
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
    
    func watchViewsAction() {
        if watchViews != nil {
            watchViews!()
        }
    }
        
    func flexAction() {
        if flex != nil {
            flex!()
        }
    }
    
    func documentAction() {
        let vc = PTFileBrowserViewController()
        present(content: vc)
    }
    
    func present(content:UIViewController) {
        let nav = PTBaseNavControl(rootViewController: content)
        nav.modalPresentationStyle = .fullScreen
        
        if let presentedVC = PTUtils.getCurrentVC().presentedViewController {
            presentedVC.present(nav, animated: true)
        } else {
            PTUtils.getCurrentVC().present(nav, animated: true)
        }
    }
        
    func rulerAction() {
        if PTViewRulerPlugin.share.showed {
            PTViewRulerPlugin.share.hide()
        } else {
            PTViewRulerPlugin.share.show()
        }
    }
    
    func colorAction() {
        if PTColorPickPlugin.share.showed {
            PTColorPickPlugin.share.close()
        } else {
            PTColorPickPlugin.share.show()
        }
    }
    
    func userdefaultAction() {
        let vc = PTUserDefultsViewController()
        vc.showAllUserDefaultsKeys = showAllUserDefaultsKeys
        present(content: vc)
    }
    
    func resizeAction() {
        PTGCDManager.gcdAfter(time: 0.1) {
            ResizeController.shared.isActive.toggle()
            ResizeController.shared.platterView.reveal()
        }
    }
    
    func shareAction() {
        let activityViewController = PTActivityViewController(text: terminal!.systemText!.text ?? "")
        activityViewController.previewNumberOfLines = 10
        PTUtils.getCurrentVC().present(activityViewController, animated: true)
    }
    
    func systemReport() {
            
        PTGCDManager.gcdMain { [self] in

            if !currentText.stringIsEmpty() { print("\n") }
            
            dynamicReportTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in

                guard terminal!.systemText!.panGestureRecognizer.numberOfTouches == 0 else {
                    return
                }

                var _currentText = currentText

                // To optimize performance, only scan the last 2500 characters of text for system report changes.
                let result: NSRange
                scope: do {
                    if _currentText.count <= 2500 {
                        result = NSMakeRange(0, _currentText.count)
                        break scope
                    }
                    result = NSMakeRange(_currentText.count - 2500, 2500)
                }
                let range: NSRange = result

                let regex0 = try! NSRegularExpression(pattern: "ThermalState: .*", options: NSRegularExpression.Options.caseInsensitive)
                _currentText = regex0.stringByReplacingMatches(in: _currentText, options: [], range: range, withTemplate: "ThermalState: \(SystemReport.shared.thermalState)")

                let regex1 = try! NSRegularExpression(pattern: "SystemUptime: .*", options: NSRegularExpression.Options.caseInsensitive)
                _currentText = regex1.stringByReplacingMatches(in: _currentText, options: [], range: range, withTemplate: "SystemUptime: \(ProcessInfo.processInfo.systemUptime.formattedString!)")

                let regex2 = try! NSRegularExpression(pattern: "LowPowerMode: .*", options: NSRegularExpression.Options.caseInsensitive)
                _currentText = regex2.stringByReplacingMatches(in: _currentText, options: [], range: range, withTemplate: "LowPowerMode: \(ProcessInfo.processInfo.isLowPowerModeEnabled)")

                if currentText != _currentText {
                    currentText = _currentText

                    timerInvalidationCounter = 0

                } else {

                    timerInvalidationCounter += 1

                    // It has been 2 seconds and values have not changed.
                    if timerInvalidationCounter == 2 {

                        // Invalidate the timer if there is no longer anything to update.
                        dynamicReportTimer = nil
                    }
                }
            }
            var volumeAvailableCapacityForImportantUsageString = ""
            var volumeAvailableCapacityForOpportunisticUsageString = ""
            var volumesString = ""
            volumeAvailableCapacityForImportantUsageString = String.init(format: "%d", Device.volumeAvailableCapacityForImportantUsage!)
            volumeAvailableCapacityForOpportunisticUsageString = String.init(format: "%d", Device.volumeAvailableCapacityForOpportunisticUsage!)
            volumesString = String.init(format: "%d", Device.volumes!)

            var hzString = ""
            hzString = "MaxFrameRate: \(UIScreen.main.maximumFramesPerSecond) Hz"

            var supportApplePencilString = ""
            switch UIDevice.pt.supportApplePencil {
            case .Both:
                supportApplePencilString = "Support All"
            case .Second:
                supportApplePencilString = "Only Support Second"
            case .First:
                supportApplePencilString = "Only Support First"
            case .BothNot:
                supportApplePencilString = "Both Not Support"
            }
            
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
                    BatteryLevel: \(String.init(format: "%d", Device.current.batteryLevel!))
                    VolumeTotalCapacity: \(String.init(format: "%d", Device.volumeTotalCapacity!))
                    VolumeAvailableCapacity: \(String.init(format: "%d", Device.volumeAvailableCapacity!))
                    VolumeAvailableCapacityForImportantUsage: \(volumeAvailableCapacityForImportantUsageString)
                    VolumeAvailableCapacityForOpportunisticUsage: \(volumeAvailableCapacityForOpportunisticUsageString)
                    Volumes: \(volumesString)
                    ApplePencilSupport: \(String.init(format: "%@", supportApplePencilString))
                    HasCamera: \(Device.current.hasCamera ? "Yes" : "No")
                    HasNormalCamera: \(Device.current.hasWideCamera ? "Yes" : "No")
                    HasWideCamera: \(Device.current.hasWideCamera ? "Yes" : "No")
                    HasTelephotoCamera: \(Device.current.hasTelephotoCamera ? "Yes" : "No")
                    HasUltraWideCamera: \(Device.current.hasUltraWideCamera ? "Yes" : "No")
                    IsJailBroken: \(UIDevice.pt.isJailBroken ? "Yes" : "No")
                    """

            print(systemText)
        }
    }
    
    func displayReport() {
        
        PTGCDManager.gcdMain { [self] in

            if !currentText.stringIsEmpty() { print("\n") }
            
            let safeAreaInsets = PTUtils.getCurrentVC().view.safeAreaInsets
            
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

    override init(view:Any,frame:CGRect) {
        super.init(view: view, frame: frame)
        backgroundColor = .black
        draggable = true
        layer.shadowRadius = 16
        layer.shadowOpacity = 0.5
        layerShadowOffset = CGSize.init(width: 0, height: 2)
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
    
    var fontColor: UIColor = UIColor(hexString: PTCoreUserDefultsWrapper.LocalConsoleCurrentFontColor)!
    var fontSize: CGFloat = PTCoreUserDefultsWrapper.LocalConsoleCurrentFontSize

    public func setAttributedText(_ string: String) {
        let att:ASAttributedString =  ASAttributedString("\(string)",.paragraph(.lineSpacing(5),.headIndent(7)),.font(.systemFont(ofSize: fontSize, weight: .semibold, design: .monospaced)),.foreground(fontColor))

        systemText?.attributed.text = att
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        UIApplication.shared.windows[0].safeAreaInsets.bottom > 0
    }
}

@available(iOS 14.0, *)
extension LocalConsole : UIContextMenuInteractionDelegate {
    public func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [self] _ in
            makeMenu() // 返回你之前创建的菜单
        }
    }
}

extension LocalConsole:UITextFieldDelegate {}
