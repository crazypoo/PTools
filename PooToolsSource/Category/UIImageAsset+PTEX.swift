//
//  UIImageAsset+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/2/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIImageAsset {
    /// 创建一个图像资产，并根据浅色和深色模式注册图像。
    /// - Parameters:
    ///   - lightModeImage: 在浅色模式下使用的图像。
    ///   - darkModeImage: 在深色模式下使用的图像。
    convenience init(lightModeImage: UIImage?, darkModeImage: UIImage?) {
        self.init()
        register(lightModeImage: lightModeImage, darkModeImage: darkModeImage)
    }

    /// 分别为浅色和深色模式注册图像。
    /// - Parameters:
    ///   - lightModeImage: 浅色模式下的图像。
    ///   - darkModeImage: 深色模式下的图像。
    func register(lightModeImage: UIImage?, darkModeImage: UIImage?) {
        register(lightModeImage, for: .light)
        register(darkModeImage, for: .dark)
    }

    /// 为指定的特征集合注册图像。
    /// - Parameters:
    ///   - image: 要注册的图像。
    ///   - traitCollection: 要与图像关联的特征集合。
    func register(_ image: UIImage?, for traitCollection: UITraitCollection) {
        guard let image = image else { return }
        register(image, with: traitCollection)
    }

    /// 返回最符合当前特征集合的图像。在早期 SDK 中会返回浅色模式的图像。
    func image() -> UIImage {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return image(with: .current)
        }
        return image(with: .light)
    }
}
