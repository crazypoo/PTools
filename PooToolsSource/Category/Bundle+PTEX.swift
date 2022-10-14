//
//  Bundle+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension Bundle
{
    class func imageWithName(imageName:String)->UIImage
    {
        let bundlePath = Bundle.init(path: PTUtils.cgBaseBundle().path(forResource: "PooTools", ofType: "bundle")!)
        let filePath = bundlePath?.path(forResource: imageName, ofType: "png")
        let image = UIImage(contentsOfFile: filePath!)
        return image!
    }
}
