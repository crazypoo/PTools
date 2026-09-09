//
//  PTDevFunction.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Kingfisher

@MainActor
@objcMembers
public class PTDevFunction: NSObject {
    public static let share = PTDevFunction()
    
    // English: Return the shared Kingfisher options for web-image loading.
    // Español: Devuelve las opciones compartidas de Kingfisher para cargar imágenes web.
    // 中文：返回网络图片加载共用的 Kingfisher 配置。
    public class func webImageLoadOptions() -> KingfisherOptionsInfo {
//        #if DEBUG
//        let devServer:Bool = PTCoreUserDefultsWrapper.shared.WebImageOption
//        if devServer {
//            return [KingfisherOptionsInfoItem.cacheOriginalImage]
//        } else {
//            return [.lowDataModeSource,.memoryCacheExpiration(.seconds(60)).diskCacheExpiration(.seconds(20))]
//        }
//        #else
        return [KingfisherOptionsInfoItem.cacheOriginalImage]
//        #endif
    }

    @available(*, deprecated, message: "Use webImageLoadOptions() instead")
    public class func gobalWebImageLoadOption() -> KingfisherOptionsInfo {
        webImageLoadOptions()
    }
}
