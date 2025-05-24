//
//  PTLazyViewContainer.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/22/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

/// 延迟创建视图容器，只有在需要时才创建实际视图，避免不必要的内存开销
public final class PTLazyViewContainer<T: UIView> {
    
    private(set) var view: T?
    private let createView: () -> T
    private weak var parentView: UIView?

    /// 初始化
    /// - Parameter createView: 用于创建视图的闭包，默认为 `T()`。
    public init(createView: @escaping () -> T = { T() }) {
        self.createView = createView
    }

    /// 获取或创建视图，并添加到父视图中
    /// - Parameters:
    ///   - parent: 父视图
    ///   - configure: 视图创建后的配置闭包（如设置属性、布局等）
    ///   - customAdd: 自定义添加视图逻辑，默认使用 `parent.addSubview`
    ///   - onFirstAdd: 首次添加后的回调
    /// - Returns: 懒加载创建或已有的视图实例
    @discardableResult
    public func ensureView(in parent: UIView,
                           configure: ((T) -> Void)? = nil,
                           customAdd: ((T) -> Void)? = nil,
                           onFirstAdd: ((T) -> Void)? = nil) -> T {
        if let view = view {
            return view
        }

        let newView: T = Thread.isMainThread ? createView() : DispatchQueue.main.sync(execute: createView)

        configure?(newView)

        let addAction = {
            if let customAdd = customAdd {
                customAdd(newView)
            } else {
                parent.addSubview(newView)
            }
            onFirstAdd?(newView)
        }

        if Thread.isMainThread {
            addAction()
        } else {
            DispatchQueue.main.async { addAction() }
        }

        self.view = newView
        self.parentView = parent
        return newView
    }

    /// 移除并释放视图
    /// - Parameter customRemove: 自定义移除逻辑，默认调用 `removeFromSuperview`
    public func removeView(using customRemove: ((T) -> Void)? = nil) {
        guard let view = view, view.superview != nil else { return }

        let removeAction = {
            if let customRemove = customRemove {
                customRemove(view)
            } else {
                view.removeFromSuperview()
            }
            self.view = nil
            self.parentView = nil
        }

        if Thread.isMainThread {
            removeAction()
        } else {
            DispatchQueue.main.async { removeAction() }
        }
    }

    /// 是否已创建视图
    public var isCreated: Bool {
        return view != nil
    }

    deinit {
        removeView()
    }
}
