//
//  AppDelegate+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public class AppDelegateEXFunction:NSObject
{
    public static let share = AppDelegateEXFunction()
    
    public var isFullScreen:Bool = false
    
    public func faceOrientationMask(app:UIApplication,windos:UIWindow)->UIInterfaceOrientationMask
    {
        if self.isFullScreen
        {
            if #available(iOS 16.0, *)
            {
                return .landscape
            }
            else
            {
                return .landscapeRight
            }
        }
        return .portrait
    }
}
