//
//  PTLazyViewContainer.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/22/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit

/// 延迟创建视图容器，只有在需要时才创建实际视图，避免不必要的内存开销
/// Swift 6 升级：通过 @MainActor 保证类的所有状态和方法都严格在主线程执行
@MainActor
public final class PTLazyViewContainer<T: UIView> {
    
    public private(set) var view: T?
    private let createView: @MainActor () -> T
    private weak var parentView: UIView?

    /// 初始化
    /// - Parameter createView: 用于创建视图的闭包，默认为 `T()`。
    public init(createView: @escaping @MainActor () -> T = { T() }) {
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
                           configure: (@MainActor (T) -> Void)? = nil,
                           customAdd: (@MainActor (T) -> Void)? = nil,
                           onFirstAdd: (@MainActor (T) -> Void)? = nil) -> T {
        
        // Swift 6 优化：因为类带有 @MainActor，编译器会保证此方法仅在主线程调用。
        // 因此彻底移除了 Thread.isMainThread 的判断和 DispatchQueue 的分发。
        
        // 如果视图已存在，但传入了新的 parent，支持自动迁移层级
        if let existingView = view {
            if existingView.superview != parent, customAdd == nil {
                parent.addSubview(existingView)
                self.parentView = parent
            }
            return existingView
        }

        // --- 以下为首次创建视图的逻辑 ---
        let newView = createView()
        
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
    public func removeView(using customRemove: (@MainActor (T) -> Void)? = nil) {
        // Swift 6 优化：同样交由 @MainActor 保证线程安全，代码更整洁
        guard let currentView = view else { return }
        
        if let customRemove = customRemove {
            customRemove(currentView)
        } else {
            currentView.removeFromSuperview()
        }
        
        self.view = nil
        self.parentView = nil
    }

    // MARK: - 补充缺失的实用功能

    /// 控制视图的显示/隐藏 (仅仅是视觉上隐藏，不销毁内存)
    public var isHidden: Bool {
        get { view?.isHidden ?? true }
        set { view?.isHidden = newValue }
    }

    /// 是否已创建视图
    public var isCreated: Bool {
        return view != nil
    }

    // MARK: - 生命周期

    deinit {
        // Swift 6 注意事项：deinit 默认是非隔离的（nonisolated）。
        // 当对象被销毁时，我们需要安全地将移除 UI 的操作派发回主线程。
        if let v = view {
            // 使用 Task 替代 DispatchQueue 是一种更符合 Swift 并发模型的现代写法
            Task { @MainActor [v] in
                v.removeFromSuperview()
            }
        }
    }
}
