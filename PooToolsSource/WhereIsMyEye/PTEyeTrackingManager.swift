//
//  PTEyeTrackingManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import ARKit
import UIKit

//MARK: 追踪眼球的活动
@objc(PTEyeTrackingDelegate)
public protocol PTEyeTrackingDelegate: NSObjectProtocol {
    
    /**
     使用ARFaceAnchor感知的用户正在观看设备屏幕时发生的事件。
     
     - Parameter state: 显示你在看屏幕的哪个部分。
     - Parameter scrollOffset: 让它滚动这个值，它就会自然地滚动。
     */
    func didChange(lookAtPoint: CGPoint)
    
    /**
     眼球追踪的状态变化。
     
     当追踪开始时和追踪中断时就会被呼叫。
     */
    func didChange(eyeTrackingState: PTEyeTrackingState)
}


/**
 EyeTracking状态。
 
 - tracking: EyeTracking的正常运行状态
 - notTracked: 处于初期状态或没有视线信息，所以追踪功能不完善
 */
@objc public enum PTEyeTrackingState: Int {
    /// EyeTracking的正常运行状态
    case tracking = 0
    /// 由于前置摄像头无法识别脸部导致EyeTracking中断
    case notTracked = 1
}


/**
 通过TrueDepthCamera追踪用户的视线，感知用户正在注视画面上端和下端的状态。
 
 库和应用程序之间的通信都是通过EyeTrackingManager进行的。
 - 要在 iOS 12.0 + , TrueDepthCamera的设备上运行
 */
public class PTEyeTrackingManager: NSObject {
    
    /**
     EyeTracking功能是否可用。
     
     可在满足以下条件的机器上使用，并返回true。
     - SW : iOS 12.0+
     - HW : 支持TrueDepth Camera的机器
     */
    @objc public class var isSupported: Bool {
        get {
            if #available(iOS 12.0, *) {
                return ARFaceTrackingConfiguration.isSupported
            } else {
                return false
            }
        }
    }
    
    /**
     这个对象是EyeTreacking的delegate。
     
     这个delegate必须分配EyeTrackingDelegate的实现体。
     */
    public var delegate: PTEyeTrackingDelegate?
    
    private var trackingState: PTEyeTrackingState = .notTracked {
        didSet { testUtility.trackingState = trackingState }
    }
    
    private struct Constants {
        static let ERR_MESSAGE: String = "要在 iOS 12.0 + , TrueDepthCamera的设备上运行"
        static let TRACHING_STARTED: String = "开始追踪。"
        static let TRACHING_STOPPED: String = "停止追踪。"
        static let FUNC_NOT_DECLARED: String = "函数没有实现。"
    }
    
    private var eyeLTransformBuffer: [simd_float4x4] = []
    private var eyeRTransformBuffer: [simd_float4x4] = []
    
    private var sessionManager: AnyObject?
    private var dataManager: AnyObject?
    
    private var portraitScreenSize: CGRect?
    private var screenSize = kSCREEN_BOUNDS
    
    private let testUtility = PTEyeTrackingTestUtility()
    
    /**
     EyeTrackingManager的初始化。
    
     判断EyeTracking功能是否可以使用，在可以使用的情况下，构成ARSession和其他EyeTracking的环境。
     为了处理视线追踪事件，EyeTrackingDelegate的实现体必须被分配。
     */
    @objc public override init() {
        super.init()
        if #available(iOS 12.0, *) {
            if PTEyeTrackingManager.isSupported {
                self.dataManager = PTEyeTrackingDataManager()
                self.sessionManager = PTEyeTrackingSessionManager()
                if let sessionManager = self.sessionManager as? PTEyeTrackingSessionManager {
                    sessionManager.delegate = self
                }
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
            } else {
                PTNSLogConsole(Constants.ERR_MESSAGE)
            }
        } else {
            PTNSLogConsole(Constants.ERR_MESSAGE)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: PTEyeTrackingManager扩展
extension PTEyeTrackingManager {
    /**
     EyeTracking的ARSession。
     
     ARFaceTrackingConfiguration, worldAlignment = .camera, isLightEstimationEnabled = false,的环境中运行ARSession。
     建议使用EyeTracking功能的ViewController的viewWillAppear()调用。
     */
    @objc public func run() {
        if #available(iOS 12.0, *) {
            if PTEyeTrackingManager.isSupported {
                if let sessionManager = self.sessionManager as? PTEyeTrackingSessionManager {
                    sessionManager.run()
                }
            }
        }
    }
    
    /**
     中断EyeTracking的ARSession。
     
     建议在ViewController의 viewWillDisappear()的方法中调用
     */
    @objc public func pause() {
        if #available(iOS 12.0, *) {
            if PTEyeTrackingManager.isSupported {
                if let sessionManager = self.sessionManager as? PTEyeTrackingSessionManager {
                    sessionManager.pause()
                }
            }
        }
    }
}

//MARK: PTEyeTrackingManager扩展
extension PTEyeTrackingManager {
    
