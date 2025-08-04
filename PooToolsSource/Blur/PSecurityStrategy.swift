//
//  PSecurityStrategy.swift
//  Diou
//
//  Created by ken lam on 2021/10/9.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

public let effectTag = 19999

@objcMembers
public class PSecurityStrategy: NSObject {
    
    class public func addBlurEffect() {
        PTGCDManager.gcdMain {
            let imageView = UIImageView(frame: UIScreen.main.bounds)
            imageView.tag = effectTag
            imageView.image = PSecurityStrategy.screenShot()
            AppWindows!.addSubview(imageView)
            
            let blueView = UIView(frame: imageView.frame)
            imageView.addSubview(blueView)
            let aaaa = SSBlurView(to: blueView)
            aaaa.style = .extraLight
            aaaa.alpha = 1
            aaaa.enable()
        }
    }
    
    class public func removeBlurEffect() {
        let subViews = AppWindows!.subviews
        subViews.forEach { value in
            if let newValue = value as? UIImageView,newValue.tag == effectTag {
                UIView.animate(withDuration: 0.2) {
                    newValue.alpha = 0
                    newValue.removeFromSuperview()
                }
            }
        }
    }
    
    class public func blurImage() -> UIImage {
        let image = PSecurityStrategy.screenShot().blurImage()
        return image
    }
    
    class public func screenShot() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: CGFloat.kSCREEN_WIDTH * UIScreen.main.scale, height: CGFloat.kSCREEN_HEIGHT * UIScreen.main.scale), true, 0)
        AppWindows!.layer.render(in: UIGraphicsGetCurrentContext()!)
        let viewImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageRef = viewImage?.cgImage
        let rect = CGRect(x: 0, y: 0, width: CGFloat.kSCREEN_WIDTH * UIScreen.main.scale, height: CGFloat.kSCREEN_HEIGHT * UIScreen.main.scale)
        let imageRefRect = imageRef!.cropping(to: rect)
        let sendImage = UIImage(cgImage: imageRefRect!)
        return sendImage
    }
}
