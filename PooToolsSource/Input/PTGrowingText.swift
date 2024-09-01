//
//  PTGrowingText.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/13.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

public typealias GrowingTextDidChangeHeight = (_ views: PTGrowingTextView, _ height: CGFloat) -> Void
public typealias GrowingTextDidChange = (_ views: PTGrowingTextView) -> Void
public typealias GrowingTextChangeTextRange = (_ views: PTGrowingTextView, _ range: NSRange, _ replaceText: String) -> Void

@objcMembers
open class PTGrowingTextView: UITextView {

    open var growingTextDidChangeHeight: GrowingTextDidChangeHeight?
    
    override open var text: String! {
        didSet {
            layoutIfNeeded()
            setNeedsDisplay()
        }
    }
    
    private var newHeight: CGFloat = 0
    
    @IBInspectable open var maxLength: Int = 100
    @IBInspectable open var trimWhiteSpaceWhenEndEditing: Bool = true
    @IBInspectable open var minHeight: CGFloat = 44 {
        didSet { adjustHeightIfNeeded() }
    }
    @IBInspectable open var maxHeight: CGFloat = 400 {
        didSet { adjustHeightIfNeeded() }
    }
    @IBInspectable open var placeholder: String? {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable open var placeholderColor: UIColor = UIColor(white: 0.8, alpha: 1.0) {
        didSet { setNeedsDisplay() }
    }
    
    open var attributedPlaceholder: NSAttributedString? {
        didSet { setNeedsDisplay() }
    }
    
    open var placeHolderLROffset: CGFloat = 10 {
        didSet { setNeedsDisplay() }
    }

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
        setupObservers()
        associateConstraints()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(textDidEndEditing), name: UITextView.textDidEndEditingNotification, object: self)
    }

    override open var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: max(minHeight, newHeight))
    }

    private func associateConstraints() {
        PTGCDManager.gcdAfter(time: 0.1) {
            self.newHeight = self.frame.size.height
        }
    }

    private func adjustHeightIfNeeded() {
        setNeedsLayout()
        layoutIfNeeded()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        
        let size = UIView.sizeFor(string: text, font: self.font ?? .systemFont(ofSize: 16), width: bounds.size.width)
        var height = size.height
        
        height = minHeight > 0 ? max(height, minHeight) : height
        height = maxHeight > 0 ? min(height, maxHeight) : height
        
        if height != newHeight {
            newHeight = height
            invalidateIntrinsicContentSize()
            growingTextDidChangeHeight?(self, height)
        }

        setNeedsDisplay()
        scrollToCorrectPosition()
    }

    private func scrollToCorrectPosition() {
        let range = isFirstResponder ? NSRange(location: -1, length: 0) : NSRange(location: 0, length: 0)
        scrollRangeToVisible(range)
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard text.isEmpty else { return }
        
        let height = (font ?? .systemFont(ofSize: 16)).pointSize
        let xValue: CGFloat = placeHolderLROffset
        let yValue: CGFloat = (rect.size.height - height) / 2
        let width = rect.size.width - xValue * 2
        let placeholderRect = CGRect(x: xValue, y: yValue, width: width, height: height)
        
        if let attributedPlaceholder = attributedPlaceholder {
            attributedPlaceholder.draw(in: placeholderRect)
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
            var attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: placeholderColor,
                .paragraphStyle: paragraphStyle
            ]
            if let font = font {
                attributes[.font] = font
            }
            placeholder?.draw(in: placeholderRect, withAttributes: attributes)
        }
    }

    @objc private func textDidEndEditing(notification: Notification) {
        guard let sender = notification.object as? PTGrowingTextView, sender == self else { return }
        if trimWhiteSpaceWhenEndEditing {
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            setNeedsDisplay()
        }
        scrollToCorrectPosition()
    }

    @objc private func textDidChange(notification: Notification) {
        guard let sender = notification.object as? PTGrowingTextView, sender == self else { return }
        if maxLength > 0, text.count > maxLength {
            text = String(text.prefix(maxLength))
            undoManager?.removeAllActions()
        }
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }
}
