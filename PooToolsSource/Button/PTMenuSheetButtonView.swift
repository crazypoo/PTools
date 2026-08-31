//
//  PTMentSheetButtomView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/31.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

public class PTMenuSheetButtonView: UIView {
    public enum Direction {
        case up, down, left, right
    }
    
    public enum State {
        case opened, closed, animating
    }
    
    // MARK: - UI properties
    private var mainStackView: UIStackView!
    private var itemsStackView: UIStackView!
    private var arrowButton: PTMenuSheetArrowButton!
    private var separatorContainer: UIView!
    private var separatorView: UIView!
    private var itemsButtons: [PTMenuSheetItemButton] = []
    private var itemByButtonID: [ObjectIdentifier: PTMenuSheetButtonItems] = [:]
    
    // MARK: - Public properties
    public private(set) var direction: Direction
    public private(set) var state: State = .closed
    public var animationDuration: TimeInterval = 0.2 {
        didSet { arrowButton?.animationDuration = max(0, animationDuration) }
    }
    
    public var closeOnAction: Bool = false
    public var isHapticFeedback = true
    
    // Arrow Proxy Properties
    public var arrowInsets: UIEdgeInsets {
        get { arrowButton.arrowInsets }
        set { arrowButton.arrowInsets = newValue }
    }
    public var arrowWidth: CGFloat {
        get { arrowButton.arrowWidth }
        set { arrowButton.arrowWidth = newValue }
    }
    public var arrowColor: UIColor {
        get { arrowButton.arrowColor }
        set { arrowButton.arrowColor = newValue }
    }
    
    public var closeImage: UIImage?
    public var openImage: UIImage?
    
    // Separator
    public var isSeparatorHidden: Bool = false {
        didSet { updateSeparatorVisibility() }
    }
    public var separatorColor: UIColor = .black {
        didSet { separatorView?.backgroundColor = separatorColor }
    }
    public var separatorInset: CGFloat = 8 {
        didSet { updateSeparatorConstraints() }
    }
    public var separatorWidth: CGFloat = 1 {
        didSet { updateSeparatorConstraints() }
    }
    
    private var baseSize: CGSize
    private var transitionGeneration = 0
    
    // MARK: - Init
    public init(baseSize: CGSize, direction: Direction = .right, items: [PTMenuSheetButtonItems]) {
        self.direction = direction
        self.baseSize = CGSize(width: max(0, baseSize.width), height: max(0, baseSize.height))
        super.init(frame: CGRect(origin: .zero, size: self.baseSize))
        
        setupUI()
        setupButtons(with: items)
        setupLayoutDirection()
        
        transition(to: .closed, animated: false, force: true)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        direction = .right
        baseSize = .zero
        super.init(coder: aDecoder)
        baseSize = CGSize(width: max(0, bounds.width), height: max(0, bounds.height))
        setupUI()
        setupButtons(with: [])
        setupLayoutDirection()
        transition(to: .closed, animated: false, force: true)
    }
    
    // MARK: - Public API
    public func open() {
        transition(to: .opened, animated: true)
    }
    
    public func close(animated: Bool = true) {
        transition(to: .closed, animated: animated)
    }

