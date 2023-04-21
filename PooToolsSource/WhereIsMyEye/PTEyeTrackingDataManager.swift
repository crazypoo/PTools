//
//  EyeTrackingDataManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 21/4/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import ARKit

class PTEyeTrackingDataManager {
    
    // 实际设备尺寸(以米为单位)
    private let phoneScreenSize = CGSize(width: 0.0774, height: 0.1575)
    
    private let screenSize: CGRect = UIScreen.main.bounds
    private let smoothingThreshold: Int = 8
    
    private var scene: SCNScene = SCNScene()
    private var faceNode: SCNNode = SCNNode()
    private var eyeLNode: SCNNode = SCNNode()
    private var eyeRNode: SCNNode = SCNNode()
    private var virtualPhoneNode: SCNNode = SCNNode()
    private var lookAtTargetEyeLNode: SCNNode = SCNNode()
    private var lookAtTargetEyeRNode: SCNNode = SCNNode()
    
    private var eyeLookAtPositionXs: [CGFloat] = []
    private var eyeLookAtPositionYs: [CGFloat] = []
    
    private var virtualScreenNode: SCNNode = {
        let geometry =  SCNBox(width: 1, height: 1, length: 0.001, chamferRadius: 0)
        let node = SCNNode()
        node.geometry = geometry
        let parentNode = SCNNode()
        parentNode.addChildNode(node)
        return parentNode
    }()
    
    public init() {
        self.lookAtTargetEyeLNode.position.z = 2
        self.lookAtTargetEyeRNode.position.z = 2
        
        self.eyeLNode.addChildNode(self.lookAtTargetEyeLNode)
        self.eyeRNode.addChildNode(self.lookAtTargetEyeRNode)
        
        self.faceNode.addChildNode(self.eyeLNode)
        self.faceNode.addChildNode(self.eyeRNode)
        
        self.virtualPhoneNode.addChildNode(self.virtualScreenNode)
        
        self.scene.rootNode.addChildNode(self.faceNode)
        self.scene.rootNode.addChildNode(self.virtualPhoneNode)
    }
    
    @available(iOS 12.0 , *)
    func calculateEyeLookAtPoint(anchor: ARFaceAnchor) -> CGPoint {
        self.faceNode.simdTransform = anchor.transform
        self.eyeLNode.simdTransform = anchor.leftEyeTransform
        self.eyeRNode.simdTransform = anchor.rightEyeTransform
        
        var eyeLLookAt = CGPoint()
        var eyeRLookAt = CGPoint()
        
        
        let phoneScreenEyeRHitTestResults = self.virtualScreenNode.hitTestWithSegment(from: self.lookAtTargetEyeRNode.worldPosition,to: self.eyeRNode.worldPosition,options: nil)
        
        let phoneScreenEyeLHitTestResults = self.virtualScreenNode.hitTestWithSegment(from: self.lookAtTargetEyeLNode.worldPosition,to: self.eyeLNode.worldPosition,options: nil)
        
        for result in phoneScreenEyeRHitTestResults {
            eyeRLookAt.x = CGFloat(result.worldCoordinates.x)
            eyeRLookAt.y = CGFloat(result.worldCoordinates.y)
        }
        
        for result in phoneScreenEyeLHitTestResults {
            eyeLLookAt.x = CGFloat(result.worldCoordinates.x)
            eyeLLookAt.y = CGFloat(result.worldCoordinates.y)
        }
        
        self.eyeLookAtPositionXs.append((eyeRLookAt.y + eyeLLookAt.y) / 2)
        self.eyeLookAtPositionYs.append((eyeRLookAt.x + eyeLLookAt.x) / 2)
        self.eyeLookAtPositionXs = Array(self.eyeLookAtPositionXs.suffix(self.smoothingThreshold))
        self.eyeLookAtPositionYs = Array(self.eyeLookAtPositionYs.suffix(self.smoothingThreshold))
        let smoothEyeLookAtPositionX = self.eyeLookAtPositionXs.average ?? 0
        let smoothEyeLookAtPositionY = self.eyeLookAtPositionYs.average ?? 0
        
        let x = smoothEyeLookAtPositionX / (self.phoneScreenSize.width / 2) * self.screenSize.width
        let y = smoothEyeLookAtPositionY / (self.phoneScreenSize.height / 2) * self.screenSize.height
        
        return CGPoint.init(x: x, y: y)
    }
}
