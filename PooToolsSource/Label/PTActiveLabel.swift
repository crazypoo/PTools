//
//  PTActiveLabel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 31/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias PTConfigureLinkAttribute = (PTActiveType, [NSAttributedString.Key : Any], Bool) -> [NSAttributedString.Key : Any]
typealias PTElementTuple = (range: NSRange, element: PTActiveElement, type: PTActiveType)
public typealias PTActiveDidSelectedHandle = (String, PTActiveType) -> ()
public typealias PTActiveStringHandle = (String) -> ()
public typealias PTActiveURLHandle = (URL) -> ()
public typealias PTActiveStringBoolCallBack = (String) -> Bool

public class PTActiveLabel: UILabel {
    
    open var didSelectedHandle: PTActiveDidSelectedHandle?
    
    open var enabledTypes: [PTActiveType] = [.mention, .hashtag, .url,.chinaCellPhone,.snsId]
    
    open var urlMaximumLength: Int?
    
    open var configureLinkAttribute: PTConfigureLinkAttribute?
    
    open var mentionColor: UIColor = .blue {
        didSet { 
            updateTextStorage(parseText: false)
        }
    }
    open var mentionSelectedColor: UIColor? {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    open var hashtagColor: UIColor = .blue {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    open var hashtagSelectedColor: UIColor? {
        didSet { 
            updateTextStorage(parseText: false)
        }
    }
    open var URLColor: UIColor = .blue {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    open var URLSelectedColor: UIColor? {
        didSet { 
            updateTextStorage(parseText: false)
        }
    }
    open var chinaCellPhoneColor: UIColor = .blue {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    open var chinaCellPhoneSelectedColor: UIColor? {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    open var snsIdColor: UIColor = .blue {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    open var snsIdSelectedColor: UIColor? {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    open var customColor: [PTActiveType : UIColor] = [:] {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    open var customSelectedColor: [PTActiveType : UIColor] = [:] {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    public var lineSpacing: CGFloat = 0 {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    public var minimumLineHeight: CGFloat = 0 {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    public var highlightFontName: String? = nil {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    public var highlightFontSize: CGFloat? = nil {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    
    // MARK: - 计算字体
    private var hightlightFont: UIFont? {
        guard let highlightFontName = highlightFontName, let highlightFontSize = highlightFontSize else { return nil }
        return UIFont(name: highlightFontName, size: highlightFontSize)
    }
    
    open func handleMentionTap(_ handler: @escaping PTActiveStringHandle) {
        mentionTapHandler = handler
    }
    
    open func handleHashtagTap(_ handler: @escaping PTActiveStringHandle) {
        hashtagTapHandler = handler
    }
    
    open func handleURLTap(_ handler: @escaping PTActiveURLHandle) {
        urlTapHandler = handler
    }
    
    open func handleCustomTap(for type: PTActiveType, handler: @escaping PTActiveStringHandle) {
        customTapHandlers[type] = handler
    }
    
    open func handleEmailTap(_ handler: @escaping PTActiveStringHandle) {
        emailTapHandler = handler
    }
    
    open func handleChinaCellPhoneTap(_ handler: @escaping PTActiveStringHandle) {
        chinaCellPhoneTapHandler = handler
    }

    open func handleSnsIdTap(_ handler: @escaping PTActiveStringHandle) {
        snsIdTapHandler = handler
    }
    
    open func removeHandle(for type: PTActiveType) {
        switch type {
        case .hashtag:
            hashtagTapHandler = nil
        case .mention:
            mentionTapHandler = nil
        case .url:
            urlTapHandler = nil
        case .custom:
            customTapHandlers[type] = nil
        case .email:
            emailTapHandler = nil
        case .chinaCellPhone:
            chinaCellPhoneTapHandler = nil
        case .snsId:
            snsIdTapHandler = nil
        }
    }
    
    open func filterMention(_ predicate: @escaping PTActiveStringBoolCallBack) {
        mentionFilterPredicate = predicate
        updateTextStorage()
    }
    
    open func filterHashtag(_ predicate: @escaping PTActiveStringBoolCallBack) {
        hashtagFilterPredicate = predicate
        updateTextStorage()
    }
    
    open func filterChinaCellPhone(_ predicate: @escaping PTActiveStringBoolCallBack) {
        chinaCellPhoneFilterPredicate = predicate
        updateTextStorage()
    }
    
    open func filterSnsId(_ predicate: @escaping PTActiveStringBoolCallBack) {
        snsIdFilterPredicate = predicate
        updateTextStorage()
    }
    
    override open var text: String? {
        didSet { 
            updateTextStorage()
        }
    }
    
    override open var attributedText: NSAttributedString? {
        didSet {
            updateTextStorage()
        }
    }
    
    override open var font: UIFont! {
        didSet { 
            updateTextStorage(parseText: false)
        }
    }
    
    override open var textColor: UIColor! {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    
    override open var textAlignment: NSTextAlignment {
        didSet {
            updateTextStorage(parseText: false)
        }
    }
    
    open override var numberOfLines: Int {
        didSet { 
            textContainer.maximumNumberOfLines = numberOfLines
        }
    }
    
    open override var lineBreakMode: NSLineBreakMode {
        didSet {
            textContainer.lineBreakMode = lineBreakMode
        }
    }
    
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
        updateTextStorage()
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
        guard let text = text, !text.isEmpty else {
            return .zero
        }

        textContainer.size = CGSize(width: preferredMaxLayoutWidth, height: CGFloat.greatestFiniteMagnitude)
        let size = layoutManager.usedRect(for: textContainer)
        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
        
    fileprivate var _customizing: Bool = true
    fileprivate var defaultCustomColor: UIColor = .black
    
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

    fileprivate var selectedElement: PTElementTuple?
    fileprivate var heightCorrection: CGFloat = 0
    internal lazy var textStorage = NSTextStorage()
    fileprivate lazy var layoutManager = NSLayoutManager()
    fileprivate lazy var textContainer = NSTextContainer()
    lazy var activeElements = [PTActiveType: [PTElementTuple]]()
    
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
        // clean up previous active elements
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
        for (type, _) in activeElements {
            activeElements[type]?.removeAll()
        }
    }
    
    fileprivate func textOrigin(inRect rect: CGRect) -> CGPoint {
        let usedRect = layoutManager.usedRect(for: textContainer)
        heightCorrection = (rect.height - usedRect.height)/2
        let glyphOriginY = heightCorrection > 0 ? rect.origin.y + heightCorrection : rect.origin.y
        return CGPoint(x: rect.origin.x, y: glyphOriginY)
    }
    
    // MARK: - 优化 3: 提取统一的颜色获取辅助方法，减少重复代码
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

    /// 添加富文本
    fileprivate func addLinkAttribute(_ mutAttrString: NSMutableAttributedString) {
        let textLength = mutAttrString.length
        
        // 修复 1：绝对防御，如果文本为空，直接返回，防止 attributes(at: 0) 越界崩溃
        guard textLength > 0 else { return }
        
        // 修复 2：获取基础属性，并确保基础属性覆盖的是【全局完整文本】，而不是原本的有效片段 (effectiveRange)
        let fullRange = NSRange(location: 0, length: textLength)
        var baseAttributes = mutAttrString.attributes(at: 0, effectiveRange: nil)
        
        if let currentFont = font {
            baseAttributes[.font] = currentFont
        }
        if let currentTextColor = textColor {
            baseAttributes[.foregroundColor] = currentTextColor
        }
        // 使用 addAttributes 而不是覆盖，更安全
        mutAttrString.addAttributes(baseAttributes, range: fullRange)
        
        for (type, elements) in activeElements {
            
            // 为每种类型单独配置颜色和字体
            var typeAttributes: [NSAttributedString.Key: Any] = [:]
            typeAttributes[.foregroundColor] = getActiveColor(for: type, isSelected: false)
            
            if let highlightFont = hightlightFont {
                typeAttributes[.font] = highlightFont
            }
            
            if let configureLinkAttribute = configureLinkAttribute {
                // 将原有的 baseAttributes 传进去以便外部继承
                typeAttributes = configureLinkAttribute(type, typeAttributes, false)
            }
            
            for element in elements {
                // 修复 3：【核心崩溃点】严格验证元素的 range 是否在安全范围内！
                let safeLocation = element.range.location
                let safeLength = element.range.length
                
                if safeLocation >= 0 && safeLocation + safeLength <= textLength {
                    // 使用 addAttributes，防止 setAttributes 把 lineSpacing 等段落样式意外覆盖掉
                    mutAttrString.addAttributes(typeAttributes, range: element.range)
                } else {
                    // 如果发生越界，这里会自动拦截并在开发环境下打印，App 绝不会崩溃
                    #if DEBUG
                    PTNSLogConsole("⚠️ [PTActiveLabel] 越界拦截：文本总长度 \(textLength)，试图渲染的 Range(\(safeLocation), \(safeLength))")
                    #endif
                }
            }
        }
    }

    /// 通过正则表达式去检查所有的连接
    fileprivate func parseTextAndExtractActiveElements(_ attrString: NSAttributedString) -> String {
        var textString = attrString.string
        var textLength = textString.utf16.count
        var textRange = NSRange(location: 0, length: textLength)
        
        if enabledTypes.contains(.url) {
            let tuple = PTActiveBuilder.createURLElements(text: textString, range: textRange, maximumLength: urlMaximumLength)
            let urlElements = tuple.0
            let finalText = tuple.1
            textString = finalText
            textLength = textString.utf16.count
            textRange = NSRange(location: 0, length: textLength)
            activeElements[.url] = urlElements
        }
        
        for type in enabledTypes where type != .url {
            var filter: ((String) -> Bool)? = nil
            if type == .mention {
                filter = mentionFilterPredicate
            } else if type == .hashtag {
                filter = hashtagFilterPredicate
            } else if type == .chinaCellPhone {
                filter = chinaCellPhoneFilterPredicate
            } else if type == .snsId {
                filter = snsIdFilterPredicate
            }
            let hashtagElements = PTActiveBuilder.createElements(type: type, from: textString, range: textRange, filterPredicate: filter)
            activeElements[type] = hashtagElements
        }
        
        return textString
    }
    
    
    /// 给富文本添加LineBreakMode
    fileprivate func addLineBreak(_ attrString: NSAttributedString) -> NSMutableAttributedString {
        let mutAttrString = NSMutableAttributedString(attributedString: attrString)
        
        var range = NSRange(location: 0, length: 0)
        var attributes = mutAttrString.attributes(at: 0, effectiveRange: &range)
        
        let paragraphStyle = attributes[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraphStyle.alignment = textAlignment
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.minimumLineHeight = minimumLineHeight > 0 ? minimumLineHeight: font.pointSize * 1.14
        attributes[NSAttributedString.Key.paragraphStyle] = paragraphStyle
        mutAttrString.setAttributes(attributes, range: range)
        
        return mutAttrString
    }
    
    fileprivate func updateAttributesWhenSelected(_ isSelected: Bool) {
        guard let selectedElement = selectedElement else { return }
        
        var attributes = textStorage.attributes(at: 0, effectiveRange: nil)
        let type = selectedElement.type
        
        // 使用统一颜色方法
        attributes[.foregroundColor] = getActiveColor(for: type, isSelected: isSelected)
        
        if let highlightFont = hightlightFont {
            attributes[.font] = highlightFont
        }
        
        if let configureLinkAttribute = configureLinkAttribute {
            attributes = configureLinkAttribute(type, attributes, isSelected)
        }
        
        textStorage.addAttributes(attributes, range: selectedElement.range)
        setNeedsDisplay()
    }
    
    // MARK: - 优化 2: 修复“幽灵触控”问题
    fileprivate func element(location: CGPoint) -> PTElementTuple? {
        guard textStorage.length > 0 else { return nil }
                
        var correctLocation = location
        correctLocation.y -= heightCorrection
        let boundingRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: 0, length: textStorage.length), in: textContainer)
        guard boundingRect.contains(correctLocation) else { return nil }
        
        let index = layoutManager.glyphIndex(for: correctLocation, in: textContainer)
        
        // 【关键修复】校验触摸点是否真正落在了该字形的实际矩形区域内，而不是仅仅“离它最近”
        let glyphRect = layoutManager.boundingRect(forGlyphRange: NSRange(location: index, length: 1), in: textContainer)
        guard glyphRect.contains(correctLocation) else { return nil }
        
        for element in activeElements.map({ $0.1 }).joined() {
            if index >= element.range.location && index <= element.range.location + element.range.length {
                return element
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
            // MARK: - 优化 1: 修复复制粘贴 Bug
            case .snsId(let element): didTapStringSnsId(element)
            }
            
            // 保持延迟取消高亮的体验
            let when = Double(Int64(0.25 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            PTGCDManager.gcdAfter(time: when) {
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

    //MARK: - Handle UI Responder touches
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
    
    //MARK: - ActiveLabel handler
    fileprivate func didTapMention(_ username: String) {
        guard let mentionHandler = mentionTapHandler else {
            didSelectedHandle?(username,.mention)
            return
        }
        mentionHandler(username)
    }
    
    fileprivate func didTapHashtag(_ hashtag: String) {
        guard let hashtagHandler = hashtagTapHandler else {
            didSelectedHandle?(hashtag,.hashtag)
            return
        }
        hashtagHandler(hashtag)
    }
    
    fileprivate func didTapStringURL(_ stringURL: String) {
        guard let urlHandler = urlTapHandler, let url = URL(string: stringURL) else {
            didSelectedHandle?(stringURL,.url)
            return
        }
        urlHandler(url)
    }
    
    fileprivate func didTapStringEmail(_ stringEmail: String) {
        guard let emailHandler = emailTapHandler else {
            didSelectedHandle?(stringEmail,.email)
            return
        }
        emailHandler(stringEmail)
    }
    
    fileprivate func didTapStringChinaCellPhone(_ stringChinaCellPhone: String) {
        guard let chinaCellPhoneTapHandler = chinaCellPhoneTapHandler else {
            didSelectedHandle?(stringChinaCellPhone,.chinaCellPhone)
            return
        }
        chinaCellPhoneTapHandler(stringChinaCellPhone)
    }
    
    fileprivate func didTapStringSnsId(_ stringSnsid: String) {
        guard let snsIdTapHandler = snsIdTapHandler else {
            didSelectedHandle?(stringSnsid,.snsId)
            return
        }
        snsIdTapHandler(stringSnsid)
    }
    
    fileprivate func didTap(_ element: String, for type: PTActiveType) {
        guard let elementHandler = customTapHandlers[type] else {
            didSelectedHandle?(element,type)
            return
        }
        elementHandler(element)
    }
}

extension PTActiveLabel: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}
