//
//  PTGrowingText.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/13.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

public typealias GrowingTextDidChangeHeight = (_ view: PTGrowingTextView, _ height: CGFloat) -> Void
public typealias GrowingTextDidChange = (_ view: PTGrowingTextView) -> Void

@objcMembers
open class PTGrowingTextView: UITextView {

    // MARK: - Callback
    open var growingTextDidChangeHeight: GrowingTextDidChangeHeight?
    open var growingTextDidChange: GrowingTextDidChange?

    // MARK: - Config
    @IBInspectable open var maxLength: Int = 100
    @IBInspectable open var trimWhiteSpaceWhenEndEditing: Bool = true
    @IBInspectable open var minHeight: CGFloat = 44 { didSet { recalcHeightAsync() } }
    @IBInspectable open var maxHeight: CGFloat = 400 { didSet { recalcHeightAsync() } }

    // MARK: - Placeholder
    @IBInspectable open var placeholder: String? { didSet { setNeedsDisplay() } }
    @IBInspectable open var placeholderColor: UIColor = UIColor(white: 0.8, alpha: 1.0) { didSet { setNeedsDisplay() } }
    open var attributedPlaceholder: NSAttributedString? { didSet { setNeedsDisplay() } }
    
    /// 占位符的左右偏移量 (如果不设置，建议贴合 textContainerInset)
    open var placeHolderLROffset: CGFloat = 10 { didSet { setNeedsDisplay() } }

    // MARK: - Overrides (处理代码赋值不触发更新的问题)
    open override var text: String! {
        didSet {
            setNeedsDisplay()
            recalcHeightAsync()
        }
    }
    
    open override var attributedText: NSAttributedString! {
        didSet {
            setNeedsDisplay()
            recalcHeightAsync()
        }
    }
    
    open override var font: UIFont? {
        didSet {
            setNeedsDisplay()
            recalcHeightAsync()
        }
    }
    
    open override var textAlignment: NSTextAlignment {
        didSet { setNeedsDisplay() }
    }

    // MARK: - Private
    private var currentHeight: CGFloat = 0
    private var isCalculatingHeight = false   // 防止重入

    // MARK: - Init
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func commonInit() {
        isScrollEnabled = false
        // contentMode = .redraw 会在 bounds size 改变时自动调用 drawRect
        contentMode = .redraw
        setupObservers()
        currentHeight = minHeight
    }

    // MARK: - Observers
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChangeNotification),
            name: UITextView.textDidChangeNotification,
            object: self
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidEndEditingNotification),
            name: UITextView.textDidEndEditingNotification,
            object: self
        )
    }

    // MARK: - Layout
    open override func layoutSubviews() {
        super.layoutSubviews()
        // ❌ 已经移除了 setNeedsDisplay()
        // 解释：layoutSubviews 在滚动、光标闪烁时会频繁调用。
        // 因为 init 里已经设置了 contentMode = .redraw，
        // size 变化会自动重绘，此处再调用会导致严重的性能消耗。
    }

    // MARK: - Height
    private func recalcHeightAsync() {
        guard !isCalculatingHeight else { return }
        isCalculatingHeight = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.recalcHeight()
            self.isCalculatingHeight = false
        }
    }

    private func recalcHeight() {
        guard bounds.width > 0 else { return }

        let fittingSize = CGSize(
            width: bounds.width,
            height: .greatestFiniteMagnitude
        )

        var contentHeight = sizeThatFits(fittingSize).height

        let minContentHeight =
            (font?.lineHeight ?? 16)
            + textContainerInset.top
            + textContainerInset.bottom

        contentHeight = max(contentHeight, minContentHeight)
        contentHeight = max(contentHeight, minHeight)

        let finalHeight: CGFloat
        let shouldScroll: Bool

        if contentHeight > maxHeight {
            finalHeight = maxHeight
            shouldScroll = true
        } else {
            finalHeight = contentHeight
            shouldScroll = false
        }

        let wasScrollable = isScrollEnabled

        if wasScrollable != shouldScroll {
            isScrollEnabled = shouldScroll
            showsVerticalScrollIndicator = shouldScroll
        }

        guard abs(finalHeight - currentHeight) > 0.5 else { return }

        currentHeight = finalHeight
        invalidateIntrinsicContentSize()
        growingTextDidChangeHeight?(self, finalHeight)

        if shouldScroll, !wasScrollable, text.count > 0 {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let range = NSMakeRange((self.text as NSString).length - 1, 1)
                self.scrollRangeToVisible(range)
            }
        }
    }

    open override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric,
               height: max(currentHeight, minHeight))
    }

    // MARK: - Draw Placeholder
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard text.isEmpty else { return }

        let font = self.font ?? .systemFont(ofSize: 16)
        let x = placeHolderLROffset
        
        // 优化点：Y轴坐标应该基于 textContainerInset.top 计算，
        // 否则随着文本框增高，占位符会永远跑到正中间，看起来像悬空了
        // 如果 minHeight 和默认 inset 不匹配，做个平滑兼容
        let y: CGFloat
        if currentHeight <= minHeight {
            y = (minHeight - font.lineHeight) / 2.0
        } else {
            y = textContainerInset.top
        }
        
        let width = rect.width - x * 2
        let placeholderRect = CGRect(x: x, y: y, width: width, height: font.lineHeight)

        if let attributedPlaceholder = attributedPlaceholder {
            attributedPlaceholder.draw(in: placeholderRect)
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = textAlignment
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: placeholderColor,
                .paragraphStyle: paragraphStyle
            ]
            placeholder?.draw(in: placeholderRect, withAttributes: attributes)
        }
    }

    // MARK: - Notifications
    @objc private func textDidChangeNotification() {
        setNeedsDisplay() // 👈【核心修复】强制重绘，使 placeholder 在输入时消失或退格为空时出现
        enforceMaxLengthIfNeeded()
        recalcHeightAsync()
        growingTextDidChange?(self)
    }

    @objc private func textDidEndEditingNotification() {
        if trimWhiteSpaceWhenEndEditing {
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        enforceMaxLengthIfNeeded()
        recalcHeightAsync()
    }
    
    private func enforceMaxLengthIfNeeded() {
        guard maxLength > 0 else { return }
        guard markedTextRange == nil else { return } // 拼音输入法高亮阶段不截断

        // 优化点：使用 Swift 原生的 count，避免 NSString 长度将 1 个 Emoji 算作 2 个字符的问题
        if text.count > maxLength {
            text = String(text.prefix(maxLength))
            undoManager?.removeAllActions()
        }
    }
}
