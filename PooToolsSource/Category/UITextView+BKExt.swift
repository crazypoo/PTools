//
//  UITextView+BKExt.swift
//  Brickyard
//
//  Created by lam on 2019/8/31.
//  Copyright © 2019 lam. All rights reserved.
//

import UIKit
import SnapKit

// MARK: - 扩展 UITextView，添加 placeholder 和 字数限制功能。
/*
 1、使用 SnapKit 进行布局。
 2、使用 objc/runtime 动态添加了 bk_placeholderLabel 等属性
 */

public extension UITextView {
    private struct AssociatedKeys {
        static var bk_placeholderLabelKey = 999
        static var bk_placeholderKey = 998
        static var bk_attributedTextKey = 997
        static var bk_wordCountLabelKey = 996
        static var bk_maxWordCountKey = 995
        static var pt_textCountPositionKey = 994
    }

    /// 移除监听
    func bk_removeAllObservers() -> () {
        
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
        removeObserver(self, forKeyPath: "text")
    }
        
    //MARK: 設置TextView的Placeholder Label
    ///設置TextView的Placeholder Label
    var bk_placeholderLabel: UILabel? {
        set{
            objc_setAssociatedObject(self, &AssociatedKeys.bk_placeholderLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.bk_placeholderLabelKey)
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
                bk_placeholderLabel = label
                
                addObserver(self, forKeyPath: "text", options: NSKeyValueObservingOptions.new, context: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(bk_textDidChange), name: UITextView.textDidChangeNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(bk_textDidChange), name: UITextView.textDidBeginEditingNotification, object: nil)
//                bk_textDidChange()
                
                return label
            }
            return placeholderLabel
        }
    }
    
    //MARK: 設置TextView的Placeholder
    ///設置TextView的Placeholder
    @objc var bk_placeholder: String? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.bk_placeholderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let placeholder = newValue else { return }
            bk_placeholderLabel?.text = placeholder
        } get {
            objc_getAssociatedObject(self, &AssociatedKeys.bk_placeholderKey) as? String
        }
    }
    
    //MARK: 設置TextView的Placeholder的富文本
    ///設置TextView的Placeholder的富文本
    @objc var bk_placeholderAttributedText: NSAttributedString? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.bk_attributedTextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let attr = newValue else { return }
            bk_placeholderLabel?.attributedText = attr
        } get {
            objc_getAssociatedObject(self, &AssociatedKeys.bk_attributedTextKey) as? NSAttributedString
        }
    }
    
    //MARK: 設置TextView的字數限制Label
    ///設置TextView的字數限制Label
    var bk_wordCountLabel: UILabel? {
        set{
            // 调用 setter 的时候会执行此处代码，将自定义的label通过runtime保存起来
            objc_setAssociatedObject(self, &AssociatedKeys.bk_wordCountLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get{
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.bk_wordCountLabelKey) as? UILabel
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
                    PTNSLogConsole("请先将您的UITextView添加到视图中")
                }
                
                // 调用setter
                bk_wordCountLabel = label
                
                NotificationCenter.default.addObserver(self, selector: #selector(bk_maxWordCountAction), name: UITextView.textDidChangeNotification, object: nil)
                
                return label
            }
            return wordCountLabel
        }
    }
    
    //MARK: 設置TextView的字數限制
    ///設置TextView的字數限制
    @objc var pt_maxWordCount: NSNumber? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.bk_maxWordCountKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let count = newValue else { return }
            guard let label = bk_wordCountLabel else { return }
            label.text = "\(text.count)/\(count)"
        } get {
            let num = objc_getAssociatedObject(self, &AssociatedKeys.bk_maxWordCountKey) as? NSNumber
            return num
        }
    }
        
    @objc private func bk_maxWordCountAction() -> () {
        
        guard let maxCount = pt_maxWordCount else { return }
        if text.pt.typeLengh(.utf8) >= maxCount.intValue {
            /// 输入的文字超过最大值
            text = (self.text as NSString).substring(to: maxCount.intValue)
            PTNSLogConsole("已经超过限制的字数了！")
        }
    }
    
    /// text 长度发生了变化
    @objc private func bk_textDidChange() -> () {
        
        if let placeholderLabel = bk_placeholderLabel {
            placeholderLabel.isHidden = (text.count > 0)
        }
        
        if let wordCountLabel = bk_wordCountLabel {
            guard let count = pt_maxWordCount else { return }
            var valueInt = 0
            if text.pt.typeLengh(.utf8) > count.intValue {
                valueInt = (text.pt.typeLengh(.utf8) - count.intValue)
            }
            wordCountLabel.text = "\(text.pt.typeLengh(.utf8) - valueInt)/\(count)"
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, 
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
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
