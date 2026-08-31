//
//  UIScrollView+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

@MainActor
extension UIScrollView {

    // MARK: - SnapshotKitProtocol 实现 (覆盖 UIView 的默认实现)

    internal func pt_scrollVisibleSnapshot(configuration: SnapshotConfiguration) -> UIImage? {
        PTSnapshotRenderer.image(view: self,
                                 rect: bounds,
                                 configuration: configuration)
    }

    internal func pt_scrollFullSnapshot(configuration: SnapshotConfiguration) -> UIImage? {
        let contentWidth = max(contentSize.width, bounds.width)
        let contentHeight = max(contentSize.height, bounds.height)
        let totalSize = CGSize(width: contentWidth, height: contentHeight)
        let scale = PTSnapshotRenderer.scale(for: self, configuration: configuration)
        guard let renderSize = PTSnapshotRenderer.renderSize(totalSize,
                                                             scale: scale,
                                                             configuration: configuration) else {
            return nil
        }

        let originalOffset = contentOffset
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = configuration.isOpaque
        let renderer = UIGraphicsImageRenderer(size: renderSize, format: format)

        defer {
            setContentOffset(originalOffset, animated: false)
        }

        return renderer.image { context in
            if configuration.isOpaque {
                (backgroundColor ?? UIColor.systemBackground).setFill()
                context.fill(CGRect(origin: .zero, size: renderSize))
            }

            let pageWidth = max(bounds.width, 1)
            let pageHeight = max(bounds.height, 1)
            let horizontalPages = max(Int(ceil(contentWidth / pageWidth)), 1)
            let verticalPages = max(Int(ceil(contentHeight / pageHeight)), 1)

            // English: Render each viewport into its final position without changing the view hierarchy.
            // Español: Renderiza cada ventana en su posición final sin cambiar la jerarquía de vistas.
            // 中文：将每个可视窗口渲染到最终位置，不修改视图层级。
            UIView.performWithoutAnimation {
                for row in 0..<verticalPages {
                    for column in 0..<horizontalPages {
                        guard !Task.isCancelled else { return }

                        let origin = CGPoint(x: CGFloat(column) * pageWidth,
                                             y: CGFloat(row) * pageHeight)
                        setContentOffset(origin, animated: false)
                        layoutIfNeeded()

                        let tileWidth = min(pageWidth, contentWidth - origin.x)
                        let tileHeight = min(pageHeight, contentHeight - origin.y)
                        guard tileWidth > 0, tileHeight > 0 else { continue }

                        context.cgContext.saveGState()
                        context.cgContext.translateBy(x: origin.x, y: origin.y)
                        context.cgContext.addRect(CGRect(x: 0,
                                                         y: 0,
                                                         width: tileWidth,
                                                         height: tileHeight))
                        context.cgContext.clip()
                        drawHierarchy(in: bounds, afterScreenUpdates: true)
                        context.cgContext.restoreGState()
                    }
                }
            }
        }
    }

    internal func pt_scrollAsyncSnapshot(configuration: SnapshotConfiguration) async -> UIImage? {
        guard !Task.isCancelled else { return nil }
        await Task.yield()
        guard !Task.isCancelled else { return nil }
        return pt_scrollFullSnapshot(configuration: configuration)
    }

    // MARK: - Compatibility entry points / Entradas de compatibilidad / 兼容入口

    public func scrollTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        pt_scrollVisibleSnapshot(configuration: configuration)
    }

    public func scrollTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        pt_scrollFullSnapshot(configuration: configuration)
    }

    public func scrollAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration,
                                                      completion: @escaping @Sendable (UIImage?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else {
                completion(nil)
                return
            }
            let image = await self.pt_scrollAsyncSnapshot(configuration: configuration)
            guard !Task.isCancelled else { return }
            completion(image)
        }
    }
}
