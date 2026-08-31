//
//  WKWebView+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import WebKit

@MainActor
extension WKWebView {
    
    // MARK: - SnapshotKitProtocol 实现
    
    internal func pt_wkVisibleSnapshot(configuration: SnapshotConfiguration) -> UIImage? {
        PTSnapshotRenderer.image(view: self,
                                 rect: bounds,
                                 configuration: configuration,
                                 usesHierarchy: true)
    }

    internal func pt_wkFullSnapshot(configuration: SnapshotConfiguration) -> UIImage? {
        let renderer = PTWebViewPrintPageRenderer(formatter: viewPrintFormatter(),
                                                   contentSize: scrollView.contentSize)
        return renderer.printContentToImage(with: configuration)
    }

    internal func pt_wkAsyncSnapshot(configuration: SnapshotConfiguration) async -> UIImage? {
        let originalOffset = scrollView.contentOffset
        defer {
            scrollView.setContentOffset(originalOffset, animated: false)
        }

        let viewportHeight = max(scrollView.bounds.height, 1)
        let pageCount = max(Int(ceil(max(scrollView.contentSize.height, viewportHeight) / viewportHeight)), 1)
        for page in 0..<pageCount {
            guard !Task.isCancelled else { return nil }
            scrollView.setContentOffset(CGPoint(x: originalOffset.x,
                                                y: CGFloat(page) * viewportHeight),
                                        animated: false)
            do {
                try await Task.sleep(nanoseconds: 100_000_000)
            } catch {
                return nil
            }
        }

        guard !Task.isCancelled else { return nil }
        return pt_wkFullSnapshot(configuration: configuration)
    }

    // MARK: - Compatibility entry points / Entradas de compatibilidad / 兼容入口

    public func wkTakeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        pt_wkVisibleSnapshot(configuration: configuration)
    }

    public func wkTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        pt_wkFullSnapshot(configuration: configuration)
    }

    public func wkAsyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration,
                                                  completion: @escaping @Sendable (UIImage?) -> Void) {
        Task { @MainActor [weak self] in
            guard let self else {
                completion(nil)
                return
            }
            let image = await self.pt_wkAsyncSnapshot(configuration: configuration)
            guard !Task.isCancelled else { return }
            completion(image)
        }
    }
}
