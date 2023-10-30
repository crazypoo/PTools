//
//  PTPermissionPhotoLibrary.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Photos

public extension PTPermission {
    
    static var photoLibrary: PTPermissionPhotoLibrary {
        PTPermissionPhotoLibrary()
    }
}

public class PTPermissionPhotoLibrary: PTPermission {
    
    open override var kind: PTPermission.Kind { .photoLibrary }
    
    open var fullAccessUsageDescriptionKey: String? {
        "NSPhotoLibraryUsageDescription"
    }
    
    open var addingOnlyUsageDescriptionKey: String? {
        "NSPhotoLibraryAddUsageDescription"
    }
    
    public override var status: PTPermission.Status {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .limited: return .authorized
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization({
            finished in
            PTGCDManager.gcdMain {
                completion()
            }
        })
    }
}
