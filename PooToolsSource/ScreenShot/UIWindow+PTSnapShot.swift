//
//  UIWindow+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

extension UIWindow {

    // MARK: - SnapshotKitProtocol 实现 (覆盖 UIView 的默认实现)

    public func windowTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        // 对于 UIWindow 来说，可见内容通常就是它的全部边界内容
        return self.takeSnapshotOfFullContent(with: configuration)
    }

    public func windowTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        // 使用现代的渲染 API
        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        // 优先使用配置的透明度，结合底层性能判断
        format.opaque = configuration.isOpaque || (self.isOpaque && self.layer.cornerRadius == 0)

        let renderer = UIGraphicsImageRenderer(bounds: self.bounds, format: format)
        let backgroundColor = self.backgroundColor ?? UIColor.white

        let image = renderer.image { context in
            // 填充背景色
            backgroundColor.setFill()
            context.fill(self.bounds)

            // 【核心保留】使用 drawHierarchy 替代 layer.render
            // 能有效避免 UIWindow 中包含 WKWebView 或 UIVisualEffectView(毛玻璃) 时截取到空白区域的问题
            self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        }

        return image
    }

    public func windowAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((UIImage?) -> Void)) {
        // UIWindow 不需要像长列表那样在后台疯狂拼接图片。
        // 这里的异步延迟 (0.1s) 主要是为了让 RunLoop 跑完当前周期，
        // 确保屏幕上所有待处理的视图刷新、隐式动画、转场效果等彻底渲染完成后再截图。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let image = self.takeSnapshotOfFullContent(with: configuration)
            completion(image)
        }
    }
}
