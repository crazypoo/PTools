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
    public var isSeparatorHidden: Bool = false {
        didSet { updateSeparatorVisibility() }
    }
    public var separatorColor: UIColor = .black {
        didSet { separatorView.backgroundColor = separatorColor }
    }
    public var separatorInset: CGFloat = 8 {
        didSet { updateSeparatorConstraints() }
    }
    public var separatorWidth: CGFloat = 1 {
        didSet { updateSeparatorConstraints() }
    }
    
    private var baseSize: CGSize
    
    // MARK: - Init
    public init(baseSize: CGSize, direction: Direction = .right, items: [PTMenuSheetButtonItems]) {
        self.direction = direction
        self.baseSize = baseSize
        super.init(frame: CGRect(origin: .zero, size: baseSize))
        
        setupUI()
        setupButtons(with: items)
        setupLayoutDirection()
        
        // 初始状态为关闭
        close(animated: false)
    }
    
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Public API
    public func open() {
        guard state == .closed else { return }
        state = .animating
        
        showOpenArrow()
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut], animations: {
            self.itemsButtons.forEach {
                $0.isHidden = false
                $0.alpha = 1
            }
            self.separatorContainer.isHidden = self.isSeparatorHidden
            self.layoutIfNeeded() // 触发 AutoLayout 动画
        }) { _ in
            self.state = .opened
            self.impactHapticFeedback()
        }
    }
    
    public func close(animated: Bool = true) {
        guard state == .opened || !animated else { return }
        if animated { state = .animating }
        
        showCloseArrow()
        
        let closeActions = {
            self.itemsButtons.forEach {
                $0.isHidden = true
                $0.alpha = 0
            }
            self.separatorContainer.isHidden = true
            self.layoutIfNeeded() // 触发 AutoLayout 动画
        }
        
        if animated {
            UIView.animate(withDuration: animationDuration, delay: 0, options: [.curveEaseInOut], animations: closeActions) { _ in
                self.state = .closed
                self.impactHapticFeedback()
            }
        } else {
            closeActions()
            self.state = .closed
        }
    }

    // MARK: - UI Setup Logic
    private func setupUI() {
        clipsToBounds = true
        
        // 1. 初始化 StackViews
        mainStackView = UIStackView()
        mainStackView.alignment = .center
        mainStackView.distribution = .fill
        mainStackView.spacing = 0
        addSubview(mainStackView)
        
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        itemsStackView = UIStackView()
        itemsStackView.distribution = .fillEqually
        itemsStackView.spacing = 0
        
        // 2. 初始化 ArrowButton
        arrowButton = PTMenuSheetArrowButton(frame: CGRect(origin: .zero, size: baseSize))
        arrowButton.addTarget(self, action: #selector(arrowTapped), for: .touchUpInside)
        arrowButton.snp.makeConstraints { make in
            make.width.equalTo(baseSize.width)
            make.height.equalTo(baseSize.height)
        }
        
        // 3. 初始化 Separator
        separatorContainer = UIView()
        separatorView = UIView()
        separatorView.backgroundColor = separatorColor
        separatorContainer.addSubview(separatorView)
        updateSeparatorConstraints()
    }
    
    private func setupLayoutDirection() {
        // 根据方向配置 StackView 的轴向和子视图排列顺序
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
        
        // 重新布局分隔线
        separatorContainer.snp.remakeConstraints { make in
            if isVertical {
                make.height.equalTo(separatorWidth)
                make.width.equalTo(baseSize.width)
            } else {
                make.width.equalTo(separatorWidth)
                make.height.equalTo(baseSize.height)
            }
        }
        
        separatorView.snp.remakeConstraints { make in
            if isVertical {
                make.leading.trailing.equalToSuperview().inset(separatorInset)
                make.top.bottom.equalToSuperview()
            } else {
                make.top.bottom.equalToSuperview().inset(separatorInset)
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
            let button = UIButton(type: .custom)
            button.alpha = 0
            button.isHidden = true
            
            var config = UIButton.Configuration.plain()
            config.image = item.image
            if let title = item.attributedTitle { config.attributedTitle = AttributedString(title) }
            button.configuration = config
            
            button.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            
            button.snp.makeConstraints { make in
                make.width.equalTo(baseSize.width)
                make.height.equalTo(baseSize.height)
            }
            
            itemsStackView.addArrangedSubview(button)
            itemsButtons.append(button)
        }
    }
    
    // MARK: - Actions
    @objc private func arrowTapped() {
        state == .opened ? close() : open()
    }
    
    @objc private func itemTapped(_ sender: UIButton) {
        if closeOnAction { close() }
    }

    // MARK: - Helpers
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
