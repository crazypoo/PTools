//
//  PTActiveLabel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 31/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public class PTActiveLabel: UILabel {
    
    open var didSelectedHandle: PTActiveDidSelectedHandle?
    open var enabledTypes: [PTActiveType] = [.mention, .hashtag, .url, .chinaCellPhone, .snsId]
    open var urlMaximumLength: Int?
    open var configureLinkAttribute: PTConfigureLinkAttribute?
    
    open var mentionColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } }
    open var mentionSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } }
    open var hashtagColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } }
    open var hashtagSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } }
    open var URLColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } }
    open var URLSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } }
    open var chinaCellPhoneColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } }
    open var chinaCellPhoneSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } }
    open var snsIdColor: UIColor = .blue { didSet { updateTextStorage(parseText: false) } }
    open var snsIdSelectedColor: UIColor? { didSet { updateTextStorage(parseText: false) } }
    open var customColor: [PTActiveType : UIColor] = [:] { didSet { updateTextStorage(parseText: false) } }
    open var customSelectedColor: [PTActiveType : UIColor] = [:] { didSet { updateTextStorage(parseText: false) } }
    
    public var lineSpacing: CGFloat = 0 { didSet { updateTextStorage(parseText: false) } }
    public var minimumLineHeight: CGFloat = 0 { didSet { updateTextStorage(parseText: false) } }
    public var highlightFontName: String? = nil { didSet { updateTextStorage(parseText: false) } }
    public var highlightFontSize: CGFloat? = nil { didSet { updateTextStorage(parseText: false) } }
    
    private var hightlightFont: UIFont? {
        guard let highlightFontName = highlightFontName, let highlightFontSize = highlightFontSize else { return nil }
        return UIFont(name: highlightFontName, size: highlightFontSize)
    }
    
    // 回调与过滤属性保持不变
    internal var mentionTapHandler: PTActiveStringHandle?
    internal var hashtagTapHandler: PTActiveStringHandle?
    internal var urlTapHandler: PTActiveURLHandle?
    internal var emailTapHandler: PTActiveStringHandle?
    internal var chinaCellPhoneTapHandler: PTActiveStringHandle?
    internal var snsIdTapHandler: PTActiveStringHandle?
    internal var customTapHandlers: [PTActiveType : PTActiveStringHandle] = [:]
    
    fileprivate var mentionFilterPredicate: PTActiveStringBoolCallBack?
    fileprivate var hashtagFilterPredicate: PTActiveStringBoolCallBack?
    fileprivate var chinaCellPhoneFilterPredicate: PTActiveStringBoolCallBack?
    fileprivate var snsIdFilterPredicate: PTActiveStringBoolCallBack?

    open func handleMentionTap(_ handler: @escaping PTActiveStringHandle) { mentionTapHandler = handler }
    open func handleHashtagTap(_ handler: @escaping PTActiveStringHandle) { hashtagTapHandler = handler }
    open func handleURLTap(_ handler: @escaping PTActiveURLHandle) { urlTapHandler = handler }
    open func handleCustomTap(for type: PTActiveType, handler: @escaping PTActiveStringHandle) { customTapHandlers[type] = handler }
    open func handleEmailTap(_ handler: @escaping PTActiveStringHandle) { emailTapHandler = handler }
    open func handleChinaCellPhoneTap(_ handler: @escaping PTActiveStringHandle) { chinaCellPhoneTapHandler = handler }
    open func handleSnsIdTap(_ handler: @escaping PTActiveStringHandle) { snsIdTapHandler = handler }
    
    override open var text: String? { didSet { updateTextStorage() } }
    override open var attributedText: NSAttributedString? { didSet { updateTextStorage() } }
    override open var font: UIFont! { didSet { updateTextStorage(parseText: false) } }
    override open var textColor: UIColor! { didSet { updateTextStorage(parseText: false) } }
    override open var textAlignment: NSTextAlignment { didSet { updateTextStorage(parseText: false) } }
    open override var numberOfLines: Int { didSet { textContainer.maximumNumberOfLines = numberOfLines } }
    open override var lineBreakMode: NSLineBreakMode { didSet { textContainer.lineBreakMode = lineBreakMode } }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        _customizing = false
        setupLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _customizing = false
        setupLabel()
    }
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        // 修复：使用 Swift Concurrency 替代 GCD
        Task { @MainActor in
            self.updateTextStorage()
        }
    }
    
    open override func drawText(in rect: CGRect) {
        let range = NSRange(location: 0, length: textStorage.length)
        textContainer.size = rect.size
        let newOrigin = textOrigin(inRect: rect)
        
        layoutManager.drawBackground(forGlyphRange: range, at: newOrigin)
        layoutManager.drawGlyphs(forGlyphRange: range, at: newOrigin)
    }
    
    @discardableResult
    open func customize(_ block: (_ label: PTActiveLabel) -> ()) -> PTActiveLabel {
        _customizing = true
        block(self)
        _customizing = false
        updateTextStorage()
        return self
    }
    
    open override var intrinsicContentSize: CGSize {
        guard let text = text, !text.isEmpty else { return .zero }
        textContainer.size = CGSize(width: preferredMaxLayoutWidth, height: CGFloat.greatestFiniteMagnitude)
        let size = layoutManager.usedRect(for: textContainer)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
    
    fileprivate var _customizing: Bool = true
    fileprivate var defaultCustomColor: UIColor = .black
    
    fileprivate var selectedElement: PTElementTuple?
    fileprivate var heightCorrection: CGFloat = 0
    internal lazy var textStorage = NSTextStorage()
    fileprivate lazy var layoutManager = NSLayoutManager()
    fileprivate lazy var textContainer = NSTextContainer()
    lazy var activeElements = [PTActiveType: [PTElementTuple]]()
    
    // 保存当前的高亮取消任务，方便取消
    private var highlightTask: Task<Void, Never>?
    
    fileprivate func setupLabel() {
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = lineBreakMode
        textContainer.maximumNumberOfLines = numberOfLines
        isUserInteractionEnabled = true
    }
    
    fileprivate func updateTextStorage(parseText: Bool = true) {
        if _customizing { return }
        guard let attributedText = attributedText, attributedText.length > 0 else {
            clearActiveElements()
            textStorage.setAttributedString(NSAttributedString())
            setNeedsDisplay()
            return
        }
        
        let mutAttrString = addLineBreak(attributedText)
        
        if parseText {
            clearActiveElements()
            let newString = parseTextAndExtractActiveElements(mutAttrString)
            mutAttrString.mutableString.setString(newString)
        }
        
        addLinkAttribute(mutAttrString)
        textStorage.setAttributedString(mutAttrString)
        _customizing = true
        text = mutAttrString.string
        _customizing = false
        setNeedsDisplay()
    }
    
    fileprivate func clearActiveElements() {
        selectedElement = nil
        activeElements.removeAll()
    }
    
    fileprivate func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRect(for: textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
    
    private func getActiveColor(for type: PTActiveType, isSelected: Bool) -> UIColor {
        switch type {
        case .mention: return isSelected ? (mentionSelectedColor ?? mentionColor) : mentionColor
        case .hashtag: return isSelected ? (hashtagSelectedColor ?? hashtagColor) : hashtagColor
        case .url: return isSelected ? (URLSelectedColor ?? URLColor) : URLColor
        case .chinaCellPhone: return isSelected ? (chinaCellPhoneSelectedColor ?? chinaCellPhoneColor) : chinaCellPhoneColor
        case .snsId: return isSelected ? (snsIdSelectedColor ?? snsIdColor) : snsIdColor
        case .email: return isSelected ? (URLSelectedColor ?? URLColor) : URLColor
        case .custom:
            let color = isSelected ? (customSelectedColor[type] ?? customColor[type]) : customColor[type]
            return color ?? defaultCustomColor
        }
    }

    fileprivate func addLinkAttribute(_ mutAttrString: NSMutableAttributedString) {
        let textLength = mutAttrString.length
        guard textLength > 0 else { return }
        
        let fullRange = NSRange(location: 0, length: textLength)
        var baseAttributes = mutAttrString.attributes(at: 0, effectiveRange: nil)
        
        if let currentFont = font { baseAttributes[.font] = currentFont }
        if let currentTextColor = textColor { baseAttributes[.foregroundColor] = currentTextColor }
        mutAttrString.addAttributes(baseAttributes, range: fullRange)
        
        for (type, elements) in activeElements {
            var typeAttributes: [NSAttributedString.Key: Any] = [:]
            typeAttributes[.foregroundColor] = getActiveColor(for: type, isSelected: false)
            if let highlightFont = hightlightFont { typeAttributes[.font] = highlightFont }
            
            if let configureLinkAttribute = configureLinkAttribute {
                typeAttributes = configureLinkAttribute(type, typeAttributes, false)
            }
            
            for element in elements {
                let safeLocation = element.range.location
                let safeLength = element.range.length
                if safeLocation >= 0 && safeLocation + safeLength <= textLength {
                    mutAttrString.addAttributes(typeAttributes, range: element.range)
                }
            }
        }
    }

    fileprivate func parseTextAndExtractActiveElements(_ attrString: NSAttributedString) -> String {
        var textString = attrString.string
        var textLength = textString.utf16.count
        var textRange = NSRange(location: 0, length: textLength)
        
        if enabledTypes.contains(.url) {
            let tuple = PTActiveBuilder.createURLElements(text: textString, range: textRange, maximumLength: urlMaximumLength)
            textString = tuple.1
            textLength = textString.utf16.count
            textRange = NSRange(location: 0, length: textLength)
            activeElements[.url] = tuple.0
        }
        
        for type in enabledTypes where type != .url {
            var filter: PTActiveStringBoolCallBack? = nil
            switch type {
            case .mention: filter = mentionFilterPredicate
            case .hashtag: filter = hashtagFilterPredicate
            case .chinaCellPhone: filter = chinaCellPhoneFilterPredicate
            case .snsId: filter = snsIdFilterPredicate
            default: break
            }
            let elements = PTActiveBuilder.createElements(type: type, from: textString, range: textRange, filterPredicate: filter)
            activeElements[type] = elements
        }
        return textString
    }
    
    fileprivate func addLineBreak(_ attrString: NSAttributedString) -> NSMutableAttributedString {
        let mutAttrString = NSMutableAttributedString(attributedString: attrString)
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        let paragraphStyle = attributes[.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.minimumLineHeight = minimumLineHeight > 0 ? minimumLineHeight : font.pointSize * 1.14
        attributes[.paragraphStyle] = paragraphStyle
        mutAttrString.setAttributes(attributes, range: range)
        
        return mutAttrString
    }
    
    fileprivate func updateAttributesWhenSelected(_ isSelected: Bool) {
        guard let selectedElement = selectedElement else { return }
        var attributes = textStorage.attributes(at: 0, effectiveRange: nil)
        let type = selectedElement.type
        
        attributes[.foregroundColor] = getActiveColor(for: type, isSelected: isSelected)
        if let highlightFont = hightlightFont { attributes[.font] = highlightFont }
        if let configureLinkAttribute = configureLinkAttribute {
            attributes = configureLinkAttribute(type, attributes, isSelected)
        }
        textStorage.addAttributes(attributes, range: selectedElement.range)
        setNeedsDisplay()
    }
    
    fileprivate func element(location: CGPoint) -> PTElementTuple? {
        guard textStorage.length > 0 else { return nil }
        var correctLocation = location
        correctLocation.y -= heightCorrection
        let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
        guard boundingRect.contains(correctLocation) else { return nil }
        
        let index = layoutManager.glyphIndex(for: correctLocation, in: textContainer)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: index, length: 1), in: textContainer)
        guard glyphRect.contains(correctLocation) else { return nil }
        
        // 优化：避免重复 map 创造中间数组
        for (_, elements) in activeElements {
            for element in elements {
                if index >= element.range.location && index <= element.range.location + element.range.length {
                    return element
                }
            }
        }
        return nil
    }
    
    func onTouch(_ touch: UITouch) -> Bool {
        let location = touch.location(in: self)
        var avoidSuperCall = false
        
        switch touch.phase {
        case .began, .moved, .regionEntered, .regionMoved:
            if let element = element(location: location) {
                if element.range.location != selectedElement?.range.location || element.range.length != selectedElement?.range.length {
                    updateAttributesWhenSelected(false)
                    selectedElement = element
                    updateAttributesWhenSelected(true)
                }
                avoidSuperCall = true
            } else {
                updateAttributesWhenSelected(false)
                selectedElement = nil
            }
        case .ended, .regionExited:
            guard let selectedElement = selectedElement else { return avoidSuperCall }
            
            switch selectedElement.element {
            case .mention(let userHandle): didTapMention(userHandle)
            case .hashtag(let hashtag): didTapHashtag(hashtag)
            case .url(let originalURL, _): didTapStringURL(originalURL)
            case .custom(let element): didTap(element, for: selectedElement.type)
            case .email(let element): didTapStringEmail(element)
            case .chinaCellPhone(let element): didTapStringChinaCellPhone(element)
            case .snsId(let element): didTapStringSnsId(element)
            }
            
            // 修复：取消旧的高亮任务
            highlightTask?.cancel()
            highlightTask = Task { @MainActor in
                // 延迟 0.25 秒
                try? await Task.sleep(nanoseconds: 250_000_000)
                guard !Task.isCancelled else { return }
                self.updateAttributesWhenSelected(false)
                self.selectedElement = nil
            }
            avoidSuperCall = true
        case .cancelled:
            updateAttributesWhenSelected(false)
            selectedElement = nil
        case .stationary: break
        @unknown default: break
        }
        return avoidSuperCall
    }

    // 触控转发逻辑及点击分发逻辑不变...
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesBegan(touches, with: event)
    }
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesMoved(touches, with: event)
    }
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        _ = onTouch(touch)
        super.touchesCancelled(touches, with: event)
    }
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if onTouch(touch) { return }
        super.touchesEnded(touches, with: event)
    }

    fileprivate func didTapMention(_ username: String) {
        mentionTapHandler?(username) ?? didSelectedHandle?(username, .mention)
    }
    fileprivate func didTapHashtag(_ hashtag: String) {
        hashtagTapHandler?(hashtag) ?? didSelectedHandle?(hashtag, .hashtag)
    }
    fileprivate func didTapStringURL(_ stringURL: String) {
        guard let url = URL(string: stringURL) else {
            didSelectedHandle?(stringURL, .url)
            return
        }
        urlTapHandler?(url) ?? didSelectedHandle?(stringURL, .url)
    }
    fileprivate func didTapStringEmail(_ stringEmail: String) {
        emailTapHandler?(stringEmail) ?? didSelectedHandle?(stringEmail, .email)
    }
    fileprivate func didTapStringChinaCellPhone(_ stringChinaCellPhone: String) {
        chinaCellPhoneTapHandler?(stringChinaCellPhone) ?? didSelectedHandle?(stringChinaCellPhone, .chinaCellPhone)
    }
    fileprivate func didTapStringSnsId(_ stringSnsid: String) {
        snsIdTapHandler?(stringSnsid) ?? didSelectedHandle?(stringSnsid, .snsId)
    }
    fileprivate func didTap(_ element: String, for type: PTActiveType) {
        customTapHandlers[type]?(element) ?? didSelectedHandle?(element, type)
    }
}

extension PTActiveLabel: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
}
