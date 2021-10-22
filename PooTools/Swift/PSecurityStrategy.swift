//
//  PSecurityStrategy.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

let effectTag = 19999

class PSecurityStrategy: NSObject {
    
    class open func addBlurEffect()
    {
        PTUtils.gcdMain {
            let imageView = UIImageView.init(frame: UIScreen.main.bounds)
            imageView.tag = effectTag
            imageView.image = PSecurityStrategy.screenShot()
            UIApplication.shared.keyWindow?.addSubview(imageView)
            
            let blueView = UIView.init(frame: imageView.frame)
            imageView.addSubview(blueView)
            let aaaa = SSBlurView.init(to: blueView)
            aaaa.style = .extraLight
            aaaa.alpha = 1
            aaaa.enable()
        }
    }
    
    class open func removeBlurEffect()
    {
        let subViews = UIApplication.shared.keyWindow?.subviews
        subViews!.enumerated().forEach { (index,value) in
            if value is UIImageView
            {
                if (value as! UIImageView).tag == effectTag
                {
                    UIView.animate(withDuration: 0.2) {
                        (value as! UIImageView).alpha = 0
                        (value as! UIImageView).removeFromSuperview()
                    }
                }
            }
        }
    }
    
    class open func blurImage()->UIImage
    {
        let image = PSecurityStrategy.screenShot().blurImage()
        return image
    }
    
    class open func screenShot()->UIImage
    {
        UIGraphicsBeginImageContextWithOptions(CGSize.init(width: kSCREEN_WIDTH * UIScreen.main.scale, height: kSCREEN_HEIGHT * UIScreen.main.scale), true, 0)
        UIApplication.shared.keyWindow?.layer.render(in: UIGraphicsGetCurrentContext()!)
        let viewImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageRef = viewImage?.cgImage
        let rect = CGRect.init(x: 0, y: 0, width: kSCREEN_WIDTH * UIScreen.main.scale, height: kSCREEN_HEIGHT * UIScreen.main.scale)
        let imageRefRect = imageRef!.cropping(to: rect)
        let sendImage = UIImage.init(cgImage: imageRefRect!)
        return sendImage
    }
}
