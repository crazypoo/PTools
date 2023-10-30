//
//  PTPermissionCamera.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation

@available(iOS 11.0, macCatalyst 14.0, *)
public extension PTPermission {
    
    static var camera: PTPermissionCamera {
        PTPermissionCamera()
    }
}

@available(iOS 11.0, macCatalyst 14.0, *)
public class PTPermissionCamera: PTPermission {
    
    open override var kind: PTPermission.Kind { .camera }
    open var usageDescriptionKey: String? { "NSCameraUsageDescription" }
    
    public override var status: PTPermission.Status {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping () -> Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
            finished in
            PTGCDManager.gcdMain {
                completion()
            }
        })
    }
}
