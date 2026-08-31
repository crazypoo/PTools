//
//  UIView+PTSnapShot.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/11/2025.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import WebKit

extension UIView: SnapshotKitProtocol {
    
    // MARK: - SnapshotKitProtocol 实现
    
    public func takeSnapshotOfVisibleContent(with configuration: SnapshotConfiguration) -> UIImage? {
        if let window = self as? UIWindow {
            return window.pt_windowSnapshot(configuration: configuration)
        }
        if let webView = self as? WKWebView {
            return webView.pt_wkVisibleSnapshot(configuration: configuration)
        }
        if let tableView = self as? UITableView {
            return tableView.pt_tableVisibleSnapshot(configuration: configuration)
        }
        if let scrollView = self as? UIScrollView {
            return scrollView.pt_scrollVisibleSnapshot(configuration: configuration)
        }
        return PTSnapshotRenderer.image(view: self,
                                        rect: self.bounds,
                                        configuration: configuration)
    }
    
    public func takeSnapshotOfFullContent(with configuration: SnapshotConfiguration) -> UIImage? {
        if let window = self as? UIWindow {
            return window.pt_windowSnapshot(configuration: configuration)
        }
        if let webView = self as? WKWebView {
            return webView.pt_wkFullSnapshot(configuration: configuration)
        }
        if let tableView = self as? UITableView {
            return tableView.pt_tableFullSnapshot(configuration: configuration)
        }
        if let scrollView = self as? UIScrollView {
            return scrollView.pt_scrollFullSnapshot(configuration: configuration)
        }
        return PTSnapshotRenderer.image(view: self,
                                        rect: self.bounds,
                                        configuration: configuration)
    }

    public func asyncTakeSnapshotOfFullContent(with configuration: SnapshotConfiguration, completion: @escaping ((UIImage?) -> Void)) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else {
                completion(nil)
                return
            }
            completion(self.takeSnapshotOfFullContent(with: configuration))
        }
    }

    // MARK: - 核心功能：按指定区域进行截图 (供内部或其他子类调用)
    
    /// 按指定的 CGRect 截取视图内容
    /// - Parameters:
    ///   - croppingRect: 需要截取的区域 (相对于视图自身的坐标系)
    ///   - configuration: 截图配置
    /// - Returns: UIImage?
    public func takeSnapshotOfFullContent(for croppingRect: CGRect, with configuration: SnapshotConfiguration? = nil) -> UIImage? {
        PTSnapshotRenderer.image(view: self,
                                 rect: croppingRect,
                                 configuration: configuration ?? .default)
    }
}
