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
    static let fps = "FPS"
    static let showMemoryCheck = "Show Memory check"
    static let hideMemoryCheck = "Hide Memory check"
    static let hideColorCheck = "Hide Color check"
    static let showColorCheck = "Show Color check"
    static let hideRulerCheck = "Hide Ruler check"
    static let showRulerCheck = "Show Ruler check"
    static let appDocument = "App Document"
    static let flex = "Flex"
    static let hyperioniOS = "HyperioniOS"
    static let foxNet = "FoxNet"
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
            
    public var FoxNet:PTActionTask?
    public var HyperioniOS:PTActionTask?
    public var flex:PTActionTask?
    public var watchViews:PTActionTask?
    public var closeAllOutsideFunction:PTActionTask?
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
            } else {
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
    
    var terminal:PTTerminal?
    private var maskView:PTDevMaskView?

    var currentText: String = "" {
        didSet {
            PTGCDManager.gcdMain {
                self.setLog()
            }
        }
    }
    
    private var debugBordersEnabled = false {
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
        
        SwizzleTool().swizzleContextMenuReverseOrder()

        if isVisiable {
            createSystemLogView()
        } else {
            cleanSystemLogView()
        }
    }
    
    public func cleanSystemLogView() {
        terminal?.removeFromSuperview()
        terminal = nil
        terminal?.systemIsVisible = false
        closeAllFunction()
    }
    
    func setLog() {
        if terminal!.systemText!.contentOffset.y > (terminal!.systemText!.contentSize.height - terminal!.systemText!.bounds.size.height - 20) {
            terminal!.systemText?.pendingOffsetChange = true
        }
        
        terminal!.systemText?.text = currentText
        terminal!.setAttributedText(currentText)
        terminal!.systemText!.contentOffset.y = terminal!.systemText!.contentSize.height
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
                        endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28,
                                                 y: endpoints[0].y))
                    } else {
                        endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28,
                                                 y: endpoints[1].y))
                    }
                }
            } else if terminal!.frame.maxX >= screenSize.width {
                
                // Right edge endpoints.
                endpoints = [endpoints[1], endpoints[3]]
                
                // Right edge hiding endpoints.
                if !isLandscapeRightNotchedPhone {
                    if terminal!.center.y < (screenSize.height - (temporaryKeyboardHeightValueTracker ?? 0)) / 2 {
                        endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28,
                                                 y: endpoints[0].y))
                    } else {
                        endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28,
                                                 y: endpoints[1].y))
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
                    endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28,
                                             y: endpoints[0].y))
                } else {
                    endpoints.append(CGPoint(x: -consoleSize.width / 2 + 28,
                                             y: endpoints[1].y))
                }
            } else if terminal!.frame.maxX >= screenSize.width {
                
                // Right edge hiding endpoints.
                if terminal!.center.y < (screenSize.height - (temporaryKeyboardHeightValueTracker ?? 0)) / 2 {
                    endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28,
                                             y: endpoints[0].y))
                } else {
                    endpoints.append(CGPoint(x: screenSize.width + consoleSize.width / 2 - 28,
                                             y: endpoints[1].y))
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
            
            UserDefaults.standard.set(consoleSize.width, forKey: "LocalConsole.Width")
            UserDefaults.standard.set(consoleSize.height, forKey: "LocalConsole.Height")
        }
    }

    func snapToCachedEndpoint() {
        let cachedConsolePosition = CGPoint(x: UserDefaults.standard.object(forKey: "LocalConsole.X") as? CGFloat ?? possibleEndpoints.first!.x, y: UserDefaults.standard.object(forKey: "LocalConsole.Y") as? CGFloat ?? possibleEndpoints.first!.y)
        
        terminal!.center = cachedConsolePosition // Update console center so possibleEndpoints are calculated correctly.
        terminal!.center = nearestTargetTo(cachedConsolePosition, possibleTargets: possibleEndpoints)
    }

    public func createSystemLogView() {
        if terminal == nil {
            terminal = PTTerminal.init(view: AppWindows!, frame: CGRect.init(x: 0, y: CGFloat.kNavBarHeight_Total, width: UserDefaults.standard.object(forKey: "LocalConsole.Width") as? CGFloat ?? consoleSize.width, height:UserDefaults.standard.object(forKey: "LocalConsole.Height") as? CGFloat ?? consoleSize.height))
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
                UserDefaults.standard.set(nearestTargetPosition.x, forKey: "LocalConsole.X")
                UserDefaults.standard.set(nearestTargetPosition.y, forKey: "LocalConsole.Y")
            }
            terminal!.menuButton.addActionHandlers { sender in
                var memoryString = ""
                if PTMemory.share.closed {
                    memoryString = .showMemoryCheck
                } else {
                    memoryString = .hideMemoryCheck
                }
                
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
                
                var titles = [.resizeConsole,.shareText,.copyText,.clearConsole,.userDefaults,.fps,memoryString,colorString,rulerString,.appDocument,.flex,.hyperioniOS,.foxNet,.inApp]
                var devMaskString = ""
                var devMaskBubbleString = ""
                if self.maskView != nil {
                    devMaskString = .devMaskClose
                    
                    if PTCoreUserDefultsWrapper.AppDebbugTouchBubble {
                        devMaskBubbleString = .devMaskBubbleClose
                    } else {
                        devMaskBubbleString = .devMaskBubbleOpen
                    }
                    titles.append(devMaskString)
                    titles.append(devMaskBubbleString)
                } else {
                    devMaskString = .devMaskOpen
                    titles.append(devMaskString)
                }
                
                var viewFrameString = ""
                if self.debugBordersEnabled {
                    viewFrameString = .hideViewFrames
                } else {
                    viewFrameString = .showViewFrames
                }
                titles.append(viewFrameString)

                titles.append(.systemReport)
                titles.append(.displayReport)
                titles.append(.debugController)
                titles.append(.terminateApp)
                titles.append(.respring)
                UIAlertController.base_alertVC(title:.debug,okBtns: titles,cancelBtn: "PT Button cancel".localized(), moreBtn:  { index, title in
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
                    } else if title == .fps {
                        self.fpsFunction()
                    } else if title == .showMemoryCheck || title == .hideMemoryCheck {
                        self.memoryFunction()
                    } else if title == .hideColorCheck || title == .showColorCheck {
                        self.colorAction()
                    } else if title == .hideRulerCheck || title == .showRulerCheck {
                        self.rulerAction()
                    } else if title == .appDocument {
                        self.documentAction()
                    } else if title == .flex {
                        self.flexAction()
                    } else if title == .hyperioniOS {
                        self.hyperioniOSAction()
                    } else if title == .foxNet {
                        self.foxNetAction()
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
                    } else if title == .terminateApp {
                        self.terminateApplicationAction()
                    } else if title == .respring {
                        self.respringAction()
                    } else if title == .debugController {
                        self.debugControllerAction()
                    }
                })
            }
        }
    }
    
    var hasShortened = false
    
    public var isCharacterLimitDisabled = false
    public var isCharacterLimitWarningDisabled = false

    public func print(_ items: Any) {
        let _currentText: String = {
            if currentText == "" {
                return "\(items)"
            } else {
                return currentText + "\n\(items)"
            }
        }()
        
        // Cut down string if it exceeds 50,000 characters to keep text view running smoothly.
        if _currentText.count > 50000 && !isCharacterLimitDisabled {
            
            if !hasShortened && !isCharacterLimitWarningDisabled {
                hasShortened = true
                PTNSLogConsole("LocalConsole的内容已超过50000个字符。为了保持性能，LocalConsole减少了打印内容的开头部分。要禁用此行为，请将LocalConsole.shared.isCharacterLimitDisabled设置为true。要禁用此警告，请设置localconsole.share.ischaracterlimitwarningdisabled = true。")
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
    
    public var showAllUserDefaultsKeys = false

    @available(iOS 14.0, *)
    func makeMenu() -> UIMenu {
        let share: UIAction = {
            // Something here causes a crash < iOS 15. Fall back to copy text for iOS 15 and below.
            if #available(iOS 16, *) {
                return UIAction(title: .shareText, image: UIImage(.square.andArrowUp)) { _ in
                    self.shareAction()
                }
            } else {
                return UIAction(title: .copyText, image: UIImage(.doc.onDoc)) { _ in
                    self.copyTextAction()
                }
            }
        }()
        
        let resize = UIAction(title: .resizeConsole, image: UIImage(.arrow.upBackwardAndArrowDownForward)) { _ in
            self.resizeAction()
        }
        
        // If device is phone in landscape, disable resize controller.
        if UIDevice.current.userInterfaceIdiom == .phone && PTUtils.getCurrentVC().view.frame.width > PTUtils.getCurrentVC().view.frame.height {
            resize.attributes = .disabled
            if #available(iOS 15, *) {
                resize.subtitle = "Portrait Orientation Only"
            }
        }
        
        let clear = UIAction(title: .clearConsole, image: UIImage(systemName: "delete.backward"), attributes: .destructive) { _ in
            self.clear()
        }
        
        var frameSymbol = "rectangle.3.offgrid"
        
        var debugActions: [UIMenuElement] = []
        
        if #available(iOS 15, *) {
            frameSymbol = "square.inset.filled"
            
            let deferredUserDefaultsList = UIDeferredMenuElement.uncached { completion in
                var actions: [UIAction] = []
                
                let keys: [String] = {
                    
                    if self.showAllUserDefaultsKeys {
                        return UserDefaults.standard.dictionaryRepresentation().map { $0.key }
                    }
                    
                    // Show keys the developer has added to the app (+ LocalConsole keys), excluding all of Apple's keys.
                    if let bundle: String = Bundle.main.bundleIdentifier {
                        let preferencePath: String = NSHomeDirectory() + "/Library/Preferences/\(bundle).plist"
                        
                        let _keys = NSDictionary(contentsOfFile: preferencePath)?.allKeys as! [String]
                        
                        return _keys.filter {
                            !$0.contains("LocalConsole.")
                        }
                    }
                    
                    return []
                }()
                
                if keys.isEmpty {
                    actions.append(
                        UIAction(title: "No Entries", attributes: .disabled, handler: { _ in })
                    )
                } else {
                    for key in keys.sorted(by: { $0.lowercased() < $1.lowercased() }) {
                        
                        // Old LocalConsole Key Cleanup
                        guard !key.contains("LocalConsole_") else {
                            UserDefaults.standard.removeObject(forKey: key)
                            continue
                        }
                        
                        if let value = UserDefaults.standard.value(forKey: key) {
                            let action = UIAction(title: key, image: nil) { _ in
                                let alertController = UIAlertController(title: key,
                                                                        message: nil,
                                                                        preferredStyle: .alert)
                                
                                let headerParagraphStyle = NSMutableParagraphStyle()
                                headerParagraphStyle.paragraphSpacing = 6
                                let contentParagraphStyle = NSMutableParagraphStyle()
                                
                                let attributes: [NSAttributedString.Key: Any] = [
                                    .paragraphStyle: contentParagraphStyle,
                                    .foregroundColor: UIColor.label,
                                    .font: UIFont.systemFont(ofSize: 13, weight: .semibold, design: .monospaced)
                                ]
                                
                                let attributedTitle: NSMutableAttributedString = {
                                    
                                    let attributedString = NSMutableAttributedString(string: "Key\n" + key, attributes: attributes)
                                    attributedString.addAttributes(
                                        [NSAttributedString.Key.foregroundColor : UIColor.label.withAlphaComponent(0.5),
                                         NSAttributedString.Key.paragraphStyle : headerParagraphStyle],
                                        range: NSRange(location: 0, length: 3))
                                    
                                    return attributedString
                                }()
                                
                                let attributedMessage: NSMutableAttributedString = {
                                    
                                    let attributedString = NSMutableAttributedString(string: "\nValue\n" + "\(value)", attributes: attributes)
                                    attributedString.addAttributes(
                                        [NSAttributedString.Key.foregroundColor : UIColor.label.withAlphaComponent(0.5),
                                         NSAttributedString.Key.paragraphStyle : headerParagraphStyle],
                                        range: NSRange(location: 0, length: 7))
                                    
                                    return attributedString
                                }()
                                
                                alertController.setValue(attributedTitle, forKey: "attributedTitle")
                                alertController.setValue(attributedMessage, forKey: "attributedMessage")
                                
                                alertController.addAction(UIAlertAction(title: "Copy Value", style: .default, handler: { _ in
                                    "\(value)".copyToPasteboard()
                                }))
                                alertController.addAction(UIAlertAction(title: "Clear Value", style: .destructive, handler: { _ in
                                    UserDefaults.standard.removeObject(forKey: key)
                                }))
                                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                                }))
                                
                                PTUtils.getCurrentVC().present(alertController,
                                                            animated: true)
                            }
                            action.subtitle = "\(value)"
                            actions.append(action)
                        }
                    }
                    
                    
                    actions.append(
                        UIAction(title: "Clear Defaults",
                                 image: UIImage(.trash), attributes: .destructive, handler: { _ in
                                     keys.forEach {
                                         UserDefaults.standard.removeObject(forKey: $0)
                                     }
                                 })
                    )
                }
                
                
                completion(actions)
            }
            
            let userDefaults = UIMenu(title: .userDefaults, image: UIImage(.doc.badgeGearshape), children: [deferredUserDefaultsList])
            
            debugActions.append(userDefaults)
        } else {
            let userDefaults = UIAction(title: .userDefaults,image: UIImage(.doc.badgeGearshape)) { _ in
                self.userdefaultAction()
            }
            debugActions.append(userDefaults)
        }
        
        let fps = UIAction(title: .fps,image: UIImage(.cursorarrow.motionlines)) { _ in
            self.fpsFunction()
        }
        
        let memory = UIAction(title: PTMemory.share.closed ? .showMemoryCheck : .hideMemoryCheck,image: UIImage(.memorychip)) { _ in
            self.memoryFunction()
        }
        
        let colorCheck = UIAction(title: PTColorPickPlugin.share.showed ? .hideColorCheck : .showColorCheck,image: UIImage(.paintpalette)) { _ in
            self.colorAction()
        }

        let ruler = UIAction(title: PTViewRulerPlugin.share.showed ? .hideRulerCheck : .showRulerCheck,image: UIImage(.ruler)) { _ in
            self.rulerAction()
        }
        
        let document = UIAction(title: .appDocument,image: UIImage(.doc)) { _ in
            self.documentAction()
        }
        
        let Flex = UIAction(title: .flex,image: UIImage(.plus.magnifyingglass)) { _ in
            self.flexAction()
        }
        
        let HyperioniOS = UIAction(title: .hyperioniOS,image: UIImage(.plus.magnifyingglass)) { _ in
            self.hyperioniOSAction()
        }
            
        let FoxNet = UIAction(title: .foxNet,image: UIImage(.plus.magnifyingglass)) { _ in
            self.foxNetAction()
        }
        
        let InApp = UIAction(title: .inApp,image: UIImage(.plus.magnifyingglass)) { _ in
            self.watchViewsAction()
        }
        
        if #available(iOS 15.0, *) {
            
            let deferredMaskList = UIDeferredMenuElement.uncached { completion in
                var actions: [UIAction] = []
                      
                let maskOpen = UIAction(title: self.maskView != nil ? .devMaskClose : .devMaskOpen,image: UIImage(.theatermasks)) { _ in
                    self.maskOpenFunction()
                }
                actions.append(maskOpen)
                
                if self.maskView != nil {
                    let maskTouchBubble = UIAction(title: PTCoreUserDefultsWrapper.AppDebbugTouchBubble ? .devMaskBubbleClose : .devMaskBubbleOpen,image: UIImage(systemName: "bubble.right")) { _ in
                        self.maskOpenBubbleFunction()
                    }
                    actions.append(maskTouchBubble)
                }

                completion(actions)
            }

            
            let masks = UIMenu(title: "Dev Mask", image: UIImage(.theatermasks), children: [deferredMaskList])
            debugActions.append(masks)
        } else {
            let maskOpen = UIAction(title: self.maskView != nil  ? .devMaskClose : .devMaskOpen,image: UIImage(SafeSFSymbol.Person.circle.fill)) { _ in
                self.maskOpenFunction()
            }
            debugActions.append(maskOpen)

            if self.maskView != nil {
                let maskTouchBubble = UIAction(title: PTCoreUserDefultsWrapper.AppDebbugTouchBubble ? .devMaskBubbleClose : .devMaskBubbleOpen,image: UIImage(systemName: "bubble.right")) { _ in
                    self.maskOpenBubbleFunction()
                }
                debugActions.append(maskTouchBubble)
            }
        }

        let viewFrames = UIAction(title: debugBordersEnabled ? .hideViewFrames : .showViewFrames,image: UIImage(systemName: frameSymbol)) { _ in
            self.viewFramesAction()
            self.terminal!.menuButton.menu = self.makeMenu()
        }
        
        let systemReport = UIAction(title: .systemReport, image: UIImage(.cpu)) { _ in
            self.systemReport()
        }
        
        // Show the right glyph for the current device being used.
        let deviceSymbol: String = {
            
            let hasHomeButton = UIScreen.main.value(forKey: "_displ" + "ayCorn" + "erRa" + "dius") as! CGFloat == 0
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                if hasHomeButton {
                    return "ipad.homebutton"
                } else {
                    return "ipad"
                }
            } else if UIDevice.current.userInterfaceIdiom == .phone {
                if hasHomeButton {
                    return "iphone.homebutton"
                } else {
                    return "iphone"
                }
            } else {
                return "rectangle"
            }
        }()
        
        let displayReport = UIAction(title: .displayReport, image: UIImage(systemName: deviceSymbol)) { _ in
            self.displayReport()
        }
        
        let terminateApplication = UIAction(title: .terminateApp, image: UIImage(.xmark), attributes: .destructive) { _ in
            self.terminateApplicationAction()
        }
        
        let respring = UIAction(title: .respring, image: UIImage(.arrowtriangle.backward), attributes: .destructive) { _ in
            self.respringAction()
        }
        
        let debugController = UIAction(title: .debugController,image: UIImage(.pencil),attributes: .destructive) { _ in
            self.debugControllerAction()
        }
        
        debugActions.append(contentsOf: [fps,memory,colorCheck,ruler,document,viewFrames, systemReport, displayReport,Flex,HyperioniOS,FoxNet,InApp])
        let destructActions = [debugController,terminateApplication , respring]
        
        let debugMenu = UIMenu(
            title: .debug, image: UIImage(.ant),
            children: [
                UIMenu(title: "", options: .displayInline, children: debugActions),
                UIMenu(title: "", options: .displayInline, children: destructActions),
            ]
        )
        
        var menuContent: [UIMenuElement] = []
        
        if terminal!.systemText!.text != "" {
            menuContent.append(contentsOf: [UIMenu(title: "", options: .displayInline, children: [share, resize])])
        } else {
            menuContent.append(UIMenu(title: "", options: .displayInline, children: [resize]))
        }
        
        menuContent.append(debugMenu)
        if let customMenu = menu {
            menuContent.append(customMenu)
        }
        
        if terminal!.systemText!.text != "" {
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
    
    func maskOpenFunction() {
        if self.maskView != nil {
            PTCoreUserDefultsWrapper.AppDebbugMark = false
            self.maskView?.removeFromSuperview()
            self.maskView = nil
        } else {
            PTCoreUserDefultsWrapper.AppDebbugMark = true
            
            let maskConfig = PTDevMaskConfig()
            self.maskView = PTDevMaskView(config: maskConfig)
            self.maskView?.frame = AppWindows!.frame
            AppWindows?.addSubview(self.maskView!)
        }
    }
    
    func maskOpenBubbleFunction() {
        PTCoreUserDefultsWrapper.AppDebbugTouchBubble = !PTCoreUserDefultsWrapper.AppDebbugTouchBubble
        if self.maskView != nil {
            self.maskView!.showTouch = PTCoreUserDefultsWrapper.AppDebbugTouchBubble
        }
    }

    func closeAllFunction() {
        self.debugBordersEnabled = false
        PTViewRulerPlugin.share.hide()
        PTColorPickPlugin.share.close()
        PTMemory.share.stopMonitoring()
        PCheckAppStatus.shared.close()
        ResizeController.shared.isActive = false
        PTCoreUserDefultsWrapper.AppDebbugMark = false
        self.maskView?.removeFromSuperview()
        self.maskView = nil
        
        if self.closeAllOutsideFunction != nil {
            self.closeAllOutsideFunction!()
        }
    }

    func debugControllerAction() {
        let vc = PTDebugViewController()
        present(content: vc)
    }
    
    func copyTextAction() {
        self.terminal!.systemText!.text.copyToPasteboard()
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
        self.debugBordersEnabled.toggle()
    }
    
    func watchViewsAction() {
        if self.watchViews != nil {
            self.watchViews!()
        }
    }
    
    func foxNetAction() {
        if self.FoxNet != nil {
            self.FoxNet!()
        }
    }
    
    func hyperioniOSAction() {
        if self.HyperioniOS != nil {
            self.HyperioniOS!()
        }
    }

    func flexAction() {
        if self.flex != nil {
            self.flex!()
        }
    }
    
    func documentAction() {
        let vc = PTFileBrowserViewController()
        present(content: vc)
    }
    
    func present(content:UIViewController) {
        let nav = PTBaseNavControl(rootViewController: content)
        nav.modalPresentationStyle = .fullScreen
        
        PTUtils.getCurrentVC().pt_present(nav) {
            AppWindows?.bringSubviewToFront(self.terminal!)
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
    
    func memoryFunction() {
        if PTMemory.share.closed {
            PTMemory.share.startMonitoring()
        } else {
            PTMemory.share.stopMonitoring()
        }
    }
    
    func fpsFunction() {
        PCheckAppStatus.shared.open()
    }
    
    func userdefaultAction() {
        let vc = PTUserDefultsViewController()
        present(content: vc)
    }
    
    func resizeAction() {
        PTGCDManager.gcdAfter(time: 0.1) {
            ResizeController.shared.isActive.toggle()
            ResizeController.shared.platterView.reveal()
        }
    }
    
    func shareAction() {
        let activityViewController = PTActivityViewController(text: self.terminal!.systemText!.text ?? "")
        activityViewController.previewNumberOfLines = 10
        PTUtils.getCurrentVC().present(activityViewController, animated: true)
    }
    
    func systemReport() {
            
        PTGCDManager.gcdMain() { [self] in

            if currentText != "" { print("\n") }
            
            dynamicReportTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] timer in
                
                guard terminal!.systemText!.panGestureRecognizer.numberOfTouches == 0 else { return }
                
                var _currentText = currentText
                
                // To optimize performance, only scan the last 2500 characters of text for system report changes.
                let range: NSRange = {
                    if _currentText.count <= 2500 {
                        return NSMakeRange(0, _currentText.count)
                    }
                    return NSMakeRange(_currentText.count - 2500, 2500)
                }()
                
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
        
        PTGCDManager.gcdMain() { [self] in

            if currentText != "" { print("\n") }
            
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
    public var systemIsVisible : Bool? = false

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
        systemIsVisible = true

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
        return UIApplication.shared.windows[0].safeAreaInsets.bottom > 0
    }
}
