//
//  Extensions.swift
//
//  Created by Duraid Abdul.
//  Copyright © 2021 Duraid Abdul. All rights reserved.
//

import UIKit

// 1. 创建一个私有的闭包包装器，充当 Target-Action 中的 Target
private class UIControlClosureWrapper: NSObject {
    // 使用 Any 接收，方便在扩展中进行泛型转换
    let closure: (Any) -> Void
    
    init(_ closure: @escaping (Any) -> Void) {
        self.closure = closure
        super.init()
    }
    
    // 真正接收事件触发的方法
    @objc func invoke(_ sender: Any) {
        closure(sender)
    }
}

// 2. 为 UIControl 添加扩展
public extension UIControl {
    
    private struct AssociatedKeys {
        static var controlActionWrappersKey : UInt8 = 0
    }
    
    /// 统一的添加事件闭包方法
    /// - Parameters:
    ///   - event: 触发的事件类型，例如 .touchUpInside, .valueChanged
    ///   - handler: 触发后的回调闭包，泛型 T 会自动推断为调用该方法的 UIControl 子类
    func addActionHandler<T: UIControl>(for event: UIControl.Event, handler: @escaping (_ sender: T) -> Void) {
        
        // 获取当前控件已绑定的事件字典，如果没有则创建一个空字典
        var wrappers = objc_getAssociatedObject(self, &AssociatedKeys.controlActionWrappersKey) as? [UInt: UIControlClosureWrapper] ?? [:]
        
        // 创建新的包装器
        let wrapper = UIControlClosureWrapper { sender in
            // 将 sender 安全地转换为泛型 T
            if let typedSender = sender as? T {
                handler(typedSender)
            }
        }
        
        // 将包装器保存到字典中，防止被释放
        wrappers[event.rawValue] = wrapper
        objc_setAssociatedObject(self, &AssociatedKeys.controlActionWrappersKey, wrappers, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // 绑定 Target-Action
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
