//
//  C7CameraConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

// English: Import the umbrella Core target explicitly for standalone SwiftPM builds.
// Español: Importa explícitamente el target Core para las compilaciones SwiftPM independientes.
// 中文：独立 SwiftPM 编译时，显式导入 Core 聚合 target。
#if SWIFT_PACKAGE
import ptools
import PooToolsHud
import PooToolsLoading
#endif
import AVFoundation

@MainActor
public class C7CameraConfig: NSObject {
    public static let share = C7CameraConfig()

    // English: Keep camera control metrics in the implementation target so the collector does not depend on a view controller.
    // Español: Mantiene las métricas de control de cámara en el target de implementación para que el collector no dependa de un controlador.
    // 中文：将相机控制尺寸集中在实现 target 中，避免采集器反向依赖控制器。
    public static let largeCircleRadius: CGFloat = 80
    public static let borderLayerWidth: CGFloat = 1.8
    public static let smallCircleRadius: CGFloat = 65
    public static let largeCircleRecordScale: CGFloat = 1.2
    public static let smallCircleRecordScale: CGFloat = 0.5
    public static let cameraBtnRecodingBorderColor: UIColor = .white.withAlphaComponent(0.8)
    public static let cameraBtnNormalColor: UIColor = .white
    public static let toolBarHeight: CGFloat = 120
    public static let animateLayerWidth: CGFloat = 5
    public static let filterCollectionHeight: CGFloat = 108

    // English: Camera flows can own an independent configuration instead of mutating the shared default.
    // Español: Los flujos de cámara pueden poseer una configuración independiente sin mutar el valor compartido.
    // 中文：相机流程可以持有独立配置，不再必须修改 shared 默认值。
    public override init() {
        super.init()
    }
    /// The default camera position after entering the camera. Defaults to back.
    public var devicePosition: C7CameraConfig.DevicePosition = .back
    @objc public enum DevicePosition: Int {
        case back
        case front
        
        /// For custom camera
        var avDevicePosition: AVCaptureDevice.Position {
            switch self {
            case .back:
                return .back
            case .front:
                return .front
            }
        }
        
        /// For system camera
        var cameraDevice: UIImagePickerController.CameraDevice {
            switch self {
            case .back:
                return .rear
            case .front:
                return .front
            }
        }
    }
    
    @discardableResult
    func devicePosition(_ position: C7CameraConfig.DevicePosition) -> C7CameraConfig {
        devicePosition = position
        return self
    }
    
    @discardableResult
    func sessionPreset(_ sessionPreset: C7CameraConfig.CaptureSessionPreset) -> C7CameraConfig {
        self.sessionPreset = sessionPreset
        return self
    }

    /// Video resolution. Defaults to hd1920x1080.
    public var sessionPreset: C7CameraConfig.CaptureSessionPreset = .hd1920x1080

    @objc public enum CaptureSessionPreset: Int {
        var avSessionPreset: AVCaptureSession.Preset {
            switch self {
            case .cif352x288:
                return .cif352x288
            case .vga640x480:
                return .vga640x480
            case .hd1280x720:
                return .hd1280x720
            case .hd1920x1080:
                return .hd1920x1080
            case .hd4K3840x2160:
                return .hd4K3840x2160
            case .photo:
                return .photo
            }
        }
        
        case cif352x288
        case vga640x480
        case hd1280x720
        case hd1920x1080
        case hd4K3840x2160
        case photo
    }

    public class func hasCameraAuthority() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .restricted || status == .denied {
            return false
        }
        return true
    }
    
    var hud:PTHudView?
    @MainActor private func hudConfig() {
        let hudConfig = PTHudConfig.share
        hudConfig.hudColors = [.gray,.gray]
        hudConfig.lineWidth = 4
    }
    
    func hudShow() {
        Task { @MainActor in
            self.hudConfig()
            if self.hud == nil {
                self.hud = PTHudView()
                self.hud!.hudShow()
            }
        }
    }
    
    func hudHide(completion:PTActionTask? = nil) {
        if self.hud != nil {
            self.hud!.hide {
                Task { @MainActor in
                    self.hud = nil
                    completion?()
                }
            }
        }
    }
}
