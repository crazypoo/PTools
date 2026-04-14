//
//  File.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation
import UIKit

/// 截图配置选项，用于未来扩展（例如控制分辨率、背景透明度等）
public struct SnapshotConfiguration {
    /// 屏幕缩放比例，0 表示设备主屏幕的缩放比例 (UIScreen.main.scale)
    public var scale: CGFloat
    /// 截图是否不透明（设置为 true 有助于提高性能，但如果 view 有透明区域会变成黑色）
    public var isOpaque: Bool
    
    public init(scale: CGFloat = 0.0, isOpaque: Bool = false) {
        self.scale = scale
        self.isOpaque = isOpaque
    }
    
    /// 提供一个默认的配置
    public static let `default` = SnapshotConfiguration()
}

public protocol SnapshotKitProtocol {

    /// 同步截取视图当前可见区域的内容
    /// - Parameter configuration: 截图的配置项
    /// - Returns: 截取到的图像 UIImage?
    func takeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage?

    /// 同步截取视图的完整内容
    /// - Important: 仅当视图内容较小（如普通的 UIView）时使用，避免内存峰值和主线程卡顿
    /// - Parameter configuration: 截图的配置项
    /// - Returns: 截取到的图像 UIImage?
    func takeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage?

    /// 【推荐】异步截取视图的完整内容 (闭包回调版本，兼容旧版项目)
    /// - Important: 适用于 UIScrollView/WKWebView 等长图截取，防止卡死 UI
    /// - Parameters:
    ///   - configuration: 截图的配置项
    ///   - completion: 截图完成后的主线程回调
    func asyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((_ image: UIImage?) -> Void))
    
    /// 【现代 Swift 推荐】异步截取视图的完整内容 (async/await 版本)
    /// - Important: 适用于 iOS 13.0+，使用现代并发模型，避免回调嵌套
    /// - Parameter configuration: 截图的配置项
    /// - Returns: 截取到的图像 UIImage?
    @available(iOS 13.0, *)
    func takeSnapshotOfFullContent(with configuration: SnapshotConfiguration) async -> UIImage?
}

// MARK: - 协议默认实现 (确保向后兼容和易用性)
public extension SnapshotKitProtocol {
    
    // 提供无参数调用的默认实现，默认使用 .default 配置
    func takeSnapshotOfVisibleContent() -> UIImage? {
        return takeSnapshotOfVisibleContent(with: .default)
    }
    
    func takeSnapshotOfFullContent() -> UIImage? {
        return takeSnapshotOfFullContent(with: .default)
    }
    
    func asyncTakeSnapshotOfFullContent(_ completion: @escaping ((_ image: UIImage?) -> Void)) {
        asyncTakeSnapshotOfFullContent(with: .default, completion: completion)
    }
    
    // 提供 async/await 版本的默认实现，如果实现类没有写这个方法，系统会自动用闭包版本封装一个
    @available(iOS 13.0, *)
    func takeSnapshotOfFullContent(with configuration: SnapshotConfiguration = .default) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            self.asyncTakeSnapshotOfFullContent(with: configuration) { image in
                continuation.resume(returning: image)
            }
        }
    }
}
