//
//  PTGrowingText.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/13.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

public typealias GrowingTextDidChangeHeight = (_ views:PTGrowingTextView,_ height:CGFloat)->Void
public typealias GrowingTextDidChange = (_ views:PTGrowingTextView)->Void
public typealias GrowingTextChangeTextRange = (_ views:PTGrowingTextView,_ range:NSRange,_ replaceText:String)->Void

@objcMembers
open class PTGrowingTextView: UITextView {
    
    open var growingTextDidChangeHeight:GrowingTextDidChangeHeight?

    override open var text: String! {
        didSet { setNeedsDisplay() }
    }
    
    private var newHeight:CGFloat = 0
        
    // Maximum length of text. 0 means no limit.
    @IBInspectable open var maxLength: Int = 0
    
    // Trim white space and newline characters when end editing. Default is true
    @IBInspectable open var trimWhiteSpaceWhenEndEditing: Bool = true
    
    // Customization
    @IBInspectable open var minHeight: CGFloat = 0 {
        didSet { forceLayoutSubviews() }
    }
    @IBInspectable open var maxHeight: CGFloat = 0 {
        didSet { forceLayoutSubviews() }
    }
    @IBInspectable open var placeholder: String? {
        didSet { layoutSubviews() }
    }
    @IBInspectable open var placeholderColor: UIColor = UIColor(white: 0.8, alpha: 1.0) {
        didSet { layoutSubviews() }
    }
    open var attributedPlaceholder: NSAttributedString? {
        didSet { layoutSubviews() }
    }
    
    open var placeHolderLROffset: CGFloat = 10 {
        didSet { layoutSubviews() }
    }
    
    // Initialize
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        contentMode = .redraw
        associateConstraints()
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidEndEditing), name: UITextView.textDidEndEditingNotification, object: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 30)
    }
    
    private func associateConstraints() {
        // iterate through all text view's constraints and identify
        PTGCDManager.gcdAfter(time: 0.1) {
            self.newHeight = self.frame.size.height
        }
    }
    
    // Calculate and adjust textview's height
    private var oldText: String = ""
    private var oldSize: CGSize = .zero
    
    private func forceLayoutSubviews() {
        oldSize = .zero
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private var shouldScrollAfterHeightChanged = false
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        oldText = text
        oldSize = bounds.size
        
        let size = UIView.sizeFor(string: text, font: self.font ?? .systemFont(ofSize: 16),width: bounds.size.width)
        var height = size.height
        
        // Constrain minimum height
        height = minHeight > 0 ? max(height, minHeight) : height
        
        // Constrain maximum height
        height = maxHeight > 0 ? min(height, maxHeight) : height
        
        // Add height constraint if it is not found
        newHeight = height

        // Update height constraint if needed
        shouldScrollAfterHeightChanged = height > minHeight
        if growingTextDidChangeHeight != nil {
            growingTextDidChangeHeight!(self,height)
        }
        if shouldScrollAfterHeightChanged {
            shouldScrollAfterHeightChanged = false
            scrollToCorrectPosition()
        }
    }
    
    private func scrollToCorrectPosition() {
        if isFirstResponder {
            scrollRangeToVisible(NSRange(location: -1, length: 0)) // Scroll to bottom
        } else {
            scrollRangeToVisible(NSRange(location: 0, length: 0)) // Scroll to top
        }
    }
    
    // Show placeholder if needed
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if text.isEmpty {
            let height = (font ?? .systemFont(ofSize: 16)).pointSize
            let xValue:CGFloat = placeHolderLROffset
            let yValue:CGFloat = (rect.size.height - height) / 2
            let width = rect.size.width - xValue * 2
            let placeholderRect = CGRect(x: xValue, y: yValue, width: width, height: height)
            
            if let attributedPlaceholder = attributedPlaceholder {
                // Prefer to use attributedPlaceholder
                attributedPlaceholder.draw(in: placeholderRect)
            } else if let placeholder = placeholder {
                // Otherwise user placeholder and inherit `text` attributes
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = textAlignment
                var attributes: [NSAttributedString.Key: Any] = [
                    .foregroundColor: placeholderColor,
                    .paragraphStyle: paragraphStyle
                ]
                if let font = font {
                    attributes[.font] = font
                }
                
                placeholder.draw(in: placeholderRect, withAttributes: attributes)
            }
        }
    }
    
    // Trim white space and new line characters when end editing.
    func textDidEndEditing(notification: Notification) {
        if let sender = notification.object as? PTGrowingTextView, sender == self {
            if trimWhiteSpaceWhenEndEditing {
                text = text?.trimmingCharacters(in: .whitespacesAndNewlines)
                layoutSubviews()
            }
            scrollToCorrectPosition()
        }
    }
    
    // Limit the length of text
    func textDidChange(notification: Notification) {
        if let sender = notification.object as? PTGrowingTextView, sender == self {
            if maxLength > 0 && text.count > maxLength {
                let endIndex = text.index(text.startIndex, offsetBy: maxLength)
                text = String(text[..<endIndex])
                undoManager?.removeAllActions()
            }
            layoutSubviews()
        }
    }
}
