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
    
    class func appScheme()->[String]
    {
        let bundleURL = Bundle.main.bundleURL
        let plistPath = bundleURL.appendingPathComponent("Info.plist")
        if let plistData = try? Data(contentsOf: plistPath),let plist = try? PropertyListSerialization.propertyList(from:plistData,options: [],format: nil) as? [String:Any] {
            if let scheme = plist["CFBundleURLTypes"] as? [[String:Any]]
            {
                var schemeArr = [String]()
                scheme.enumerated().forEach { index,value in
                    if let schemes = value["CFBundleURLSchemes"] as? [String]
                    {
                        schemes.enumerated().forEach { index,value in
                            schemeArr.append(value)
                        }
                    }
                }
                return schemeArr
            }
        }
        return []
    }
}
