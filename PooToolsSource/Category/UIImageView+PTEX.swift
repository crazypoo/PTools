//
//  UIImageView+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/4.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SDWebImage

public extension UIImageView {
    func getImagePointColor(point:CGPoint)->UIColor
    {
        let thumbSize = CGSize(width: self.image!.size.width, height: self.image!.size.height)

        // 当前点在图片中的相对位置
        let pInImage = CGPointMake(point.x * thumbSize.width / self.bounds.size.width,
                                   point.y * thumbSize.height / self.bounds.size.height)
        return self.image!.getImgePointColor(point: pInImage)
    }
    
    func pt_SDWebImage(imageString:String)
    {
        self.sd_setImage(with: URL.init(string: imageString), placeholderImage: PTAppBaseConfig.share.defaultPlaceholderImage, options: PTAppBaseConfig.share.gobalWebImageLoadOption(), context: nil)
    }
}