    /**
     显示目前EyeTracking状态的UILabel。
     
     在ViewController의 viewDidLoad() 中使用.
     ```
     eyeTrackingManager.showStatusView(parent: self.view)
     ```
     - Parameter parent: 指定添加UILabel的父视图。
     */
    @objc public func showStatusView(parent: UIView) {
        self.testUtility.showStatusView(parent: parent)
    }
    
    /**
     显示当前EyeTracking状态的CursorView。
     
     ViewController의 viewDidLoad() 中使用.
     ```
     eyeTrackingManager.showCursorView(parent: self.view)
     ```
     - Parameter parent: 指定添加UILabel的父视图。这时，父视图使用ViewController中的View。
     
     */
    @objc public func showCursorView(parent: UIView) {
        self.testUtility.showCursorView(parent: parent)
    }
    
    /**
     隐藏UILabel显示当前EyeTracking状态。
     */
    @objc public func hideStatusView() {
        self.testUtility.hideStatusView()
    }
    
    /**
     隐藏当前EyeTracking状态的CursorView。
     */
    @objc public func hideCursorView() {
        self.testUtility.hideCursorView()
    }
}

//MARK: PTEyeTrackingSessionManagerDelegate的时间处理
@available(iOS 12.0, *)
extension PTEyeTrackingManager: PTEyeTrackingSessionManagerDelegate {
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        guard let dataManager = self.dataManager as? PTEyeTrackingDataManager else {
            return
        }
        
        let lookAtPoint = dataManager.calculateEyeLookAtPoint(anchor: anchor)
        
        //TODO: 重要的是顺序
        self.findLookAt(with : lookAtPoint)
        self.checkTrackingState(withFaceAnchor: anchor)
        self.testUtility.updateTestViews(with: lookAtPoint)
    }
}

// MARK: 屏幕旋转处理
extension PTEyeTrackingManager {
    
    @objc private func rotated() {
        guard let portraitScreenSize = portraitScreenSize else { return }
        
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.portrait: fallthrough
        case UIDeviceOrientation.portraitUpsideDown:
            self.screenSize = portraitScreenSize
        case UIDeviceOrientation.landscapeLeft: fallthrough
        case UIDeviceOrientation.landscapeRight:
            self.screenSize = CGRect.init(x: 0, y: 0, width: portraitScreenSize.height, height: portraitScreenSize.width)
        default:break
        }
        
        self.testUtility.screenSize = screenSize
        self.testUtility.rotated()
    }
}

//MARK: 事件感知的代码
@available(iOS 12.0, *)
extension PTEyeTrackingManager {
    
    /// 发生您正在看的部分的事件。
    private func findLookAt(with lookAtPoint: CGPoint) {
        // 在无法追踪的情况下会被return。
        if self.trackingState == .notTracked {
            return
        }
        
        guard let delegate = self.delegate else {
            return
        }
        
        if delegate.responds(to: #selector(PTEyeTrackingDelegate.didChange(lookAtPoint:))) {
            let x = max(-self.screenSize.width / 2, min(lookAtPoint.x, self.screenSize.width / 2))
            let y = max(-self.screenSize.height / 2, min(lookAtPoint.y, self.screenSize.height / 2))
            let point = CGPoint(x: self.screenSize.width / 2, y: self.screenSize.height / 2)
            let transformedPoint = point.applying(CGAffineTransform(translationX: x, y: y))
            
            delegate.didChange(lookAtPoint: transformedPoint)
        } else {
            PTNSLogConsole("didChange(eyeLookAtState:lookAtPoint:)  \(Constants.FUNC_NOT_DECLARED)")
        }
    }
    
    private func checkTrackingState(withFaceAnchor anchor: ARFaceAnchor) {
        let bufferSize = 6  // 每隔约60秒，约0.1秒。
        self.eyeLTransformBuffer.append(anchor.leftEyeTransform)
        self.eyeRTransformBuffer.append(anchor.rightEyeTransform)
        self.eyeLTransformBuffer = Array(self.eyeLTransformBuffer.suffix(bufferSize))
        self.eyeRTransformBuffer = Array(self.eyeRTransformBuffer.suffix(bufferSize))
        
        guard self.eyeLTransformBuffer.count >= bufferSize && self.eyeRTransformBuffer.count >= bufferSize else { return }
        guard let delegate = self.delegate else { return }
        let isTrackingStopped = self.eyeLTransformBuffer.isAllEqual! && self.eyeRTransformBuffer.isAllEqual!
        
        if isTrackingStopped && self.trackingState == .tracking {
            self.trackingState = .notTracked
            print(Constants.TRACHING_STOPPED)
            // 保持屏幕睡眠
            UIApplication.shared.isIdleTimerDisabled = false
        } else if !isTrackingStopped && self.trackingState == .notTracked {
            self.trackingState = .tracking
            print(Constants.TRACHING_STARTED)
            // 为了不让画面变暗
            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            // 忽略其他情况。
        }
        
        if delegate.responds(to: #selector(PTEyeTrackingDelegate.didChange(eyeTrackingState:))) {
            delegate.didChange(eyeTrackingState: self.trackingState)
        } else {
            PTNSLogConsole("didChange(eyeTrackingState:)  \(Constants.FUNC_NOT_DECLARED)")
        }
    }
}



