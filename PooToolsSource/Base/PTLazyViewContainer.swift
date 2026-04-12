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
    
    public private(set) var view: T?
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
        // 1. 修复：确保所有 UI 创建和操作严格在主线程进行
        guard Thread.isMainThread else {
            var createdView: T!
            // 同步切回主线程执行，防止多线程同时调用时创建多个 View (竞争条件)
            DispatchQueue.main.sync {
                createdView = ensureView(in: parent, configure: configure, customAdd: customAdd, onFirstAdd: onFirstAdd)
            }
            return createdView
        }

        // 2. 补充：如果视图已存在，但传入了新的 parent，支持自动迁移层级
        if let existingView = view {
            if existingView.superview != parent, customAdd == nil {
                parent.addSubview(existingView)
                self.parentView = parent
            }
            return existingView
        }

        // --- 以下为首次创建视图的逻辑 ---
        let newView = createView()
        
        // 3. 修复：configure 现在被保证在主线程执行（原版若在后台线程触发会 Crash）
        configure?(newView)

        if let customAdd = customAdd {
            customAdd(newView)
        } else {
            parent.addSubview(newView)
        }
        
        onFirstAdd?(newView)

        self.view = newView
        self.parentView = parent
        
        return newView
    }

    /// 移除并释放视图内存
    /// - Parameter customRemove: 自定义移除逻辑，默认调用 `removeFromSuperview`
    public func removeView(using customRemove: ((T) -> Void)? = nil) {
        // 确保 UI 移除操作在主线程
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.removeView(using: customRemove)
            }
            return
        }
        
        guard let view = view else { return } // 移除了 view.superview != nil 判断，确保即使遇到动画使视图短暂脱离视图树，也能被彻底清理
        
        if let customRemove = customRemove {
            customRemove(view)
        } else {
            view.removeFromSuperview()
        }
        
        self.view = nil
        self.parentView = nil
    }

    // MARK: - 补充缺失的实用功能

    /// 控制视图的显示/隐藏 (仅仅是视觉上隐藏，不销毁内存)
    public var isHidden: Bool {
        get { view?.isHidden ?? true }
        set {
            if Thread.isMainThread {
                view?.isHidden = newValue
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.view?.isHidden = newValue
                }
            }
        }
    }

    /// 是否已创建视图
    public var isCreated: Bool {
        return view != nil
    }

    // MARK: - 生命周期

    deinit {
        // 4. 修复致命崩溃：绝对不要在 deinit 中使用异步闭包隐式捕获 self
        if let v = view {
            // 只捕获视图局部变量 v，而不是 self
            DispatchQueue.main.async {
                v.removeFromSuperview()
            }
        }
    }
}
