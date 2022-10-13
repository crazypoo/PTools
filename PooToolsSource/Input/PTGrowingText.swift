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

public class PTGrowingTextView: UIView {

    public var growingTextDidChangeHeight:GrowingTextDidChangeHeight?
    public var growingTextDidChange:GrowingTextDidChange?
    public var growingTextWillChangeHeight:GrowingTextDidChangeHeight?
    public var growingTextShouldBeginEditing:GrowingTextDidChange?
    public var growingTextShouldEndEditing:GrowingTextDidChange?
    public var growingTextDidBeginEditing:GrowingTextDidChange?
    public var growingTextDidEndEditing:GrowingTextDidChange?
    public var growingTextShouldChange:GrowingTextChangeTextRange?
    public var growingTextShouldReturn:GrowingTextDidChange?
    public var growingTextDidChangeSelection:GrowingTextDidChange?
    public var text:String
    {
        get
        {
            self.internalText.text
        }
        set
        {
            self.internalText.text = newValue
            self.perform(#selector(self.textViewDidChange(_:)), with: self.internalText)
        }
    }
    
    public var font:UIFont
    {
        get
        {
            .appfont(size: 13)
        }
        set
        {
            self.internalText.font = newValue
            self.maxNumberOfLines = self.maxNumberOfLines
            self.minNumberOfLines = self.minNumberOfLines
        }
    }
    
    public var textColor:UIColor
    {
        get
        {
            .black
        }
        set
        {
            self.internalText.textColor = newValue
        }
    }
    
    public override var backgroundColor: UIColor?
    {
        get
        {
            .clear
        }
        set
        {
            self.internalText.backgroundColor = newValue
        }
    }
    
    public var textAlignment:NSTextAlignment?
    {
        didSet{
            self.internalText.textAlignment = self.textAlignment!
        }
    }
    
    public var selectedRange:NSRange?
    {
        didSet{
            self.internalText.selectedRange = self.selectedRange!
        }
    }
    
    public var isScrollable:Bool?
    {
        didSet{
            self.internalText.isScrollEnabled = self.isScrollable!
        }
    }
    
    public var editable:Bool?
    {
        didSet{
            self.internalText.isEditable = self.editable!
        }
    }
    
    public var returnKeyType:UIReturnKeyType?
    {
        didSet{
            self.internalText.returnKeyType = self.returnKeyType!
        }
    }
    
    public var keyboardType:UIKeyboardType?
    {
        didSet{
            self.internalText.keyboardType = self.keyboardType!
        }
    }
    
    public var enablesReturnKeyAutomatically:Bool?
    {
        didSet{
            self.internalText.enablesReturnKeyAutomatically = self.enablesReturnKeyAutomatically!
        }
    }
    
    public var dataDetectorTypes:UIDataDetectorTypes?
    {
        didSet{
            self.internalText.dataDetectorTypes = self.dataDetectorTypes!
        }
    }

    public var hasText:Bool
    {
        get
        {
            self.internalText.hasText
        }
    }
    
    public var maxTextCount:Int = 1000
    
    var internalText:PTGrowingInternal!
    var minHeihgt:CGFloat = 0
    {
        didSet
        {
            self.minNumberOfLines = 0
        }
    }
    var maxHeihgt:CGFloat = 0
    {
        didSet
        {
            self.maxNumberOfLines = 0
        }
    }
    lazy var minNumberOfLines:Int = 2
    {
        didSet
        {
            if self.minNumberOfLines == 0 && self.minHeihgt > 0
            {
                return
            }
            let saveText = self.internalText.text
            var newText = "-"
            
            self.internalText.delegate = nil
            self.internalText.isHidden = true
            
            for _ in 0..<self.minNumberOfLines
            {
                newText = newText.nsString.appending("\n|W|")
            }
            
            self.internalText.text = newText
            self.minHeihgt = self.measureHeight()
            self.internalText.text = saveText
            self.internalText.isHidden = false
            self.internalText.delegate = self
            self.sizeToFit()
        }
    }
    lazy var maxNumberOfLines:Int = 0
    {
        didSet
        {
            if self.maxNumberOfLines == 0 && self.maxHeihgt > 0
            {
                return
            }
            let saveText = self.internalText.text
            var newText = "-"
            
            self.internalText.delegate = nil
            self.internalText.isHidden = true
            
            for _ in 1..<self.maxNumberOfLines
            {
                newText = newText.nsString.appending("\n|W|")
            }
            
            self.internalText.text = newText
            self.maxHeihgt = self.measureHeight()
            self.internalText.text = saveText
            self.internalText.isHidden = false
            self.internalText.delegate = self
            self.sizeToFit()
        }
    }
    var animationHeightChange:Bool = true
    var animationDuration:CGFloat = 1
    var placeholderColor:UIColor
    {
        get
        {
            self.internalText.placeholderColor ?? .clear
        }
        set{
            self.internalText.placeholderColor = newValue
        }
    }
    var contentInset:UIEdgeInsets = .zero
    
    public init(frame:CGRect,textContainer:NSTextContainer) {
        super.init(frame: frame)
        self.commonInitialiser(frame: frame, container: textContainer)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInitialiser(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInitialiser(frame:CGRect,container:NSTextContainer? = nil)
    {
        if container != nil
        {
            self.internalText = PTGrowingInternal.init(frame: frame, textContainer: container!)
        }
        else
        {
            self.internalText = PTGrowingInternal.init(frame: frame)
        }
        
        self.internalText.delegate = self
        self.internalText.isScrollEnabled = false
        self.internalText.font = .appfont(size: 13)
        self.internalText.contentInset = .zero
        self.internalText.showsHorizontalScrollIndicator = false
        self.internalText.text = "-"
        self.internalText.contentMode = .redraw
        self.addSubview(self.internalText)
        
        
        self.internalText.text = ""
        
        self.maxNumberOfLines = 3
        
        self.internalText.displayPlaceHolder = true
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.internalText.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        var r = self.frame
        r.origin.y = 0
        r.origin.x = 0
        self.minHeihgt = self.internalText.frame.size.height
    }
    
    func measureHeight()->CGFloat
    {
        if self.responds(to: #selector(snapshotView(afterScreenUpdates:)))
        {
            return ceil(self.internalText.sizeThatFits(self.internalText.frame.size).height)
        }
        return self.internalText.contentSize.height
    }
    
    func refreshHeight()
    {
        var newSizeH = self.measureHeight()
        if newSizeH < self.minHeihgt || !self.internalText.hasText
        {
            newSizeH = minHeihgt
        }
        else if maxHeihgt > 0 && newSizeH > maxHeihgt
        {
            newSizeH = self.maxHeihgt
        }
        
        if self.internalText.frame.size.height != newSizeH
        {
            if newSizeH >= self.maxHeihgt
            {
                if !self.internalText.isScrollEnabled
                {
                    self.internalText.isScrollEnabled = true
                    self.internalText.flashScrollIndicators()
                }
            }
            else
            {
                self.internalText.isScrollEnabled = false
            }
            
            if newSizeH <= self.maxHeihgt
            {
                if self.animationHeightChange
                {
                    UIView.animate(withDuration: self.animationDuration, delay: 0,options: [.allowUserInteraction,.beginFromCurrentState]) {
                        self.resizeTextView(newSizeH: newSizeH)
                    } completion: { finish in
                        if self.growingTextDidChangeHeight != nil
                        {
                            self.growingTextDidChangeHeight!(self,newSizeH)
                        }
                    }
                }
            }
            else
            {
                self.resizeTextView(newSizeH: newSizeH)
                if self.growingTextDidChangeHeight != nil
                {
                    self.growingTextDidChangeHeight!(self,newSizeH)
                }
            }
        }
        
        let wasDisplayPlaceholder = self.internalText.displayPlaceHolder
        self.internalText.displayPlaceHolder = self.internalText.text.nsString.length == 0
        if wasDisplayPlaceholder != self.internalText.displayPlaceHolder
        {
            self.internalText.setNeedsDisplay()
        }
        
        if self.responds(to: #selector(snapshotView(afterScreenUpdates:)))
        {
            self.perform(#selector(self.resetScrollPosition), afterDelay: 0.1)
        }
        
        if self.growingTextDidChange != nil
        {
            self.growingTextDidChange!(self)
        }
    }
    
    func resizeTextView(newSizeH:CGFloat)
    {
        if self.growingTextWillChangeHeight != nil
        {
            self.growingTextWillChangeHeight!(self,newSizeH)
        }
        
        var internalTextViewFrame = self.frame
        internalTextViewFrame.size.height = newSizeH
        self.frame = internalTextViewFrame
        
        internalTextViewFrame.origin.y = self.contentInset.top - self.contentInset.bottom
        internalTextViewFrame.origin.x = self.contentInset.left
        
        if !CGRectEqualToRect(self.internalText.frame, internalTextViewFrame)
        {
            self.internalText.frame = internalTextViewFrame
        }
    }
    
    @objc func growDidStop()
    {
        if self.responds(to: #selector(snapshotView(afterScreenUpdates:)))
        {
            self.resetScrollPosition()
        }
        
        if self.growingTextDidChangeHeight != nil
        {
            self.growingTextDidChangeHeight!(self,self.frame.size.height)
        }
    }
    
    @objc func resetScrollPosition()
    {
        let r = self.internalText.caretRect(for: self.internalText.selectedTextRange?.end ?? UITextPosition())
        let caretY = max(r.origin.y - self.internalText.frame.self.height + r.size.height + 8, 0)
        if self.internalText.contentOffset.y < caretY && r.origin.y != .infinity
        {
            self.internalText.contentOffset = CGPoint(x: 0, y: caretY)
        }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.internalText.becomeFirstResponder()
    }
    
    public override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return self.internalText.becomeFirstResponder()
    }
    
    public override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return self.internalText.resignFirstResponder()
    }
    
    public override var isFirstResponder: Bool
    {
        return self.internalText.isFirstResponder
    }
    
    public func scrollRangeToVisible(range:NSRange)
    {
        self.internalText.scrollRangeToVisible(range)
    }
}

extension PTGrowingTextView:UITextViewDelegate
{
    public func textViewDidChange(_ textView: UITextView) {
        self.refreshHeight()
        let nsTextContent = textView.text
        let existTextNum = nsTextContent?.nsString.length
        PTLocalConsoleFunction.share.pNSLog("\(String(describing: existTextNum))")
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if self.growingTextShouldBeginEditing != nil
        {
            self.growingTextShouldBeginEditing!(self)
        }
        return true
    }
    
    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        if self.growingTextShouldEndEditing != nil
        {
            self.growingTextShouldEndEditing!(self)
        }
        return true
    }
    
    public func textViewDidBeginEditing(_ textView: UITextView) {
        if self.growingTextDidBeginEditing != nil
        {
            self.growingTextDidBeginEditing!(self)
        }
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        if self.growingTextDidEndEditing != nil
        {
            self.growingTextDidEndEditing!(self)
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if !textView.hasText && text.stringIsEmpty()
        {
            return false
        }
        
        if self.growingTextShouldChange != nil
        {
            self.growingTextShouldChange!(self,range,text)
        }
        
        if text == "\n"
        {
            if self.growingTextShouldReturn != nil
            {
                self.growingTextShouldReturn!(self)
                return true
            }
            else
            {
                textView.resignFirstResponder()
                return false
            }
        }
        
        if range.location >= self.maxTextCount
        {
            return false
        }
        else
        {
            return true
        }
    }
    
    public func textViewDidChangeSelection(_ textView: UITextView) {
        if self.growingTextDidChangeSelection != nil
        {
            self.growingTextDidChangeSelection!(self)
        }
    }
}

class PTGrowingInternal:UITextView
{
    public var placeholder:String = ""
    public var placeholderColor:UIColor?
    {
        didSet{
            self.setNeedsDisplay()
        }
    }
    public var displayPlaceHolder:Bool = false

    public override var text: String!
    {
        didSet{
            let originalValue = self.isScrollEnabled
            self.isScrollEnabled = true
            self.isScrollEnabled = originalValue
        }
    }
    
    public override var contentOffset: CGPoint
    {
        didSet
        {
            if self.isTracking || self.isDecelerating
            {
                var insets = self.contentInset
                insets.bottom = 0
                insets.top = 0
                self.contentInset = insets
            }
            else
            {
                let bottomOffSet = self.contentSize.height - self.frame.size.height + self.contentInset.bottom
                if self.contentOffset.y < bottomOffSet && self.isScrollEnabled
                {
                    var insets = self.contentInset
                    insets.bottom = 8
                    insets.top = 0
                    self.contentInset = insets
                }
            }
            
            if self.contentOffset.y > self.contentSize.height - self.frame.size.height && !self.isDecelerating && !self.isTracking && !self.isDragging
            {
                self.contentOffset = CGPoint(x: self.contentOffset.x,y: self.contentSize.height - self.frame.size.height)
            }
        }
    }
    
    public override var contentInset: UIEdgeInsets
    {
        didSet
        {
            var insets = self.contentInset
            if self.contentInset.bottom > 8
            {
                insets.bottom = 0
                insets.top = 0
                self.contentInset = insets
            }
        }
    }
    
    public override var contentSize: CGSize
    {
        didSet{
            var insets = self.contentInset
            insets.bottom = 0
            insets.top = 0
            self.contentInset = insets
        }
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if self.displayPlaceHolder && !self.placeholder.stringIsEmpty() && self.placeholderColor != nil
        {
            if self.responds(to: #selector(snapshotView(afterScreenUpdates:)))
            {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = self.textAlignment
                
                self.placeholder.nsString.draw(in: CGRect(x: 5, y: 8 + self.contentInset.top, width: self.frame.size.width - self.contentInset.left, height: self.frame.size.height - self.contentInset.top),withAttributes: [NSAttributedString.Key.font:self.font!,NSAttributedString.Key.foregroundColor:self.placeholderColor!,NSAttributedString.Key.paragraphStyle:paragraphStyle])
            }
            else
            {
                self.placeholderColor?.set()
                self.placeholder.nsString.draw(in: CGRect(x: 8, y: 8 , width: self.frame.size.width - 16, height: self.frame.size.height - 16))
            }
        }
    }
}
