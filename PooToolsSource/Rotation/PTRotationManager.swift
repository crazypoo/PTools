//
//  PTRotationManager.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 4/12/22.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTRotationManager: NSObject {
    static let share = PTRotationManager()
    
    /*! @brief 初始化
     * @see 在Appdelegate中加载此方法
     - (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
     return [PTRotationManager share].interfaceOrientationMask;
     }
     * @see 在须要变换状态的ViewController中使用此方法
     [PTRotationManager share].orientation = UIDeviceOrientationLandscapeRight;
     * @attention 不支持iPad
     */
    
    @objc public var interfaceOrientationMask: UIInterfaceOrientationMask = .portrait
    @objc public var orientation: UIDeviceOrientation = .portrait
    
    @objc public func setOrientation(orientation:UIDeviceOrientation) {
        if self.orientation == orientation {
            return
        }
        
        if UIDevice.current.orientation == orientation {
            UIDevice.current.setValue(self.orientation, forKey: "orientation")
        }
        
        var interfaceOrientationMask : UIInterfaceOrientationMask = .portrait
        switch orientation {
        case .portrait:
            interfaceOrientationMask = .portrait
        case .portraitUpsideDown:
            interfaceOrientationMask = .portraitUpsideDown
        case .landscapeRight:
            interfaceOrientationMask = .landscapeLeft
        case .landscapeLeft:
            interfaceOrientationMask = .landscapeRight
        default:
            interfaceOrientationMask = .portrait
        }
        
        PTRotationManager.share.interfaceOrientationMask = interfaceOrientationMask
        UIDevice.current.setValue(orientation, forKey: "orientation")
    }
}