    private func transition(to target: State, animated: Bool, force: Bool = false) {
        guard force || state != target else { return }

        transitionGeneration += 1
        let generation = transitionGeneration
        let safeDuration = max(0, animationDuration)
        let shouldAnimate = animated && safeDuration > 0 && !UIAccessibility.isReduceMotionEnabled

        if target == .opened {
            showOpenArrow()
            itemsButtons.forEach {
                $0.isHidden = false
                if !$0.isUserInteractionEnabled { $0.isUserInteractionEnabled = true }
            }
            separatorContainer.isHidden = isSeparatorHidden
        } else {
            showCloseArrow()
            if shouldAnimate {
                itemsButtons.forEach { $0.isHidden = false }
                separatorContainer.isHidden = false
            }
        }

        let animations = {
            self.itemsButtons.forEach { $0.alpha = target == .opened ? 1 : 0 }
            self.separatorContainer.alpha = target == .opened && !self.isSeparatorHidden ? 1 : 0
            self.layoutIfNeeded()
        }

        let finish = { [weak self] in
            guard let self, self.transitionGeneration == generation else { return }
            if target == .closed {
                self.itemsButtons.forEach { $0.isHidden = true }
                self.separatorContainer.isHidden = true
            }
            self.state = target
            self.impactHapticFeedback()
        }

        if shouldAnimate {
            state = .animating
            UIView.animate(withDuration: safeDuration,
                           delay: 0,
                           options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction],
                           animations: animations) { _ in
                finish()
            }
        } else {
            state = target
            UIView.performWithoutAnimation(animations)
            finish()
        }
    }

    // MARK: - UI Setup Logic
    private func setupUI() {
        clipsToBounds = true
        
        mainStackView = UIStackView()
        mainStackView.alignment = .center
        mainStackView.distribution = .fill
        mainStackView.spacing = 0
        addSubview(mainStackView)
        
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        itemsStackView = UIStackView()
        itemsStackView.distribution = .fill
        itemsStackView.alignment = .fill
        itemsStackView.spacing = 0
        
        arrowButton = PTMenuSheetArrowButton(frame: CGRect(origin: .zero, size: baseSize))
        arrowButton.addTarget(self, action: #selector(arrowTapped), for: .touchUpInside)
        arrowButton.snp.makeConstraints { make in
            make.width.equalTo(baseSize.width)
            make.height.equalTo(baseSize.height)
        }
        
        separatorContainer = UIView()
        separatorView = UIView()
        separatorView.backgroundColor = separatorColor
        separatorContainer.addSubview(separatorView)
        updateSeparatorConstraints()
    }
    
    private func setupLayoutDirection() {
        let isVertical = (direction == .up || direction == .down)
        mainStackView.axis = isVertical ? .vertical : .horizontal
        itemsStackView.axis = isVertical ? .vertical : .horizontal
        
        switch direction {
        case .up:
            mainStackView.addArrangedSubview(itemsStackView)
            mainStackView.addArrangedSubview(separatorContainer)
            mainStackView.addArrangedSubview(arrowButton)
        case .down:
            mainStackView.addArrangedSubview(arrowButton)
            mainStackView.addArrangedSubview(separatorContainer)
            mainStackView.addArrangedSubview(itemsStackView)
        case .left:
            mainStackView.addArrangedSubview(itemsStackView)
            mainStackView.addArrangedSubview(separatorContainer)
            mainStackView.addArrangedSubview(arrowButton)
        case .right:
            mainStackView.addArrangedSubview(arrowButton)
            mainStackView.addArrangedSubview(separatorContainer)
            mainStackView.addArrangedSubview(itemsStackView)
        }
    }
    
    private func updateSeparatorConstraints() {
        let isVertical = (direction == .up || direction == .down)
        
        let safeSeparatorWidth = max(0, separatorWidth)
        let safeSeparatorInset = max(0, separatorInset)
        separatorContainer.snp.remakeConstraints { make in
            if isVertical {
                make.height.equalTo(safeSeparatorWidth)
                make.width.equalTo(baseSize.width)
            } else {
                make.width.equalTo(safeSeparatorWidth)
                make.height.equalTo(baseSize.height)
            }
        }

        separatorView.snp.remakeConstraints { make in
            if isVertical {
                make.leading.trailing.equalToSuperview().inset(safeSeparatorInset)
                make.top.bottom.equalToSuperview()
            } else {
                make.top.bottom.equalToSuperview().inset(safeSeparatorInset)
                make.leading.trailing.equalToSuperview()
            }
        }
    }
    
    private func updateSeparatorVisibility() {
        if state == .opened {
            separatorContainer.isHidden = isSeparatorHidden
        }
    }

    private func setupButtons(with items: [PTMenuSheetButtonItems]) {
        items.forEach { item in
            let button = PTMenuSheetItemButton(item: item)
            button.alpha = 0
            button.isHidden = true

            button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)

            let itemSize = item.size ?? baseSize
            button.snp.makeConstraints { make in
                make.width.equalTo(max(0, itemSize.width))
                make.height.equalTo(max(0, itemSize.height))
            }

            itemsStackView.addArrangedSubview(button)
            itemsButtons.append(button)
            itemByButtonID[ObjectIdentifier(button)] = item
        }
    }
    
    // MARK: - Actions
    @objc private func arrowTapped() {
        state == .opened ? close() : open()
    }
    
    @objc private func itemTapped(_ sender: UIButton) {
        if let item = itemByButtonID[ObjectIdentifier(sender)] {
            item.action(item)
        }
        if closeOnAction { close() }
    }

    // MARK: - Helpers
    private func showOpenArrow() {
        if let openImage {
            arrowButton.isArrowsHidden = true
            arrowButton.setImage(openImage, for: .normal)
            arrowButton.setImage(openImage, for: .highlighted)
        } else {
            arrowButton.setImage(nil, for: .normal)
            arrowButton.setImage(nil, for: .highlighted)
            arrowButton.isArrowsHidden = false
            switch direction {
            case .up: arrowButton.showDownArrow()
            case .down: arrowButton.showUpArrow()
            case .left: arrowButton.showRightArrow()
            case .right: arrowButton.showLeftArrow()
            }
        }
    }

    private func showCloseArrow() {
        if let closeImage {
            arrowButton.isArrowsHidden = true
            arrowButton.setImage(closeImage, for: .normal)
            arrowButton.setImage(closeImage, for: .highlighted)
        } else {
            arrowButton.setImage(nil, for: .normal)
            arrowButton.setImage(nil, for: .highlighted)
            arrowButton.isArrowsHidden = false
            switch direction {
            case .up: arrowButton.showUpArrow()
            case .down: arrowButton.showDownArrow()
            case .left: arrowButton.showLeftArrow()
            case .right: arrowButton.showRightArrow()
            }
        }
    }

    private func impactHapticFeedback() {
        if isHapticFeedback {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

private final class PTMenuSheetItemButton: UIButton {
    private let item: PTMenuSheetButtonItems
    private let contentImageView = UIImageView()
    private let contentTitleLabel = UILabel()

    init(item: PTMenuSheetButtonItems) {
        self.item = item
        super.init(frame: .zero)
        configureContent()
    }

    required init?(coder: NSCoder) {
        item = PTMenuSheetButtonItems()
        super.init(coder: coder)
        configureContent()
    }

    override var isHighlighted: Bool {
        didSet { updateContentForCurrentState() }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContent()
    }

    private func configureContent() {
        // Keep layout independent from deprecated UIButton edge-inset properties.
        // Mantenemos el diseño independiente de las propiedades de insets obsoletas de UIButton.
        // 使用独立内容视图布局，避免依赖已弃用的 UIButton 边距属性。
        addSubview(contentImageView)
        addSubview(contentTitleLabel)
        contentTitleLabel.numberOfLines = 0
        contentTitleLabel.textAlignment = item.titleAlignment
        contentImageView.contentMode = item.imageContentMode
        accessibilityIdentifier = item.identifier.isEmpty ? nil : item.identifier
        isAccessibilityElement = true
        updateContentForCurrentState()
    }

    private func updateContentForCurrentState() {
        let highlighted = isHighlighted
        contentImageView.image = highlighted ? (item.highlightedImage ?? item.image) : item.image
        contentTitleLabel.attributedText = highlighted ? (item.highlightedAttributedTitle ?? item.attributedTitle) : item.attributedTitle
        accessibilityLabel = (highlighted ? (item.highlightedAttributedTitle ?? item.attributedTitle) : item.attributedTitle)?.string
        setNeedsLayout()
    }

    private func layoutContent() {
        let contentInsets = normalizedInsets(item.contentEdgeInsets)
        let imageInsets = normalizedInsets(item.imageEdgeInsets)
        let titleInsets = normalizedInsets(item.titleEdgeInsets)
        let contentRect = bounds.inset(by: contentInsets)
        let availableSize = CGSize(width: max(0, contentRect.width), height: max(0, contentRect.height))

        let imageSize = contentImageView.image.map { _ in
            contentImageView.sizeThatFits(availableSize)
        } ?? .zero
        let titleSize = contentTitleLabel.attributedText.map { _ in
            contentTitleLabel.sizeThatFits(availableSize)
        } ?? .zero

        let imageTotalWidth = imageSize.width + imageInsets.left + imageInsets.right
        let titleTotalWidth = titleSize.width + titleInsets.left + titleInsets.right
        let groupWidth = imageTotalWidth + titleTotalWidth
        let groupX: CGFloat
        switch item.titleAlignment {
        case .left:
            groupX = contentRect.minX
        case .right:
            groupX = contentRect.maxX - groupWidth
        default:
            groupX = contentRect.midX - groupWidth / 2
        }

        var cursorX = groupX
        if imageSize != .zero {
            let imageY = contentRect.midY - (imageSize.height + imageInsets.top + imageInsets.bottom) / 2 + imageInsets.top
            contentImageView.frame = CGRect(x: cursorX + imageInsets.left,
                                            y: imageY,
                                            width: imageSize.width,
                                            height: imageSize.height)
            cursorX += imageTotalWidth
        } else {
            contentImageView.frame = .zero
        }

        if titleSize != .zero {
            let titleY = contentRect.midY - (titleSize.height + titleInsets.top + titleInsets.bottom) / 2 + titleInsets.top
            contentTitleLabel.frame = CGRect(x: cursorX + titleInsets.left,
                                             y: titleY,
                                             width: titleSize.width,
                                             height: titleSize.height)
        } else {
            contentTitleLabel.frame = .zero
        }
    }

    private func normalizedInsets(_ insets: UIEdgeInsets) -> UIEdgeInsets {
        UIEdgeInsets(top: max(0, insets.top),
                     left: max(0, insets.left),
                     bottom: max(0, insets.bottom),
                     right: max(0, insets.right))
    }
}
