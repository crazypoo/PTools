//
//  PTPermissionMedia.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import MediaPlayer

public extension PTPermission {
    
    static var mediaLibrary: PTPermissionMedia {
        return PTPermissionMedia()
    }
}

public class PTPermissionMedia: PTPermission {
    
    open override var kind: PTPermission.Kind { .mediaLibrary }
    open var usageDescriptionKey: String? { "NSAppleMusicUsageDescription" }
    
    public override var status: PTPermission.Status {
        switch MPMediaLibrary.authorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping () -> Void) {
        MPMediaLibrary.requestAuthorization() { status in
            PTGCDManager.gcdMain {
                completion()
            }
        }
    }
}
