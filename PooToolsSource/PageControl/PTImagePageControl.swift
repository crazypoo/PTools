//
//  PTImagePageControl.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 22/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Foundation

@objcMembers
open class PTImagePageControl: UIPageControl {

    open var dotInActiveImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive")
    open var dotActiveImage: Any = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive")
    open var iCloudDocument:String = ""
    
    override open var numberOfPages: Int {
        didSet {
            updateDots()
        }
    }
    
    override open var currentPage: Int {
        didSet {
            updateDots()
        }
    }
    
    func updateDots() {
        var i = 0
        for view in subviews {
            var imageView = imageView(forSubview: view)
            if imageView == nil {
                if i == 0 {
                    imageView = UIImageView()
                    setImageViewImage(imageContent: dotInActiveImage, imageView: imageView!)
                } else {
                    imageView = UIImageView()
                    setImageViewImage(imageContent: dotActiveImage, imageView: imageView!)
                }
                imageView!.center = view.center
                imageView?.frame = CGRect.init(x: view.frame.origin.x, y: view.frame.origin.y+2, width: 8, height: 8)
                view.addSubview(imageView!)
                view.clipsToBounds = false
            }
            
            if i == currentPage {
                setImageViewImage(imageContent: dotInActiveImage, imageView: imageView!)
            } else {
                setImageViewImage(imageContent: dotActiveImage, imageView: imageView!)
            }
            i += 1
        }
    }
    
    fileprivate func imageView(forSubview view: UIView) -> UIImageView? {
        var dot: UIImageView?
        if let dotImageView = view as? UIImageView {
            dot = dotImageView
        } else {
            for foundView in view.subviews {
                if let imageView = foundView as? UIImageView {
                    dot = imageView
                    break
                }
            }
        }
        return dot
    }
    
    fileprivate func setImageViewImage(imageContent:Any,imageView:UIImageView) {
        imageView.loadImage(contentData: imageContent,iCloudDocumentName: iCloudDocument)
    }
}

