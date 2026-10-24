//
//  PTEyeTrackingManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation

// English: Import the umbrella Core target explicitly for standalone SwiftPM builds.
// Español: Importa explícitamente el target Core para las compilaciones SwiftPM independientes.
// 中文：独立 SwiftPM 编译时，显式导入 Core 聚合 target。
#if SWIFT_PACKAGE
import ptools
#endif
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
@MainActor
public class PTEyeTrackingManager: NSObject {

    // English: Expose calibration confidence without changing the existing point callback API.
    // Español: Expone la confianza de calibración sin cambiar la API existente de puntos.
    // 中文：在不改变原有坐标回调 API 的前提下暴露标定可信度。
    @objc public var calibrationState: PTEyeTrackingCalibrationState {
        dataManager?.calibrationState ?? .unsupported
    }
    
    /**
     EyeTracking功能是否可用。
     
     可在满足以下条件的机器上使用，并返回true。
     - SW : iOS 12.0+
     - HW : 支持TrueDepth Camera的机器
     */
    @objc public class var isSupported: Bool {
        get {
            return ARFaceTrackingConfiguration.isSupported
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
    private var dataManager: PTEyeTrackingDataManager?
    
    private var screenSize = CGRect.zero
    private weak var trackingHostView: UIView?
    
    private let testUtility = PTEyeTrackingTestUtility()
    
    /**
     EyeTrackingManager的初始化。
    
     判断EyeTracking功能是否可以使用，在可以使用的情况下，构成ARSession和其他EyeTracking的环境。
     为了处理视线追踪事件，EyeTrackingDelegate的实现体必须被分配。
     */
    @objc public override init() {
        super.init()
        if PTEyeTrackingManager.isSupported {
            let initialBounds = PTSceneContext.activeWindow()?.bounds ?? .zero
            screenSize = initialBounds
            dataManager = PTEyeTrackingDataManager(screenBounds: initialBounds)
            sessionManager = PTEyeTrackingSessionManager()
            if let sessionManager = sessionManager as? PTEyeTrackingSessionManager {
                sessionManager.delegate = self
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        } else {
            PTNSLogConsole(Constants.ERR_MESSAGE, levelType: .error,loggerType: .debug)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: PTEyeTrackingManager扩展
extension PTEyeTrackingManager {

    @MainActor private func updateHostBounds(_ parent: UIView) {
        guard !parent.bounds.isEmpty else { return }
        trackingHostView = parent
        screenSize = parent.bounds
        testUtility.updateHostBounds(screenSize)
        dataManager?.update(screenBounds: screenSize,
                            displayBounds: parent.window?.screen.nativeBounds.size,
                            displayIdentifier: parent.window.map { ObjectIdentifier($0.screen) },
                            sceneIdentifier: parent.window?.windowScene?.session.persistentIdentifier)
    }

    // English: Supply a measured physical display size before treating eye points as precise.
    // Español: Proporciona el tamaño físico medido antes de tratar los puntos como precisos.
    // 中文：提供实测物理屏幕尺寸后，才将眼动坐标视为精确结果。
    @objc public func calibrate(screenSizeMeters: CGSize) {
        dataManager?.updateCalibration(screenSizeMeters: screenSizeMeters)
    }

    // English: Mark calibration stale after a display or tracking setup change.
    // Español: Marca la calibración como obsoleta tras cambiar la pantalla o la sesión.
    // 中文：屏幕或追踪环境变化后，将当前标定标记为需要重新校准。
    @objc public func invalidateCalibration() {
        dataManager?.invalidateCalibration()
    }
    /**
     EyeTracking的ARSession。
     
     ARFaceTrackingConfiguration, worldAlignment = .camera, isLightEstimationEnabled = false,的环境中运行ARSession。
     建议使用EyeTracking功能的ViewController的viewWillAppear()调用。
     */
    @objc public func run() {
        if PTEyeTrackingManager.isSupported {
            dataManager?.trackingSessionDidReset()
            if let sessionManager = sessionManager as? PTEyeTrackingSessionManager {
                sessionManager.run()
            }
        }
    }
    
    /**
     中断EyeTracking的ARSession。
     
     建议在ViewController의 viewWillDisappear()的方法中调用
     */
    @objc public func pause() {
        if PTEyeTrackingManager.isSupported {
            if let sessionManager = sessionManager as? PTEyeTrackingSessionManager {
                sessionManager.pause()
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
        updateHostBounds(parent)
        testUtility.showStatusView(parent: parent)
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
        updateHostBounds(parent)
        testUtility.showCursorView(parent: parent)
    }
    
    /**
     隐藏UILabel显示当前EyeTracking状态。
     */
    @objc public func hideStatusView() {
        testUtility.hideStatusView()
    }
    
    /**
     隐藏当前EyeTracking状态的CursorView。
     */
    @objc public func hideCursorView() {
        testUtility.hideCursorView()
    }
}

//MARK: PTEyeTrackingSessionManagerDelegate的时间处理
extension PTEyeTrackingManager: @preconcurrency PTEyeTrackingSessionManagerDelegate {
    
    @MainActor func update(withFaceAnchor anchor: ARFaceAnchor) {
        guard let dataManager else {
            return
        }
        
        let lookAtPoint = dataManager.calculateEyeLookAtPoint(anchor: anchor)
        checkTrackingState(withFaceAnchor: anchor)

        guard let lookAtPoint else { return }
        findLookAt(with : lookAtPoint)
        testUtility.updateTestViews(with: lookAtPoint)
    }
}

// MARK: 屏幕旋转处理
extension PTEyeTrackingManager {
    
    @MainActor @objc private func rotated() {
        guard let trackingHostView else { return }
        updateHostBounds(trackingHostView)
        testUtility.rotated()
    }
}

//MARK: 事件感知的代码
extension PTEyeTrackingManager {
    
    /// 发生您正在看的部分的事件。
    @MainActor private func findLookAt(with lookAtPoint: CGPoint) {
        // 在无法追踪的情况下会被return。
        if trackingState == .notTracked {
            return
        }
        
        guard let delegate = delegate else {
            return
        }
        
        if delegate.responds(to: #selector(PTEyeTrackingDelegate.didChange(lookAtPoint:))) {
            let x = max(-screenSize.width / 2, min(lookAtPoint.x, screenSize.width / 2))
            let y = max(-screenSize.height / 2, min(lookAtPoint.y, screenSize.height / 2))
            let point = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
            let transformedPoint = point.applying(CGAffineTransform(translationX: x, y: y))
            
            delegate.didChange(lookAtPoint: transformedPoint)
        } else {
            PTNSLogConsole("didChange(eyeLookAtState:lookAtPoint:)  \(Constants.FUNC_NOT_DECLARED)", levelType: .error,loggerType: .debug)
        }
    }
    
    private func checkTrackingState(withFaceAnchor anchor: ARFaceAnchor) {
        let bufferSize = 6  // 每隔约60秒，约0.1秒。
        eyeLTransformBuffer.append(anchor.leftEyeTransform)
        eyeRTransformBuffer.append(anchor.rightEyeTransform)
        eyeLTransformBuffer = Array(eyeLTransformBuffer.suffix(bufferSize))
        eyeRTransformBuffer = Array(eyeRTransformBuffer.suffix(bufferSize))
        
        guard eyeLTransformBuffer.count >= bufferSize && eyeRTransformBuffer.count >= bufferSize else { return }
        guard let delegate = delegate else { return }
        let isTrackingStopped = eyeLTransformBuffer.isAllEqual! && eyeRTransformBuffer.isAllEqual!
        
        if isTrackingStopped && trackingState == .tracking {
            trackingState = .notTracked
            PTNSLogConsole(Constants.TRACHING_STOPPED, levelType: .error,loggerType: .debug)
            // 保持屏幕睡眠
            UIApplication.shared.isIdleTimerDisabled = false
        } else if !isTrackingStopped && trackingState == .notTracked {
            trackingState = .tracking
            PTNSLogConsole(Constants.TRACHING_STARTED, levelType: .error,loggerType: .debug)
            // 为了不让画面变暗
            UIApplication.shared.isIdleTimerDisabled = true
        } else {
            // 忽略其他情况。
        }
        
        if delegate.responds(to: #selector(PTEyeTrackingDelegate.didChange(eyeTrackingState:))) {
            delegate.didChange(eyeTrackingState: trackingState)
        } else {
            PTNSLogConsole("didChange(eyeTrackingState:)  \(Constants.FUNC_NOT_DECLARED)", levelType: .error,loggerType: .debug)
        }
    }
}



