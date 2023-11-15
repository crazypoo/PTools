//
//  PTDevFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Kingfisher

@objcMembers
public class PTDevFunction: NSObject {
    public static let share = PTDevFunction()
    
    //MARK: SDWebImage的加载失误图片方式(全局控制)
    ///SDWebImage的加载失误图片方式(全局控制)
    public class func gobalWebImageLoadOption()->KingfisherOptionsInfo {
        #if DEBUG
        let devServer:Bool = PTCoreUserDefultsWrapper.WebImageOption
        if devServer {
            return [KingfisherOptionsInfoItem.cacheOriginalImage]
        } else {
            return [.lowDataModeSource,.memoryCacheExpiration(.seconds(60)).diskCacheExpiration(.seconds(20))]
        }
        #else
        return [KingfisherOptionsInfoItem.cacheOriginalImage]
        #endif
    }
}
