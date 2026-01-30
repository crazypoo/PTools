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
    open var placeHolderLROffset: CGFloat = 10 { didSet { setNeedsDisplay() } }

    // MARK: - Private
    private var currentHeight: CGFloat = 0
    private var isCalculatingHeight = false   // 👈 防止重入

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
        contentMode = .redraw
        setupObservers()
        currentHeight = minHeight   // ✅ 初始兜底
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
        // ❌ 这里不再算高度（iOS 17 雷区）
        setNeedsDisplay()
    }

    // MARK: - Height
    private func recalcHeightAsync() {
        guard !isCalculatingHeight else { return }
        isCalculatingHeight = true

        DispatchQueue.main.async { [weak self] in
            self?.recalcHeight()
            self?.isCalculatingHeight = false
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

        // 🔴 关键：记录“之前是否可滚动”
        let wasScrollable = isScrollEnabled

        // 🔴 只在状态变化时切换
        if wasScrollable != shouldScroll {
            isScrollEnabled = shouldScroll
            showsVerticalScrollIndicator = shouldScroll
        }

        guard abs(finalHeight - currentHeight) > 0.5 else { return }

        currentHeight = finalHeight
        invalidateIntrinsicContentSize()
        growingTextDidChangeHeight?(self, finalHeight)

        // ✅ 只在「刚刚变成可滚动」时滚到底
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
        let height = font.lineHeight
        let x = placeHolderLROffset
        let y = (rect.height - height) / 2
        let width = rect.width - x * 2
        let placeholderRect = CGRect(x: x, y: y, width: width, height: height)

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
        guard markedTextRange == nil else { return }

        let nsText = text as NSString
        if nsText.length > maxLength {
            text = nsText.substring(to: maxLength)
            undoManager?.removeAllActions()
        }
    }
}
