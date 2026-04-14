//
//  UIView+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

extension UIView:SnapshotKitProtocol {
    
    // MARK: - SnapshotKitProtocol 实现
    
    public func takeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        return self.takeSnapshotOfFullContent(for: self.bounds, with: configuration)
    }
    
    public func takeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        return self.takeSnapshotOfFullContent(for: self.bounds, with: configuration)
    }

    public func asyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((UIImage?) -> Void)) {
        // 对于普通 UIView，内容通常不会像长列表那样庞大。
        // 延迟 0.1 秒确保所有隐式动画或布局约束更新完毕后，再进行截图
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let image = self.takeSnapshotOfFullContent(with: configuration)
            completion(image)
        }
    }

    // MARK: - 核心功能：按指定区域进行截图 (供内部或其他子类调用)
    
    /// 按指定的 CGRect 截取视图内容
    /// - Parameters:
    ///   - croppingRect: 需要截取的区域 (相对于视图自身的坐标系)
    ///   - configuration: 截图配置
    /// - Returns: UIImage?
    public func takeSnapshotOfFullContent(for croppingRect: CGRect, with configuration: SnapshotConfiguration = .default) -> UIImage? {
        
        // 使用 floor 防止 Double 精度问题导致的 1px 黑线或白边
        let contentSize = CGSize(width: floor(croppingRect.size.width), height: floor(croppingRect.size.height))
        
        // 安全校验：如果截取区域为 0，直接返回 nil
        guard contentSize.width > 0 && contentSize.height > 0 else { return nil }

        var backgroundColor = self.backgroundColor ?? UIColor.white
        
        // 性能优化：若 View 为非透明且无圆角，则创建非透明的画布，渲染速度更快
        let opaqueCanvas = (self.isOpaque && self.layer.cornerRadius == 0)
        if !opaqueCanvas {
            backgroundColor = UIColor.white
        }

        // 配置现代的渲染格式
        let format = UIGraphicsImageRendererFormat()
        format.scale = configuration.scale
        // 优先使用内部判断的 opaqueCanvas，如果用户配置强制要求，也可以结合使用
        format.opaque = opaqueCanvas || configuration.isOpaque

        let renderer = UIGraphicsImageRenderer(size: contentSize, format: format)

        // 开始渲染
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            cgContext.saveGState()
            
            // 填充背景色
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: contentSize))
            
            // 将画笔上下文移动到目标区域，这样渲染 layer 时只会捕获需要的局部
            cgContext.translateBy(x: -croppingRect.origin.x, y: -croppingRect.origin.y)
            
            // 渲染视图的 layer
            self.layer.render(in: cgContext)
            
            cgContext.restoreGState()
        }

        return image
    }
}
