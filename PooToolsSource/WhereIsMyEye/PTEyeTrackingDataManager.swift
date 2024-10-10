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
        lookAtTargetEyeLNode.position.z = 2
        lookAtTargetEyeRNode.position.z = 2
        
        eyeLNode.addChildNode(lookAtTargetEyeLNode)
        eyeRNode.addChildNode(lookAtTargetEyeRNode)
        
        faceNode.addChildNode(eyeLNode)
        faceNode.addChildNode(eyeRNode)
        
        virtualPhoneNode.addChildNode(virtualScreenNode)
        
        scene.rootNode.addChildNode(faceNode)
        scene.rootNode.addChildNode(virtualPhoneNode)
    }
    
    func calculateEyeLookAtPoint(anchor: ARFaceAnchor) -> CGPoint {
        faceNode.simdTransform = anchor.transform
        eyeLNode.simdTransform = anchor.leftEyeTransform
        eyeRNode.simdTransform = anchor.rightEyeTransform
        
        var eyeLLookAt = CGPoint()
        var eyeRLookAt = CGPoint()
        
        
        let phoneScreenEyeRHitTestResults = virtualScreenNode.hitTestWithSegment(from: lookAtTargetEyeRNode.worldPosition,to: eyeRNode.worldPosition,options: nil)
        
        let phoneScreenEyeLHitTestResults = virtualScreenNode.hitTestWithSegment(from: lookAtTargetEyeLNode.worldPosition,to: eyeLNode.worldPosition,options: nil)
        
        for result in phoneScreenEyeRHitTestResults {
            eyeRLookAt.x = CGFloat(result.worldCoordinates.x)
            eyeRLookAt.y = CGFloat(result.worldCoordinates.y)
        }
        
        for result in phoneScreenEyeLHitTestResults {
            eyeLLookAt.x = CGFloat(result.worldCoordinates.x)
            eyeLLookAt.y = CGFloat(result.worldCoordinates.y)
        }
        
        eyeLookAtPositionXs.append((eyeRLookAt.y + eyeLLookAt.y) / 2)
        eyeLookAtPositionYs.append((eyeRLookAt.x + eyeLLookAt.x) / 2)
        eyeLookAtPositionXs = Array(eyeLookAtPositionXs.suffix(smoothingThreshold))
        eyeLookAtPositionYs = Array(eyeLookAtPositionYs.suffix(smoothingThreshold))
        let smoothEyeLookAtPositionX = eyeLookAtPositionXs.average ?? 0
        let smoothEyeLookAtPositionY = eyeLookAtPositionYs.average ?? 0
        
        let x = smoothEyeLookAtPositionX / (phoneScreenSize.width / 2) * screenSize.width
        let y = smoothEyeLookAtPositionY / (phoneScreenSize.height / 2) * screenSize.height
        
        return CGPoint.init(x: x, y: y)
    }
}
