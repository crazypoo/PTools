//
//  PTMentSheetButtomView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/31.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public class PTMenuSheetButtonView: UIView {
    public enum Direction {
        case up, down, left, right
    }
    
    public enum State {
        case opened, closed, animating
    }
    
    // MARK: - UI properties
    private var arrowButton: PTMenuSheetArrowButton!
    private var separatorView: UIView!
    private var itemsButtons: [UIButton] = []
    
    // MARK: - Public properties
    public private(set) var direction: Direction
    public private(set) var state: State = .closed
    public var animationDuration: TimeInterval = 0.2 {
        didSet { arrowButton.animationDuration = animationDuration }
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
    public var isSeparatorHidden: Bool = false      { didSet { separatorView.isHidden = isSeparatorHidden } }
    public var separatorColor: UIColor = .black     { didSet { separatorView.backgroundColor = separatorColor } }
    public var separatorInset: CGFloat = 8          { didSet { setNeedsLayout() } }
    public var separatorWidth: CGFloat = 1          { didSet { setNeedsLayout() } }
    
    private var baseSize: CGSize = .zero
    private var firstLayout = true
    
    // MARK: - Init
    public init(frame: CGRect, direction: Direction = .right, items: [PTMenuSheetButtonItems]) {
        self.direction = direction
        self.baseSize = frame.size
        super.init(frame: frame)
        setupUI()
        setupButtons(with: items)
    }
    
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    public override func layoutSubviews() {
        super.layoutSubviews()
        if firstLayout {
            updateLayoutForCurrentState()
            showCloseArrow()
            firstLayout = false
        }
    }

    // MARK: - Public API
    public func open() {
        guard state == .closed else { return }
        state = .animating
        
        showOpenArrow()
        itemsButtons.forEach { $0.isHidden = false }
        
        // 关键点：展开前根据方向设置锚点
        applyAnchorPoint(for: direction)
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut], animations: {
            self.itemsButtons.forEach { $0.alpha = 1 }
            self.updateFrame(isOpening: true)
            self.layoutIfNeeded()
        }) { _ in
            self.state = .opened
            self.impactHapticFeedback()
        }
    }
    
    public func close() {
        guard state == .opened else { return }
        state = .animating
        
        showCloseArrow()
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut], animations: {
            self.itemsButtons.forEach { $0.alpha = 0 }
            self.updateFrame(isOpening: false)
            self.layoutIfNeeded()
        }) { _ in
            self.itemsButtons.forEach { $0.isHidden = true }
            self.state = .closed
            self.impactHapticFeedback()
        }
    }

    // MARK: - Private Layout Logic
    
    /// 根据方向动态设置锚点，确保动画从正确边缘开始
    private func applyAnchorPoint(for direction: Direction) {
        let anchor: CGPoint
        switch direction {
        case .up:    anchor = CGPoint(x: 0.5, y: 1.0) // 底部固定，向上长
        case .down:  anchor = CGPoint(x: 0.5, y: 0.0) // 顶部固定，向下长
        case .left:  anchor = CGPoint(x: 1.0, y: 0.5) // 右侧固定，向左长
        case .right: anchor = CGPoint(x: 0.0, y: 0.5) // 左侧固定，向右长
        }
        
        let oldFrame = frame
        layer.anchorPoint = anchor
        frame = oldFrame // 重新赋值 frame 以补偿锚点变更带来的位移
    }

    private func updateFrame(isOpening: Bool) {
        var newSize = baseSize
        if isOpening {
            let extraHeight = itemsButtons.reduce(0) { $0 + $1.frame.height }
            let extraWidth = itemsButtons.reduce(0) { $0 + $1.frame.width }
            
            if direction == .up || direction == .down {
                newSize.height += extraHeight
            } else {
                newSize.width += extraWidth
            }
        }
        // 更新 bounds 而不是 frame，配合锚点实现平滑缩放
        self.bounds.size = newSize
        updateSubviewsLayout()
    }

    private func updateSubviewsLayout() {
        // 无论方向如何，arrowButton 始终占据基础尺寸的那一块区域
        // 在 .up 或 .left 时，它会因为 bounds 的增加而在视觉上保持在“末端”
        let arrowFrame: CGRect
        switch direction {
        case .up:    arrowFrame = CGRect(x: 0, y: bounds.height - baseSize.height, width: baseSize.width, height: baseSize.height)
        case .down:  arrowFrame = CGRect(x: 0, y: 0, width: baseSize.width, height: baseSize.height)
        case .left:  arrowFrame = CGRect(x: bounds.width - baseSize.width, y: 0, width: baseSize.width, height: baseSize.height)
        case .right: arrowFrame = CGRect(x: 0, y: 0, width: baseSize.width, height: baseSize.height)
        }
        arrowButton.frame = arrowFrame
        
        // 更新分隔线
        updateSeparator(arrowFrame: arrowFrame)
        
        // 更新 Items
        updateItemsLayout(arrowFrame: arrowFrame)
    }

    private func updateSeparator(arrowFrame: CGRect) {
        switch direction {
        case .up:    separatorView.frame = CGRect(x: separatorInset, y: arrowFrame.minY - separatorWidth, width: bounds.width - separatorInset*2, height: separatorWidth)
        case .down:  separatorView.frame = CGRect(x: separatorInset, y: arrowFrame.maxY, width: bounds.width - separatorInset*2, height: separatorWidth)
        case .left:  separatorView.frame = CGRect(x: arrowFrame.minX - separatorWidth, y: separatorInset, width: separatorWidth, height: bounds.height - separatorInset*2)
        case .right: separatorView.frame = CGRect(x: arrowFrame.maxX, y: separatorInset, width: separatorWidth, height: bounds.height - separatorInset*2)
        }
    }

    private func updateItemsLayout(arrowFrame: CGRect) {
        var lastOrigin: CGPoint = .zero
        
        // 初始位置设置
        switch direction {
        case .up:    lastOrigin = .zero // 从顶部开始排
        case .down:  lastOrigin = CGPoint(x: 0, y: arrowFrame.maxY)
        case .left:  lastOrigin = .zero
        case .right: lastOrigin = CGPoint(x: arrowFrame.maxX, y: 0)
        }

        for button in itemsButtons {
            let w = button.frame.width == 0 ? baseSize.width : button.frame.width
            let h = button.frame.height == 0 ? baseSize.height : button.frame.height
            button.frame = CGRect(origin: lastOrigin, size: CGSize(width: w, height: h))
            
            if direction == .up || direction == .down {
                lastOrigin.y += h
            } else {
                lastOrigin.x += w
            }
        }
    }
    
    // MARK: - UI Setup (省略基础 setupUI 和 setupButtons，保持逻辑一致)
    private func setupUI() {
        clipsToBounds = true
        arrowButton = PTMenuSheetArrowButton()
        arrowButton.addTarget(self, action: #selector(arrowTapped), for: .touchUpInside)
        addSubview(arrowButton)
        
        separatorView = UIView()
        separatorView.backgroundColor = separatorColor
        addSubview(separatorView)
    }
    
    @objc private func arrowTapped() {
        state == .opened ? close() : open()
    }

    private func setupButtons(with items: [PTMenuSheetButtonItems]) {
        items.forEach { item in
            let button = UIButton(type: .custom)
            button.alpha = 0
            button.isHidden = true
            
            // 配置代码（保持你之前的 Configuration 逻辑...）
            var config = UIButton.Configuration.plain()
            config.image = item.image
            if let title = item.attributedTitle { config.attributedTitle = AttributedString(title) }
            button.configuration = config
            
            button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            // 绑定 item 到 button (可以使用运行时或自定义子类，此处简化逻辑)
            addSubview(button)
            itemsButtons.append(button)
        }
    }
    
    @objc private func itemTapped(_ sender: UIButton) {
        // 执行对应 item 的 action
        if closeOnAction { close() }
    }
    
    private func updateLayoutForCurrentState() {
        updateFrame(isOpening: state == .opened)
    }

    private func showOpenArrow() {
        arrowButton.isArrowsHidden = openImage != nil
        if openImage != nil { arrowButton.setImage(openImage, for: .normal) }
        else {
            switch direction {
            case .up: arrowButton.showDownArrow()
            case .down: arrowButton.showUpArrow()
            case .left: arrowButton.showRightArrow()
            case .right: arrowButton.showLeftArrow()
            }
        }
    }

    private func showCloseArrow() {
        arrowButton.isArrowsHidden = closeImage != nil
        if closeImage != nil { arrowButton.setImage(closeImage, for: .normal) }
        else {
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
