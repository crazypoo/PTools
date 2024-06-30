//
//  C7CameraConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation

public class C7CameraConfig: NSObject {
    static let share = C7CameraConfig()
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
    private func hudConfig() {
        let hudConfig = PTHudConfig.share
        hudConfig.hudColors = [.gray,.gray]
        hudConfig.lineWidth = 4
    }
    
    func hudShow() {
        PTGCDManager.gcdMain {
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
                self.hud = nil
                if completion != nil {
                    completion!()
                }
            }
        }
    }
}
