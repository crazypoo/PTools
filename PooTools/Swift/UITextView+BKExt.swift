//
//  UITextView+BKExt.swift
//  Brickyard
//
//  Created by lam on 2019/8/31.
//  Copyright © 2019 lam. All rights reserved.
//

import UIKit

// MARK: - 扩展 UITextView，添加 placeholder 和 字数限制功能。
/*
 1、使用 SnapKit 进行布局。
 2、使用 objc/runtime 动态添加了 bk_placeholderLabel 等属性
 */

fileprivate var bk_placeholderLabelKey = "bk_placeholderLabelKey"
fileprivate var bk_placeholderKey = "bk_placeholderKey"
fileprivate var bk_attributedTextKey = "bk_attributedTextKey"
fileprivate var bk_wordCountLabelKey = "bk_wordCountLabelKey"
fileprivate var bk_maxWordCountKey = "bk_maxWordCountKey"

public extension UITextView {
    
    /// 移除监听
    func bk_removeAllObservers() -> () {
        
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
        removeObserver(self, forKeyPath: "text")
    }
    
    /// bk_placeholder Label
    var bk_placeholderLabel: UILabel? {
        set{
            objc_setAssociatedObject(self, &bk_placeholderLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get{
            let obj =  objc_getAssociatedObject(self, &bk_placeholderLabelKey)
            guard let placeholderLabel = obj as? UILabel else {
                let label = UILabel()
                label.textAlignment = .left
                label.numberOfLines = 0
                label.font = font
                label.textColor = UIColor.lightGray
                label.isUserInteractionEnabled = false
                label.translatesAutoresizingMaskIntoConstraints = false
                addSubview(label)
                // 添加约束。要约束宽，否则可能导致label不换行。
                addConstraint(NSLayoutConstraint(item: label, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 7))
                addConstraint(NSLayoutConstraint(item: label, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1.0, constant: 4))
                addConstraint(NSLayoutConstraint(item: label, attribute: .width, relatedBy: .lessThanOrEqual, toItem: self, attribute: .width, multiplier: 1.0, constant: -8))
                addConstraint(NSLayoutConstraint(item: label, attribute: .height, relatedBy: .lessThanOrEqual, toItem: self, attribute: .height, multiplier: 1.0, constant: -7))
                // 设置bk_placeholderLabel，自动调用set方法
                self.bk_placeholderLabel = label
                
                addObserver(self, forKeyPath: "text", options: NSKeyValueObservingOptions.new, context: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(bk_textDidChange), name: UITextView.textDidChangeNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(bk_textDidChange), name: UITextView.textDidBeginEditingNotification, object: nil)
//                bk_textDidChange()
                
                return label
            }
            return placeholderLabel
        }
    }
    
    /// bk_placeholder
    var bk_placeholder: String? {
        set {
            objc_setAssociatedObject(self, bk_placeholderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let placeholder = newValue else { return }
            bk_placeholderLabel?.text = placeholder
        }
        get {
            objc_getAssociatedObject(self, bk_placeholderKey) as? String
        }
    }
    
    /// bk_placeholderAttributedText
    var bk_placeholderAttributedText: NSAttributedString? {
        set {
            objc_setAssociatedObject(self, &bk_attributedTextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let attr = newValue else { return }
            bk_placeholderLabel?.attributedText = attr
        }
        get {
            objc_getAssociatedObject(self, &bk_attributedTextKey) as? NSAttributedString
        }
    }
    
    /// 字数的Label
    var bk_wordCountLabel: UILabel? {
        set{
            // 调用 setter 的时候会执行此处代码，将自定义的label通过runtime保存起来
            objc_setAssociatedObject(self, &bk_wordCountLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get{
            let obj =  objc_getAssociatedObject(self, &bk_wordCountLabelKey) as? UILabel
            guard let wordCountLabel = obj else {
                let label = UILabel()
                label.textAlignment = .right
                label.font = font
                label.textColor = UIColor.lightGray
                label.isUserInteractionEnabled = false
                
                // 添加到视图中
                if let grandfatherView = superview {
                    // 这里添加到 self.superview。如果添加到self，发现自动布局效果不理想。
                    grandfatherView.addSubview(label)
                    
                    label.translatesAutoresizingMaskIntoConstraints = false
                    
                    grandfatherView.addConstraint(NSLayoutConstraint(item: label, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: -7)) 
                    grandfatherView.addConstraint(NSLayoutConstraint(item: label, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -7))
                } else {
                    print("请先将您的UITextView添加到视图中")
                }
                
                // 调用setter
                self.bk_wordCountLabel = label
                
                NotificationCenter.default.addObserver(self, selector: #selector(bk_maxWordCountAction), name: UITextView.textDidChangeNotification, object: nil)
                
                return label
            }
            return wordCountLabel
        }
    }
    
    /// 限制的字数
    var bk_maxWordCount: Int? {
        set {
            let num = NSNumber(integerLiteral: newValue!)
            objc_setAssociatedObject(self, &bk_maxWordCountKey, num, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let count = newValue else { return }
            guard let label = bk_wordCountLabel else { return }
            label.text = "\(text.count)/\(count)"
            
        }
        get {
            let num = objc_getAssociatedObject(self, &bk_maxWordCountKey) as? NSNumber
            return num?.intValue
        }
    }
    
    @objc private func bk_maxWordCountAction() -> () {
        
        guard let maxCount = bk_maxWordCount else { return }
        if text.count >= maxCount {
            /// 输入的文字超过最大值
            text = (self.text as NSString).substring(to: maxCount)
            print("已经超过限制的字数了！");
        }
    }
    
    /// text 长度发生了变化
    @objc private func bk_textDidChange() -> () {
        
        if let placeholderLabel = bk_placeholderLabel {
            placeholderLabel.isHidden = (text.count > 0)
        }
        
        if let wordCountLabel = bk_wordCountLabel {
            guard let count = bk_maxWordCount else { return }
            wordCountLabel.text = "\(text.count)/\(count)"
        }
        
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if object is UITextView {
            let lbl = object as! UITextView
            if lbl === self && keyPath == "text" {
                if lbl.text == " " {
                    text = ""
                }
                bk_textDidChange()
            }
        }
    }
}
