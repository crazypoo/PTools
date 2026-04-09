//
//  UITextView+ptExt.swift
//  Brickyard
//
//  Created by lam on 2019/8/31.
//  Copyright © 2019 lam. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - 扩展 UITextView，添加 placeholder 和 字数限制功能
public extension UITextView {
    
    private struct AssociatedKeys {
        static var pt_placeholderLabelKey = 999
        static var pt_placeholderKey = 998
        static var pt_attributedTextKey = 997
        static var pt_wordCountLabelKey = 996
        static var pt_maxWordCountKey = 995
        static var pt_kvoTokensKey = 994 // 新增：用于存储 KVO Token，实现自动释放
    }

    // MARK: - 1. KVO 生命周期管理 (自动释放机制)
    /// 存储 KVO 的 Token，伴随 UITextView 释放而自动释放，无需手动 removeObserver
    private var pt_kvoTokens: [NSKeyValueObservation] {
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.pt_kvoTokensKey) as? [NSKeyValueObservation]) ?? []
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pt_kvoTokensKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // MARK: - 2. Placeholder Label 逻辑
    @objc var pt_placeholderLabel: UILabel? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pt_placeholderLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let label = objc_getAssociatedObject(self, &AssociatedKeys.pt_placeholderLabelKey) as? UILabel {
                return label
            }
            
            // 初始化 Label
            let label = UILabel()
            label.textAlignment = .left
            label.numberOfLines = 0
            // 安全解包，避免 font 为 nil 时崩溃
            label.font = self.font ?? UIFont.systemFont(ofSize: 14)
            label.textColor = UIColor.lightGray
            label.isUserInteractionEnabled = false
            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)
            
            // 约束：跟随 textContainerInset 变化
            label.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(self.textContainerInset.left + 5) // +5 稍微对齐光标
                make.top.equalToSuperview().inset(self.textContainerInset.top)
                make.width.equalToSuperview().offset(-(self.textContainerInset.left + self.textContainerInset.right + 10))
            }
            
            // 设置属性并添加监听
            self.pt_placeholderLabel = label
            pt_setupObservers()
            
            return label
        }
    }
    
    @objc var pt_placeholder: String? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pt_placeholderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            pt_placeholderLabel?.text = newValue
            pt_textDidChange() // 赋值后刷新状态
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.pt_placeholderKey) as? String
        }
    }
    
    @objc var pt_placeholderAttributedText: NSAttributedString? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pt_attributedTextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            pt_placeholderLabel?.attributedText = newValue
            pt_textDidChange() // 赋值后刷新状态
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.pt_attributedTextKey) as? NSAttributedString
        }
    }
    
    // MARK: - 3. 字数统计 Label 逻辑 (完美封装)
    @objc var pt_wordCountLabel: UILabel? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pt_wordCountLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let label = objc_getAssociatedObject(self, &AssociatedKeys.pt_wordCountLabelKey) as? UILabel {
                return label
            }
            
            let label = UILabel()
            label.textAlignment = .right
            label.font = self.font ?? UIFont.systemFont(ofSize: 12)
            label.textColor = UIColor.lightGray
            label.isUserInteractionEnabled = false
            
            // ⭐️ 核心优化：直接添加到 UITextView 内部，不依赖外部视图！
            addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            label.snp.makeConstraints { make in
                // 使用 frameLayoutGuide 让它悬浮在右下角，不会随着文本滚动而消失
                make.right.equalTo(self.frameLayoutGuide).offset(-self.textContainerInset.right - 5)
                make.bottom.equalTo(self.frameLayoutGuide).offset(-self.textContainerInset.bottom - 5)
            }
            
            self.pt_wordCountLabel = label
            pt_setupObservers()
            
            return label
        }
    }
    
    @objc var pt_maxWordCount: NSNumber? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pt_maxWordCountKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            pt_textDidChange() // 赋值后立刻刷新显示
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.pt_maxWordCountKey) as? NSNumber
        }
    }
    
    // MARK: - 4. 监听与更新逻辑
    /// 统一设置通知和原生的 Block KVO 监听
    private func pt_setupObservers() {
        // 防止重复添加
        guard pt_kvoTokens.isEmpty else { return }
        
        // 监听系统输入通知
        NotificationCenter.default.addObserver(self, selector: #selector(pt_textDidChange), name: UITextView.textDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(pt_textDidChange), name: UITextView.textDidBeginEditingNotification, object: self)
        
        // 监听 text 属性的直接赋值 (代码赋值)
        let textObserver = observe(\.text, options: [.new]) { [weak self] _, _ in
            self?.pt_textDidChange()
        }
        
        // 监听 bounds 变化刷新 Placeholder 宽度
        let boundsObserver = observe(\.bounds, options: [.new]) { [weak self] _, _ in
            self?.pt_updatePlaceholderPreferredWidth()
        }
        
        // 存储 Token，UITextView 释放时自动取消监听
        pt_kvoTokens = [textObserver, boundsObserver]
    }
    
    /// 当文本发生变化时的核心处理逻辑
    @objc private func pt_textDidChange() {
        // 1. 处理 Placeholder 隐藏/显示
        let hasText = !(self.text?.isEmpty ?? true)
        pt_placeholderLabel?.isHidden = hasText
        
        // 2. 处理字数限制和截断
        if let maxCount = pt_maxWordCount?.intValue, maxCount > 0 {
            let currentText = self.text ?? ""
            
            // 只有未组字状态才强制截断（防止原生输入法拼音输入中被打断）
            if let markedTextRange = self.markedTextRange,
               self.position(from: markedTextRange.start, offset: 0) != nil {
                // 正在拼音组字中，只更新字数，不截断
                let currentCount = currentText.count
                pt_wordCountLabel?.text = "\(currentCount)/\(maxCount)"
                return
            }
            
            // 超过字数进行截断
            if currentText.count > maxCount {
                self.text = String(currentText.prefix(maxCount))
                // 假设 PTNSLogConsole 是你项目内的日志工具
                // PTNSLogConsole("已经超过限制的字数了！（已截断）", levelType: PTLogMode, loggerType: .textView)
            }
            
            // 3. 更新统计文本
            let safeCount = min(self.text.count, maxCount)
            pt_wordCountLabel?.text = "\(safeCount)/\(maxCount)"
        }
    }
    
    private func pt_updatePlaceholderPreferredWidth() {
        guard let label = pt_placeholderLabel else { return }
        let maxWidth = bounds.width - textContainerInset.left - textContainerInset.right - textContainer.lineFragmentPadding * 2
        
        guard maxWidth > 0 else { return }
        
        if label.preferredMaxLayoutWidth != maxWidth {
            label.preferredMaxLayoutWidth = maxWidth
            label.setNeedsLayout()
            label.layoutIfNeeded()
        }
    }
    
    // MARK: - 5. 动态计算高度相关方法
    func layoutDynamicHeight(width: CGFloat) {
        if isScrollEnabled { isScrollEnabled = false }
        frame.size.width = width
        sizeToFit()
        if frame.width != width {
            frame.size.width = width
        }
    }
    
    func layoutDynamicHeight(x: CGFloat, y: CGFloat, width: CGFloat) {
        if isScrollEnabled { isScrollEnabled = false }
        frame = CGRect(x: x, y: y, width: width, height: frame.height)
        sizeToFit()
        if frame.width != width {
            frame.size.width = width
        }
    }
    
    @objc func getTextViewSize(width: CGFloat = CGFloat.greatestFiniteMagnitude,
                               height: CGFloat = CGFloat.greatestFiniteMagnitude) -> CGSize {
        // 移除自定义 stringIsEmpty 依赖，使用标准 swift 语法
        guard let currentText = text, !currentText.isEmpty, let currentFont = font else {
            return .zero
        }
        // 假设这是你项目中扩展的方法，保留它
        return UIView.sizeFor(string: currentText, font: currentFont, height: height, width: width)
    }
    
    @objc func getLabelWidth(height: CGFloat) -> CGFloat {
        return getTextViewSize(height: height).width
    }
    
    @objc func getLabelHeight(width: CGFloat) -> CGFloat {
        return getTextViewSize(width: width).height
    }
}
