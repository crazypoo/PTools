//
//  PTBaseCellOption.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
open class PTBaseNormalCell: UICollectionViewCell {
    override public init(frame:CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        contentView.isOpaque = true
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open class func cellSize() -> CGSize {
        CGSize(width: 1, height: 1)
    }
    
    open class func cellIdentifier() -> String {
        "\(type(of: self))"
    }
    
    open class func cellSizeByClass() -> NSNumber {
        NSNumber(value: true)
    }
    
    open class func cellSizeValue() -> NSValue {
        NSValue(cgSize: cellSize())
    }
}

/*
 SwipeCell
 */
public class PTSwipeAction:NSObject {
    var name:String = ""
    var image:Any? = nil
    var backgroundColor:DynamicColor = .clear
    var handler:((UIButton)->Void)? = nil
    
    init(name: String,
         image: Any? = nil,
         backgroundColor:DynamicColor = .clear,
         handler: ((UIButton) -> Void)? = nil) {
        self.name = name
        self.image = image
        self.backgroundColor = backgroundColor
        self.handler = handler
    }
}

open class PTBaseSwipeCell: PTBaseNormalCell {
        
    public var cellCanSwipe:Bool = false {
        didSet {
            // 加手勢
            if cellCanSwipe {
                panGesture = UIPanGestureRecognizer { sender in
                    if let gesture = sender as? UIPanGestureRecognizer {
                        let translation = gesture.translation(in: self.contentView)
                        switch gesture.state {
                        case .changed:
                            var offsetX = translation.x
                            
                            if self.isOpen {
                                // 已經打開時要考慮偏移（左或右）
                                if offsetX < 0 { // 左滑
                                    offsetX -= CGFloat(self.rightActionButtons.count) * self.actionWidth
                                } else { // 右滑
                                    offsetX += CGFloat(self.leftActionButtons.count) * self.actionWidth
                                }
                            }
                            
                            // 限制範圍：不能超過左右按鈕的總寬度
                            let maxLeft = CGFloat(self.leftActionButtons.count) * self.actionWidth
                            let maxRight = CGFloat(self.rightActionButtons.count) * self.actionWidth
                            offsetX = max(-maxRight, min(offsetX, maxLeft))
                            
                            self.contentContainer.transform = CGAffineTransform(translationX: offsetX, y: 0)
                            
                        case .ended, .cancelled:
                            let threshold: CGFloat = 40
                            if translation.x < -threshold { // 左滑
                                self.openRightActions()
                            } else if translation.x > threshold { // 右滑
                                self.openLeftActions()
                            } else {
                                self.closeActions(animated: true)
                            }
                            
                        default:
                            break
                        }
                    }
                }
                contentContainer.addGestureRecognizer(panGesture)
            }
        }
    }
    
    private let contentContainer = UIView()
    private let actionContainer = UIView()
    
    private var panGesture: UIPanGestureRecognizer!
    private var isOpen = false
    private let actionWidth: CGFloat = 80
    private var leftActionButtons: [UIButton] = []
    private var rightActionButtons: [UIButton] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Action container 在底層
        contentView.addSubview(actionContainer)
        actionContainer.frame = contentView.bounds
        
        // Content container 在上層
        contentContainer.backgroundColor = .white
        contentView.addSubview(contentContainer)
        contentContainer.frame = contentView.bounds
    }
    
    public func configureLeftActions(_ actions: [PTSwipeAction]) {
        leftActionButtons.forEach { $0.removeFromSuperview() }
        leftActionButtons.removeAll()
        addButtons(actions, isLeft: true)
    }

    public func configureRightActions(_ actions: [PTSwipeAction]) {
        rightActionButtons.forEach { $0.removeFromSuperview() }
        rightActionButtons.removeAll()
        addButtons(actions, isLeft: false)
    }

    /// 配置 Action 按鈕
    public func addButtons(_ actions: [PTSwipeAction],isLeft: Bool) {
        // 清除舊按鈕
        rightActionButtons.forEach { $0.removeFromSuperview() }
        leftActionButtons.forEach { $0.removeFromSuperview() }
        rightActionButtons.removeAll()
        leftActionButtons.removeAll()
        
        // 建立新按鈕
        for (index, action) in actions.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(action.name, for: .normal)
            button.backgroundColor = action.backgroundColor
            button.setTitleColor(.white, for: .normal)
            button.tag = index
            button.addActionHandlers(handler: { sender in
                action.handler?(sender)
                self.closeActions(animated: true)
            })
            actionContainer.addSubview(button)
            if isLeft {
                leftActionButtons.append(button)
            } else {
                rightActionButtons.append(button)
            }
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        actionContainer.frame = contentView.bounds
        contentContainer.frame = contentView.bounds
        
        // 左側按鈕排列（從左到右）
        for (i, button) in leftActionButtons.enumerated() {
            let x = CGFloat(i) * actionWidth
            button.frame = CGRect(x: x, y: 0, width: actionWidth, height: contentView.bounds.height)
        }
        
        // 右側按鈕排列（從右到左）
        for (i, button) in rightActionButtons.enumerated() {
            let x = contentView.bounds.width - CGFloat(rightActionButtons.count - i) * actionWidth
            button.frame = CGRect(x: x, y: 0, width: actionWidth, height: contentView.bounds.height)
        }
    }
            
    private func openLeftActions() {
        let totalWidth = CGFloat(leftActionButtons.count) * actionWidth
        UIView.animate(withDuration: 0.25) {
            self.contentContainer.transform = CGAffineTransform(translationX: totalWidth, y: 0)
        }
        isOpen = true
    }

    private func openRightActions() {
        let totalWidth = CGFloat(rightActionButtons.count) * actionWidth
        UIView.animate(withDuration: 0.25) {
            self.contentContainer.transform = CGAffineTransform(translationX: -totalWidth, y: 0)
        }
        isOpen = true
    }
    
    public func closeActions(animated: Bool) {
        let animations = {
            self.contentContainer.transform = .identity
        }
        animated ? UIView.animate(withDuration: 0.25, animations: animations) : animations()
        isOpen = false
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
