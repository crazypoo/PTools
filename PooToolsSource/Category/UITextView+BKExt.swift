//
//  UITextView+ptExt.swift
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
 2、使用 objc/runtime 动态添加了 pt_placeholderLabel 等属性
 */

public extension UITextView {
    private struct AssociatedKeys {
        static var pt_placeholderLabelKey = 999
        static var pt_placeholderKey = 998
        static var pt_attributedTextKey = 997
        static var pt_wordCountLabelKey = 996
        static var pt_maxWordCountKey = 995
        static var pt_textCountPositionKey = 994
    }

    /// 移除监听
    func pt_removeAllObservers() -> () {
        
        NotificationCenter.default.removeObserver(self, name: UITextView.textDidChangeNotification, object: nil)
        removeObserver(self, forKeyPath: "text")
    }
        
    //MARK: 設置TextView的Placeholder Label
    ///設置TextView的Placeholder Label
    @objc var pt_placeholderLabel: UILabel? {
        set{
            objc_setAssociatedObject(self, &AssociatedKeys.pt_placeholderLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get {
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.pt_placeholderLabelKey)
            guard let placeholderLabel = obj as? UILabel else {
                let label = UILabel()
                label.textAlignment = .left
                label.numberOfLines = 0
                label.font = font
                label.textColor = UIColor.lightGray
                label.isUserInteractionEnabled = false
                label.translatesAutoresizingMaskIntoConstraints = false
                addSubview(label)
                // 添加约束。要约束宽，否则可能导致label不换行。如果需要設置便宜,則需要先設置本體文字的便宜,再加載Placeholder
                label.snp.makeConstraints { make in
                    make.left.equalToSuperview().inset(self.textContainerInset.left)
                    make.top.equalToSuperview().inset(self.textContainerInset.top)
                    make.bottom.equalToSuperview().inset(self.textContainerInset.bottom)
                    make.right.equalToSuperview().inset(self.textContainerInset.right)
                }
                // 设置pt_placeholderLabel，自动调用set方法
                
                addObserver(self, forKeyPath: "text", options: NSKeyValueObservingOptions.new, context: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(pt_textDidChange), name: UITextView.textDidChangeNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(pt_textDidChange), name: UITextView.textDidBeginEditingNotification, object: nil)
                
                self.pt_placeholderLabel = label
                return label
            }
            return placeholderLabel
        }
    }
    
    //MARK: 設置TextView的Placeholder
    ///設置TextView的Placeholder
    @objc var pt_placeholder: String? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pt_placeholderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let placeholder = newValue else { return }
            pt_placeholderLabel?.text = placeholder
        } get {
            objc_getAssociatedObject(self, &AssociatedKeys.pt_placeholderKey) as? String
        }
    }
    
    //MARK: 設置TextView的Placeholder的富文本
    ///設置TextView的Placeholder的富文本
    @objc var pt_placeholderAttributedText: NSAttributedString? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pt_attributedTextKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let attr = newValue else { return }
            pt_placeholderLabel?.attributedText = attr
        } get {
            objc_getAssociatedObject(self, &AssociatedKeys.pt_attributedTextKey) as? NSAttributedString
        }
    }
    
    //MARK: 設置TextView的字數限制Label
    ///設置TextView的字數限制Label
    @objc var pt_wordCountLabel: UILabel? {
        set{
            // 调用 setter 的时候会执行此处代码，将自定义的label通过runtime保存起来
            objc_setAssociatedObject(self, &AssociatedKeys.pt_wordCountLabelKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        } get{
            let obj =  objc_getAssociatedObject(self, &AssociatedKeys.pt_wordCountLabelKey) as? UILabel
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
                    PTNSLogConsole("请先将您的UITextView添加到视图中", levelType: .Error,loggerType: .TextView)
                }
                
                self.pt_wordCountLabel = label
                // 调用setter
                NotificationCenter.default.addObserver(self, selector: #selector(pt_maxWordCountAction), name: UITextView.textDidChangeNotification, object: nil)
                
                return label
            }
            return wordCountLabel
        }
    }
    
    //MARK: 設置TextView的字數限制
    ///設置TextView的字數限制
    @objc var pt_maxWordCount: NSNumber? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.pt_maxWordCountKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let count = newValue else { return }
            guard let label = pt_wordCountLabel else { return }
            label.text = "\(text.count)/\(count)"
        } get {
            let num = objc_getAssociatedObject(self, &AssociatedKeys.pt_maxWordCountKey) as? NSNumber
            return num
        }
    }
        
    @objc private func pt_maxWordCountAction() -> () {
        
        guard let maxCount = pt_maxWordCount?.intValue, maxCount > 0 else { return }
        guard let currentText = self.text else { return }

        if currentText.pt.typeLengh(.utf8) > maxCount {
            let truncated = truncateToUTF8ByteLimit(currentText, maxBytes: maxCount)
            self.text = truncated
            PTNSLogConsole("已经超过限制的字数了！", levelType: PTLogMode, loggerType: .TextView)
        }
    }
    
    private func truncateToUTF8ByteLimit(_ text: String, maxBytes: Int) -> String {
        var totalBytes = 0
        var result = ""

        for scalar in text.unicodeScalars {
            let utf8Len = String(scalar).lengthOfBytes(using: .utf8)
            if totalBytes + utf8Len > maxBytes {
                break
            }
            totalBytes += utf8Len
            result.append(String(scalar))
        }
        return result
    }
    
    /// text 长度发生了变化
    @objc private func pt_textDidChange() -> () {
        
        if let placeholderLabel = pt_placeholderLabel {
            placeholderLabel.isHidden = (text.count > 0)
        }
        
        if let wordCountLabel = pt_wordCountLabel {
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
                pt_textDidChange()
            }
        }
    }
    
    func layoutDynamicHeight(width: CGFloat) {
        // Requerid for dynamic height.
        if isScrollEnabled { isScrollEnabled = false }
        
        frame.setWidth(width)
        sizeToFit()
        if frame.width != width {
            frame.setWidth(width)
        }
    }
    
    func layoutDynamicHeight(x: CGFloat, y: CGFloat, width: CGFloat) {
        // Requerid for dynamic height.
        if isScrollEnabled { isScrollEnabled = false }
        
        frame = CGRect(x: x, y: y, width: width, height: frame.height)
        sizeToFit()
        if frame.width != width {
            frame.setWidth(width)
        }
    }
}
