//
//  C7CameraConfig.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

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

}
