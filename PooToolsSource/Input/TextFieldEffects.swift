//
//  TextFieldEffects.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 24/01/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit

extension String {
    /// 检查字符串是否不为空
    /// - Returns: 如果包含字符返回 true，如果是空字符串则返回 false
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

/// 一个自定义的 UITextField 基类，用于处理独特的文本输入状态和占位符显示动画。
/// ⚠️ 注意：这是一个抽象基类，不应该直接实例化。请通过创建它的子类来实现具体的视图绘制和动画逻辑。
open class TextFieldEffects: UITextField {
    
    /// 定义了输入框可以执行的动画类型
    public enum AnimationType: Int {
        /// 当输入框获得焦点或文本非空时触发的动画（进入输入状态）
        case textEntry
        /// 当输入框失去焦点且文本为空时触发的动画（恢复默认展示状态）
        case textDisplay
    }
    
    /// 动画完成后的回调闭包类型
    /// - Parameter type: 刚刚完成的动画类型
    public typealias AnimationCompletionHandler = (_ type: AnimationType) -> Void
    
    /// 自定义的占位符 Label，用于替代系统默认的占位符，以便子类对其进行动画处理
    public let placeholderLabel = UILabel()
    
    /// 动画完成时的回调属性
    open var animationCompletionHandler: AnimationCompletionHandler?
    
    // MARK: - 必须被子类重写的核心方法 (Abstract Methods)
    
    /// 创建并执行文本输入时的动画（例如：输入框聚焦时，占位符向上移动并缩小）。
    /// ⚠️ 子类必须重写此方法，否则会触发致命错误。
    open func animateViewsForTextEntry() {
        fatalError("\(#function) 必须在子类中被重写")
    }
    
    /// 创建并执行结束文本输入时的动画（例如：输入框失去焦点且无文本时，占位符恢复原位）。
    /// ⚠️ 子类必须重写此方法，否则会触发致命错误。
    open func animateViewsForTextDisplay() {
        fatalError("\(#function) 必须在子类中被重写")
    }
    
    /// 自定义绘制输入框的各种组件（例如绘制底部的下划线或边框）。
    /// - Parameter rect: 需要重绘的视图区域。
    /// ⚠️ 子类必须重写此方法，否则会触发致命错误。
    open func drawViewsForRect(_ rect: CGRect) {
        fatalError("\(#function) 必须在子类中被重写")
    }
    
    /// 当输入框的边界 (bounds) 发生变化时更新视图。
    /// - Parameter bounds: 新的边界 CGRect。
    /// ⚠️ 子类必须重写此方法，否则会触发致命错误。
    open func updateViewsForBoundsChange(_ bounds: CGRect) {
        fatalError("\(#function) 必须在子类中被重写")
    }
    
    // MARK: - UITextField 默认行为重写
    
    /// 重写系统的 draw 方法以接入自定义的绘制逻辑
    override open func draw(_ rect: CGRect) {
        // 如果输入框当前正在处于第一响应者（正在输入）状态，则避免多余的重绘，提升性能
        guard !isFirstResponder else { return }
        drawViewsForRect(rect)
    }
    
    /// 重写绘制占位符的方法
    override open func drawPlaceholder(in rect: CGRect) {
        // 刻意留空：阻止系统绘制默认的占位符，因为我们要使用自定义的 `placeholderLabel`
    }
    
    /// 监听程序化修改 text 属性的动作
    override open var text: String? {
        didSet {
            // 当代码动态设置文本时，根据文本内容和焦点状态，自动触发对应的动画
            let shouldAnimateEntry = (text?.isNotEmpty ?? false) || isFirstResponder
            shouldAnimateEntry ? animateViewsForTextEntry() : animateViewsForTextDisplay()
        }
    }
    
    // MARK: - 生命周期与通知监听
    
    /// 当视图被添加到父视图或从父视图移除时调用
    override open func willMove(toSuperview newSuperview: UIView!) {
        if newSuperview != nil {
            // 当被添加到父视图时，注册编辑开始和结束的系统通知
            NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidBeginEditing), name: UITextField.textDidBeginEditingNotification, object: self)
            NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidEndEditing), name: UITextField.textDidEndEditingNotification, object: self)
        } else {
            // 当从父视图移除时，清理通知监听，防止内存泄漏
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    /// 触发条件：输入框开始编辑（获得焦点）
    @objc open func textFieldDidBeginEditing() {
        animateViewsForTextEntry()
    }
    
    /// 触发条件：输入框结束编辑（失去焦点）
    @objc open func textFieldDidEndEditing() {
        animateViewsForTextDisplay()
    }
    
    // MARK: - Interface Builder 支持
    
    /// 让自定义视图可以在 Xcode 的 Storyboard / XIB 中实时预览渲染结果
    override open func prepareForInterfaceBuilder() {
        drawViewsForRect(frame)
    }
}
