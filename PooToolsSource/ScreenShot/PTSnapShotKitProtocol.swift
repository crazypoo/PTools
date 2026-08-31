//
//  File.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import Foundation
import UIKit

/// English: Snapshot options for resolution, opacity, and safe bitmap size.
/// Español: Opciones de captura para la resolución, la opacidad y el tamaño seguro del bitmap.
/// 中文：截图配置选项，用于控制分辨率、透明度和安全的位图大小。
public struct SnapshotConfiguration: Sendable {
    /// English: Screen scale; zero uses the scale of the current scene.
    /// Español: Escala de pantalla; cero usa la escala de la escena actual.
    /// 中文：屏幕缩放比例，0 表示当前场景屏幕的缩放比例。
    public var scale: CGFloat
    /// 截图是否不透明（设置为 true 有助于提高性能，但如果 view 有透明区域会变成黑色）
    public var isOpaque: Bool

    // English: Stop oversized snapshots before Core Graphics allocates an unsafe bitmap.
    // Español: Detiene las capturas demasiado grandes antes de asignar un bitmap inseguro en Core Graphics.
    // 中文：在 Core Graphics 分配高风险位图之前拦截过大的截图。
    public var maximumPixelCount: Int
    
    public init(scale: CGFloat = 0.0,
                isOpaque: Bool = false,
                maximumPixelCount: Int = 20_000_000) {
        self.scale = scale
        self.isOpaque = isOpaque
        self.maximumPixelCount = maximumPixelCount
    }
    
    /// 提供一个默认的配置
    public static let `default` = SnapshotConfiguration()
}

@MainActor
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
    @MainActor func takeSnapshotOfVisibleContent() -> UIImage? {
        return takeSnapshotOfVisibleContent(with: .default)
    }
    
    @MainActor func takeSnapshotOfFullContent() -> UIImage? {
        return takeSnapshotOfFullContent(with: .default)
    }
    
    @MainActor func asyncTakeSnapshotOfFullContent(_ completion: @escaping ((_ image: UIImage?) -> Void)) {
        asyncTakeSnapshotOfFullContent(with: .default, completion: completion)
    }
    
    // 提供 async/await 版本的默认实现，如果实现类没有写这个方法，系统会自动用闭包版本封装一个
    @MainActor 
    @available(iOS 13.0, *)
    func takeSnapshotOfFullContent(with configuration: SnapshotConfiguration? = nil) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            self.asyncTakeSnapshotOfFullContent(with: configuration ?? .default) { image in
                continuation.resume(returning: image)
            }
        }
    }
}

// English: Keep validation and renderer setup in one MainActor-owned implementation.
// Español: Mantén la validación y la configuración del renderizador en una implementación única del MainActor.
// 中文：将校验和渲染器配置集中到一个由 MainActor 管理的实现中。
@MainActor
internal enum PTSnapshotRenderer {
    static func scale(for view: UIView, configuration: SnapshotConfiguration) -> CGFloat {
        let requestedScale = configuration.scale
        guard requestedScale.isFinite, requestedScale > 0 else {
            let sceneScale = view.window?.windowScene?.screen.scale
                ?? PTSceneContext.activeWindow()?.windowScene?.screen.scale
                ?? view.traitCollection.displayScale
            return max(sceneScale, 1)
        }
        return requestedScale
    }

    static func renderSize(_ size: CGSize,
                           scale: CGFloat,
                           configuration: SnapshotConfiguration) -> CGSize? {
        let width = floor(size.width)
        let height = floor(size.height)
        guard width > 0, height > 0, width.isFinite, height.isFinite,
              scale.isFinite, scale > 0 else {
            return nil
        }

        let maximumPixelCount = max(configuration.maximumPixelCount, 1)
        let pixelCount = width * scale * height * scale
        guard pixelCount.isFinite, pixelCount <= CGFloat(maximumPixelCount) else {
            return nil
        }
        return CGSize(width: width, height: height)
    }

    static func image(view: UIView,
                      rect: CGRect,
                      configuration: SnapshotConfiguration,
                      usesHierarchy: Bool = false) -> UIImage? {
        let scale = scale(for: view, configuration: configuration)
        guard let size = renderSize(rect.size, scale: scale, configuration: configuration) else {
            return nil
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = configuration.isOpaque
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            if configuration.isOpaque {
                (view.backgroundColor ?? UIColor.systemBackground).setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }

            context.cgContext.saveGState()
            context.cgContext.translateBy(x: -rect.origin.x, y: -rect.origin.y)
            if usesHierarchy {
                view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            } else {
                view.layer.render(in: context.cgContext)
            }
            context.cgContext.restoreGState()
        }
    }
}
