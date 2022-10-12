//
//  UIButton+BlockEX.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import SDWebImage

public typealias TouchedBlock = (_ sender:UIButton) -> Void

public extension UIButton
{
    static var UIButtonBlockKey = "UIButtonBlockKey"
    
    @objc func addActionHandlers(handler:@escaping TouchedBlock)
    {
        objc_setAssociatedObject(self, &UIButton.UIButtonBlockKey, handler, .OBJC_ASSOCIATION_COPY)
        self.addTarget(self, action: #selector(self.actionTouched(sender:)), for: .touchUpInside)
    }
    
    @objc func actionTouched(sender:UIButton)
    {
        let block:TouchedBlock = objc_getAssociatedObject(self, &UIButton.UIButtonBlockKey) as! TouchedBlock
        block(sender)
    }
    
    func timeRunWithTime(timeInterval:TimeInterval,originalTitle:String,canTap:Bool,timeFinish:(()->Void)?)
    {
        PTUtils.timeRunWithTime_base(customQueName:"ButtonFunction",timeInterval: timeInterval) { finish, time in
            if finish
            {
                self.setTitle(originalTitle, for: self.state)
                self.isUserInteractionEnabled = canTap
                if timeFinish != nil
                {
                    timeFinish!()
                }
            }
            else
            {
                let strTime = String.init(format: "%.2d", time)
                let buttonTime = String.init(format: "%@", strTime)
                self.setTitle(buttonTime, for: self.state)
                self.isUserInteractionEnabled = false
            }
        }
    }
    
    func pt_SDWebImage(imageString:String)
    {
        self.sd_setImage(with: URL.init(string: imageString), for: .normal, placeholderImage: PTAppBaseConfig.share.defaultPlaceholderImage,options: PTAppBaseConfig.share.gobalWebImageLoadOption())
    }
}
