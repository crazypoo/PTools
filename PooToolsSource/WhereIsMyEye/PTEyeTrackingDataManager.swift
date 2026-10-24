//
//  EyeTrackingDataManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import ARKit
import UIKit

// English: Describe whether eye coordinates are calibrated, estimated, or unusable.
// Español: Describe si las coordenadas oculares están calibradas, estimadas o no disponibles.
// 中文：描述眼动坐标当前是已标定、估算还是不可用。
@objc public enum PTEyeTrackingCalibrationState: Int, Sendable {
    case estimated = 0
    case valid = 1
    case needsRecalibration = 2
    case unsupported = 3
}

@MainActor 
class PTEyeTrackingDataManager {
    
    // English: This is only a fallback estimate until the host supplies calibration data.
    // Español: Es solo una estimación de respaldo hasta que el host proporcione calibración.
    // 中文：在宿主提供标定数据前，这只是估算尺寸，不能视为精确测量。
    private var phoneScreenSize = CGSize(width: 0.0774, height: 0.1575)
    private(set) var calibrationState: PTEyeTrackingCalibrationState
    private var lastDisplayBounds: CGSize?
    private var lastDisplayIdentifier: ObjectIdentifier?
    private var lastSceneIdentifier: String?
    
    private var screenSize: CGRect
    private let smoothingThreshold: Int = 8
    
    private var scene: SCNScene = SCNScene()
    private var faceNode: SCNNode = SCNNode()
    private var eyeLNode: SCNNode = SCNNode()
    private var eyeRNode: SCNNode = SCNNode()
    private var virtualPhoneNode: SCNNode = SCNNode()
    private var lookAtTargetEyeLNode: SCNNode = SCNNode()
    private var lookAtTargetEyeRNode: SCNNode = SCNNode()
    
    private var eyeLookAtPositionXs: [CGFloat] = []
    private var eyeLookAtPositionYs: [CGFloat] = []
    
