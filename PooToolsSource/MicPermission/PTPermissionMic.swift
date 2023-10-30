//
//  PTPermissionMic.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 19/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import AVFoundation

public extension PTPermission {
    
    static var microphone: PTPermissionMic {
        PTPermissionMic()
    }
}

public class PTPermissionMic: PTPermission {
    
    open override var kind: PTPermission.Kind { .microphone }
    open var usageDescriptionKey: String? { "NSMicrophoneUsageDescription" }
    
    public override var status: PTPermission.Status {
        switch  AVAudioSession.sharedInstance().recordPermission {
        case .granted: return .authorized
        case .denied: return .denied
        case .undetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    public override func request(completion: @escaping () -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission {
            granted in
            PTGCDManager.gcdMain {
                completion()
            }
        }
    }
}
