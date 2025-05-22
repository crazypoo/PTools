//
//  PTLazyViewContainer.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/22/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

/// 将创建自定义UIView逻辑延迟到数据到来时，同时避免当数据无效时仍创建自定义UIView，导致无意义的内存占用问题
public final class PTLazyViewContainer<T : UIView> {
    private(set) var view: T?
    private let createView: () -> T
    private weak var parentView: UIView?

    public init(createView: @escaping () -> T) {
        self.createView = createView
    }

    public init() {
        createView = { T() }
    }

    /// 获取或创建视图，交给调用方处理布局
    /// - Parameters:
    ///   - parent: 父视图
    ///   - customAddition: 自定义添加视图逻辑
    ///   - onFirstAddition: 首次创建、同时添加到parentView的时机
    /// - Returns: 自定义视图
    @discardableResult
    public func ensureView(in parent: UIView, customAddition: ((T) -> Void)? = nil, onFirstAddition: ((T) -> Void)? = nil) -> T {
        if let existingView = view {
            return existingView
        }

        let newView = Thread.isMainThread ? createView() : DispatchQueue.main.sync { createView() }

        // 使用自定义添加方式或默认 addSubview
        if let customAddition {
            customAddition(newView)
        } else {
            parent.addSubview(newView)
        }

        onFirstAddition?(newView)
        view = newView
        parentView = parent
        return newView
    }

    /// 移除视图
    /// - Parameter customRemoval: 自定义移除视图逻辑
    public func removeView(using customRemoval: ((T) -> Void)? = nil) {
        guard let view = view, view.superview != nil else { return }
        func doRemoving() {
            if let customRemoval {
                customRemoval(view)
            } else {
                view.removeFromSuperview()
            }
        }
        if Thread.isMainThread {
            doRemoving()
        } else {
            DispatchQueue.main.async { doRemoving() }
        }
        self.view = nil
        parentView = nil
    }

    // 检查视图是否创建
    public var isCreated: Bool {
        view != nil
    }

    deinit {
        removeView()
    }
}