    private var virtualScreenNode: SCNNode = {
        let geometry =  SCNBox(width: 1, height: 1, length: 0.001, chamferRadius: 0)
        let node = SCNNode()
        node.geometry = geometry
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    public init(screenBounds: CGRect = .zero) {
        self.screenSize = screenBounds
        self.calibrationState = screenBounds.isEmpty ? .unsupported : .estimated
        lookAtTargetEyeLNode.position.z = 2
        lookAtTargetEyeRNode.position.z = 2
        
        eyeLNode.addChildNode(lookAtTargetEyeLNode)
        eyeRNode.addChildNode(lookAtTargetEyeRNode)
        
        faceNode.addChildNode(eyeLNode)
        faceNode.addChildNode(eyeRNode)
        
        virtualPhoneNode.addChildNode(virtualScreenNode)
        
        scene.rootNode.addChildNode(faceNode)
        scene.rootNode.addChildNode(virtualPhoneNode)
    }

    // English: Update only the view mapping; physical calibration remains independent.
    // Español: Actualiza solo el mapeo de la vista; la calibración física permanece independiente.
    // 中文：只更新 View 坐标映射，物理屏幕标定与布局尺寸保持分离。
    // English: Keep physical-display and owning-scene changes distinct from local view resizing.
    // Español: Distingue los cambios de pantalla física y de escena propietaria del redimensionado local.
    // 中文：将物理显示器和所属 Scene 变化与本地 View 尺寸变化区分开。
    func update(screenBounds: CGRect,
                displayBounds: CGSize? = nil,
                displayIdentifier: ObjectIdentifier? = nil,
                sceneIdentifier: String? = nil) {
        guard !screenBounds.isEmpty else {
            calibrationState = .unsupported
            eyeLookAtPositionXs.removeAll(keepingCapacity: true)
            eyeLookAtPositionYs.removeAll(keepingCapacity: true)
            return
        }
        self.screenSize = screenBounds

        if calibrationState == .unsupported {
            calibrationState = .estimated
        }

        let displayChanged = (lastDisplayIdentifier != nil || displayIdentifier != nil)
            && lastDisplayIdentifier != displayIdentifier
        let sceneChanged = (lastSceneIdentifier != nil || sceneIdentifier != nil)
            && lastSceneIdentifier != sceneIdentifier
        let nativeBoundsChanged = (lastDisplayBounds != nil || displayBounds != nil)
            && lastDisplayBounds != displayBounds

        if displayChanged || sceneChanged || nativeBoundsChanged {
            invalidateCalibration()
        }

        if let displayBounds,
           displayBounds.width.isFinite,
           displayBounds.height.isFinite,
           displayBounds.width > 0,
           displayBounds.height > 0 {
            self.lastDisplayBounds = displayBounds
        }
        lastDisplayIdentifier = displayIdentifier
        lastSceneIdentifier = sceneIdentifier
    }

    // English: Accept physical dimensions only when both values are finite and positive.
    // Español: Acepta dimensiones físicas solo cuando ambas son finitas y positivas.
    // 中文：仅接受有限且大于零的物理尺寸，避免把无效数据当作精确标定。
    func updateCalibration(screenSizeMeters: CGSize) {
        guard screenSizeMeters.width.isFinite,
              screenSizeMeters.height.isFinite,
              screenSizeMeters.width > 0,
              screenSizeMeters.height > 0 else {
            calibrationState = screenSize.isEmpty ? .unsupported : .needsRecalibration
            return
        }
        phoneScreenSize = screenSizeMeters
        calibrationState = screenSize.isEmpty ? .unsupported : .valid
    }

    // English: Force callers to acknowledge that the old physical estimate is no longer trusted.
    // Español: Obliga a reconocer que la estimación física antigua ya no es fiable.
    // 中文：明确标记旧物理估算已不再可信，等待重新标定。
    func invalidateCalibration() {
        calibrationState = screenSize.isEmpty ? .unsupported : .needsRecalibration
        eyeLookAtPositionXs.removeAll(keepingCapacity: true)
        eyeLookAtPositionYs.removeAll(keepingCapacity: true)
    }

    // English: Reset tracking samples without discarding a legacy estimate; precise calibration becomes stale.
    // Español: Reinicia las muestras sin descartar la estimación heredada; la calibración precisa queda obsoleta.
    // 中文：重置追踪样本但保留旧版估算；精确标定会被标记为过期。
    func trackingSessionDidReset() {
        eyeLookAtPositionXs.removeAll(keepingCapacity: true)
        eyeLookAtPositionYs.removeAll(keepingCapacity: true)
        if screenSize.isEmpty {
            calibrationState = .unsupported
        } else {
            calibrationState = calibrationState == .valid || calibrationState == .needsRecalibration
                ? .needsRecalibration
                : .estimated
        }
    }

    // English: Return nil for an unusable calibration instead of using (0, 0) as a sentinel.
    // Español: Devuelve nil para una calibración no utilizable en vez de usar (0, 0) como marcador.
    // 中文：无效标定返回 nil，不再用 (0, 0) 充当无效哨兵。
    func validatedLookAtPoint(_ point: CGPoint) -> CGPoint? {
        guard !screenSize.isEmpty,
              calibrationState != .unsupported,
              calibrationState != .needsRecalibration,
              point.x.isFinite,
              point.y.isFinite else { return nil }
        return point
    }

    func calculateEyeLookAtPoint(anchor: ARFaceAnchor) -> CGPoint? {
        guard !screenSize.isEmpty,
              calibrationState != .unsupported,
              calibrationState != .needsRecalibration else { return nil }

        faceNode.simdTransform = anchor.transform
        eyeLNode.simdTransform = anchor.leftEyeTransform
        eyeRNode.simdTransform = anchor.rightEyeTransform
        
        var eyeLLookAt = CGPoint()
        var eyeRLookAt = CGPoint()
        
        
        let phoneScreenEyeRHitTestResults = virtualScreenNode.hitTestWithSegment(from: lookAtTargetEyeRNode.worldPosition,to: eyeRNode.worldPosition,options: nil)
        
        let phoneScreenEyeLHitTestResults = virtualScreenNode.hitTestWithSegment(from: lookAtTargetEyeLNode.worldPosition,to: eyeLNode.worldPosition,options: nil)
        
        for result in phoneScreenEyeRHitTestResults {
            eyeRLookAt.x = CGFloat(result.worldCoordinates.x)
            eyeRLookAt.y = CGFloat(result.worldCoordinates.y)
        }
        
        for result in phoneScreenEyeLHitTestResults {
            eyeLLookAt.x = CGFloat(result.worldCoordinates.x)
            eyeLLookAt.y = CGFloat(result.worldCoordinates.y)
        }
        
        eyeLookAtPositionXs.append((eyeRLookAt.y + eyeLLookAt.y) / 2)
        eyeLookAtPositionYs.append((eyeRLookAt.x + eyeLLookAt.x) / 2)
        eyeLookAtPositionXs = Array(eyeLookAtPositionXs.suffix(smoothingThreshold))
        eyeLookAtPositionYs = Array(eyeLookAtPositionYs.suffix(smoothingThreshold))
        let smoothEyeLookAtPositionX = eyeLookAtPositionXs.average ?? 0
        let smoothEyeLookAtPositionY = eyeLookAtPositionYs.average ?? 0

        let x = smoothEyeLookAtPositionX / (phoneScreenSize.width / 2) * screenSize.width
        let y = smoothEyeLookAtPositionY / (phoneScreenSize.height / 2) * screenSize.height

        return validatedLookAtPoint(CGPoint(x: x, y: y))
    }
}
