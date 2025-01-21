//
//  PTPermissionSpeech.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import Speech

public extension PTPermission {

    static var speech: PTPermissionSpeech {
        PTPermissionSpeech()
    }
}

public class PTPermissionSpeech: PTPermission {
    
    open override var kind: PTPermission.Kind { .speech }
    open var usageDescriptionKey: String? { "NSSpeechRecognitionUsageDescription" }
    
    public override var status: PTPermission.Status {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return .authorized
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        case .restricted: return .denied
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping PTActionTask) {
        SFSpeechRecognizer.requestAuthorization { status in
            PTGCDManager.gcdMain {
                completion()
            }
        }
    }
}
