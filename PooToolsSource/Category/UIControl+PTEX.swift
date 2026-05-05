//
//  Extensions.swift
//
//  Created by Duraid Abdul.
//  Copyright © 2021 Duraid Abdul. All rights reserved.
//

import UIKit

// 1. 创建一个私有的闭包包装器
private class UIControlClosureWrapper: NSObject {
    let closure: (Any) -> Void
    
    init(_ closure: @escaping (Any) -> Void) {
        self.closure = closure
        super.init()
    }
    
    @objc func invoke(_ sender: Any) {
        closure(sender)
    }
}

// 2. 为 UIControl 添加扩展
public extension UIControl {
    
    private struct AssociatedKeys {
        static var controlActionWrappersKey: UInt8 = 0
        static var clickIntervalKey: UInt8 = 0
        static var isIgnoreEventKey: UInt8 = 0
    }
    
    // MARK: - 属性扩展：防抖时间间隔
    
    /// 点击事件的防抖间隔时间（秒）。默认是 0（不防抖）
    var clickInterval: TimeInterval {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.clickIntervalKey) as? TimeInterval ?? 0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.clickIntervalKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 内部使用的标志位，判断当前是否应该忽略事件
    private var isIgnoreEvent: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isIgnoreEventKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isIgnoreEventKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - 核心方法
    
    /// 统一的添加事件闭包方法
    /// - Parameters:
    ///   - event: 触发的事件类型，例如 .touchUpInside
    ///   - handler: 触发后的回调闭包
    func addActionHandler<T: UIControl>(for event: UIControl.Event, handler: @escaping (_ sender: T) -> Void) {
        
        var wrappers = objc_getAssociatedObject(self, &AssociatedKeys.controlActionWrappersKey) as? [UInt: UIControlClosureWrapper] ?? [:]
        
        // 【修复 1】：清理旧的 Target，防止内存泄漏和逻辑错误
        if let oldWrapper = wrappers[event.rawValue] {
            self.removeTarget(oldWrapper, action: #selector(UIControlClosureWrapper.invoke(_:)), for: event)
        }
        
        // 创建新的包装器
        let wrapper = UIControlClosureWrapper { [weak self] sender in
            guard let self = self else { return }
            
            // 【修复 2】：防抖拦截逻辑
            if self.clickInterval > 0 {
                if self.isIgnoreEvent {
                    return // 还在冷却时间内，直接忽略本次点击
                }
                
                self.isIgnoreEvent = true
                
                // 延迟重置标志位
                DispatchQueue.main.asyncAfter(deadline: .now() + self.clickInterval) { [weak self] in
                    self?.isIgnoreEvent = false
                }
            }
            
            // 将 sender 安全地转换为泛型 T 并执行回调
            if let typedSender = sender as? T {
                handler(typedSender)
            }
        }
        
        // 更新字典并重新绑定
        wrappers[event.rawValue] = wrapper
        objc_setAssociatedObject(self, &AssociatedKeys.controlActionWrappersKey, wrappers, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        addTarget(wrapper, action: #selector(UIControlClosureWrapper.invoke(_:)), for: event)
    }
}

public extension UIControl {
    func addActions(highlightAction: UIAction,
                    unhighlightAction: UIAction) {
        addAction(highlightAction, for: .touchDown)
        addAction(highlightAction, for: .touchDragEnter)
        addAction(unhighlightAction, for: .touchUpInside)
        addAction(unhighlightAction, for: .touchDragExit)
        addAction(unhighlightAction, for: .touchCancel)
    }
    
    private struct Container {
        static var expandClickEdgeInsets: Void?
    }

    /// 扩大点击区域
    var expandClickEdgeInsets: UIEdgeInsets? {
        get {
            objc_getAssociatedObject(self, &Container.expandClickEdgeInsets) as? UIEdgeInsets ?? .zero
        }
        set {
            objc_setAssociatedObject(self, &Container.expandClickEdgeInsets, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let insets = expandClickEdgeInsets else {
            return super.point(inside: point, with: event)
        }
        let hitFrame = bounds.inset(by: insets.inverted) // 注意是反向扩大
        return hitFrame.contains(point)
    }
}

private extension UIEdgeInsets {
    var inverted: UIEdgeInsets {
        return UIEdgeInsets(top: -top, left: -left, bottom: -bottom, right: -right)
    }
}
