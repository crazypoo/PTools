//
//  Extensions.swift
//
//  Created by Duraid Abdul.
//  Copyright © 2021 Duraid Abdul. All rights reserved.
//

import UIKit

// 1. 创建一个私有的闭包包装器
private class UIControlClosureWrapper: NSObject {
    // 【关键修改 1】：直接接收 UIControl 而不是 Any。
    // 避免 UIKit 在 Objective-C 层面传递 id 时，Swift 桥接 Any 产生的运行时类型不稳定。
    let closure: (UIControl) -> Void
    
    init(_ closure: @escaping (UIControl) -> Void) {
        self.closure = closure
        super.init()
    }
    
    @objc func invoke(_ sender: UIControl) {
        closure(sender)
    }
}

// 2. 为 UIControl 添加扩展
public extension UIControl {
    
    private struct AssociatedKeys {
        // 使用 Void? 作为 Key 的地址，这是 Swift 中最高效、安全的关联对象 Key 写法
        static var wrappersKey: Void?
        static var clickIntervalKey: Void?
        static var isIgnoreEventKey: Void?
    }
    
    // MARK: - 属性扩展：防抖时间间隔
    
    var clickInterval: TimeInterval {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.clickIntervalKey) as? TimeInterval ?? 0
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.clickIntervalKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var isIgnoreEvent: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isIgnoreEventKey) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.isIgnoreEventKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - 核心方法（保留泛型 T）
    
    /// 统一的添加事件闭包方法
    /// - Parameters:
    ///   - event: 触发的事件类型
    ///   - handler: 触发后的回调闭包，泛型 T 保证了外部可以直接拿到具体类型（如 UIButton）
    func addActionHandler<T: UIControl>(for event: UIControl.Event, handler: @escaping (_ sender: T) -> Void) {
        
        // 【关键修改 2】：使用 NSMutableDictionary 替代 Swift 字典 [UInt: Wrapper]。
        // 彻底解决关联对象在读取/写入 Swift Struct 时因为桥接失败导致的 SIGABRT 闪退。
        let wrappers = objc_getAssociatedObject(self, &AssociatedKeys.wrappersKey) as? NSMutableDictionary ?? NSMutableDictionary()
        let eventKey = NSNumber(value: event.rawValue)
        
        // 清理旧的 Target
        if let oldWrapper = wrappers[eventKey] as? UIControlClosureWrapper {
            self.removeTarget(oldWrapper, action: #selector(UIControlClosureWrapper.invoke(_:)), for: event)
        }
        
        // 创建新的包装器
        let wrapper = UIControlClosureWrapper { [weak self] sender in
            guard let self = self else { return }
            
            // 防抖逻辑
            if self.clickInterval > 0 {
                if self.isIgnoreEvent { return }
                self.isIgnoreEvent = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + self.clickInterval) { [weak self] in
                    self?.isIgnoreEvent = false
                }
            }
            
            // 【关键修改 3】：在这里进行安全的泛型转换
            // sender 确定是 UIControl，将其安全转换为泛型 T（例如 UIButton）再回调给外部
            if let typedSender = sender as? T {
                handler(typedSender)
            }
        }
        
        // 更新字典并重新绑定
        wrappers[eventKey] = wrapper
        objc_setAssociatedObject(self, &AssociatedKeys.wrappersKey, wrappers, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
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
