//
//  UIApplication+EX.swift
//  Diou
//
//  Created by ken lam on 2021/10/18.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SwifterSwift

public extension UIApplication
{
    @objc func clearLaunchScreenCache() {
        do {
            try FileManager.default.removeItem(atPath: NSHomeDirectory()+"/Library/SplashBoard")
        } catch {
            PTLocalConsoleFunction.share.pNSLog("Failed to delete launch screen cache: \(error)")
        }
    }
    
    //MARK: 獲取軟件的開髮狀態
    ///獲取軟件的開髮狀態
    class func applicationEnvironment()->Environment
    {
        return UIApplication.shared.inferredEnvironment
    }
}
