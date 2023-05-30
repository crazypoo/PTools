//
//  PTEyeTrackingSessionManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import ARKit

//MARK: PTEyeTrackingSessionManagerDelegate
@available(iOS 12.0, *)
protocol PTEyeTrackingSessionManagerDelegate {
    func update(withFaceAnchor: ARFaceAnchor)
}


//MARK: PTEyeTrackingSessionManager
@available(iOS 12.0, *)
internal class PTEyeTrackingSessionManager: NSObject {
    
    private struct Constants {
        static let ERR_MESSAGE_NOT_SUPPORTED : String = "该手机不支持该操作"
    }
    
    private var session: ARSession = ARSession()
    internal var delegate: PTEyeTrackingSessionManagerDelegate?
    
    internal func run() {
        session.delegate = self
        guard ARFaceTrackingConfiguration.isSupported else {
            print(Constants.ERR_MESSAGE_NOT_SUPPORTED)
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = false
        configuration.worldAlignment = .camera
        
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    internal func pause() {
        session.pause()
    }
}


//MARK: ARSessionDelegate
@available(iOS 12.0, *)
extension PTEyeTrackingSessionManager: ARSessionDelegate {

    internal func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors[0] as? ARFaceAnchor else { return }
        delegate?.update(withFaceAnchor: faceAnchor)
    }
    
    internal func session(_ session: ARSession, didFailWithError error: Error) {
        PTNSLogConsole(error.localizedDescription)
    }
}
