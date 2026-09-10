//
//  PTPermissionPhotoLibrary.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Photos
#if POOTOOLS_SPLIT_PERMISSION_CORE
import PToolsPermissionCore
#endif

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
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        case .limited: return .authorized
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        // English: Use PhotoKit's async authorization API so Photos never invokes a MainActor callback on its own queue.
        // Español: Usa la API async de autorización de PhotoKit para que Photos nunca invoque un callback de MainActor en su propia cola.
        // 中文：使用 PhotoKit 的异步授权 API，避免 Photos 队列直接调用 MainActor 回调闭包。
        Task { @MainActor in
            _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            completion()
        }
    }
}
