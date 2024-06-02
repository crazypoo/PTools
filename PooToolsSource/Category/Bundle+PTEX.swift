//
//  Bundle+PTEX.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/14.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

public extension Bundle {
    
    class func podBundleImage(bundleName:String,
                               imageName:String) -> UIImage {
        let bundle = PTUtils.cgBaseBundle()
        let resourcePath = bundle.path(forResource: bundleName, ofType: "bundle")
        let resourceBundle = Bundle.init(path: resourcePath ?? Bundle.main.bundlePath)
        let image = UIImage(named: imageName, in: resourceBundle, compatibleWith: nil)
        return image ?? UIImage()
    }

    class func podBundleResource(bundleName:String,
                                 sourceName:String,
                                 type:String) -> String? {
        let bundle = Bundle.main
        let resourcePath = bundle.path(forResource: bundleName, ofType: "bundle")
        let resourceBundle = Bundle.init(path: resourcePath ?? "") ?? bundle
        let filePath = resourceBundle.path(forResource: sourceName, ofType: type)
        return filePath
    }

    class func bundleResource(bundle:String,resourceName:String,type:String) -> String? {
        let bundlePath = Bundle.init(path: PTUtils.cgBaseBundle().path(forResource: bundle, ofType: "bundle")!)
        let filePath = bundlePath?.path(forResource: resourceName, ofType: type)
        return filePath
    }
    
    class func podCoreBundle() -> Bundle? {
        Bundle.podBundle(bundleName: CorePodBundleName)
    }
    
    class func podBundle(bundleName:String) -> Bundle? {
        Bundle.init(path: PTUtils.cgBaseBundle().path(forResource: bundleName, ofType: "bundle") ?? Bundle.main.bundlePath)
    }
    
    class func appScheme()->[String] {
        let bundleURL = Bundle.main.bundleURL
        let plistPath = bundleURL.appendingPathComponent("Info.plist")
        if let plistData = try? Data(contentsOf: plistPath),let plist = try? PropertyListSerialization.propertyList(from:plistData,options: [],format: nil) as? [String:Any] {
            if let scheme = plist["CFBundleURLTypes"] as? [[String:Any]] {
                var schemeArr = [String]()
                scheme.enumerated().forEach { index,value in
                    if let schemes = value["CFBundleURLSchemes"] as? [String] {
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
    
    // MARK: 读取项目本地文件数据
    /// 读取项目本地文件数据
    /// - Parameters:
    ///   - fileName: 文件名字
    ///   - type: 资源类型
    /// - Returns: 返回对应URL
    static func readLocalData(_ fileName: String, _ type: String) -> URL? {
        guard let path = Bundle.main.path(forResource: fileName, ofType: type) else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
}
