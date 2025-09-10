//
//  PTBaseCellOption.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

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
    public var name:String = ""
    public var nameColor:DynamicColor = .black
    public var nameFont:UIFont = .appfont(size: 14)
    public var image:Any? = nil
    public var imageSize:CGSize = .init(width: 24, height: 24)
    public var contentSpacing:CGFloat = 4
    public var backgroundColor:DynamicColor = .clear
    public var handler:((PTActionLayoutButton)->Void)? = nil
    
    public init(name: String,
                image: Any? = nil,
                imageSize:CGSize = .init(width: 24, height: 24),
                nameColor:DynamicColor = .black,
                nameFont:UIFont = .appfont(size: 14),
                contentSpacing:CGFloat = 4,
                backgroundColor:DynamicColor = .clear,
                handler: ((PTActionLayoutButton) -> Void)? = nil) {
        self.name = name
        self.nameColor = nameColor
        self.nameFont = nameFont
        self.image = image
        self.backgroundColor = backgroundColor
        self.handler = handler
        self.imageSize = imageSize
        self.contentSpacing = contentSpacing
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
                                if offsetX < 0 {
                                    offsetX -= CGFloat(self.rightActionButtons.count) * self.actionWidth
                                } else {
                                    offsetX += CGFloat(self.leftActionButtons.count) * self.actionWidth
                                }
                            }
                            let maxLeft = CGFloat(self.leftActionButtons.count) * self.actionWidth
                            let maxRight = CGFloat(self.rightActionButtons.count) * self.actionWidth
                            offsetX = max(-maxRight, min(offsetX, maxLeft))
                            self.contentLeadingConstraint?.update(offset: offsetX)
                            self.layoutIfNeeded()   // 🔥 必須要這個才能看到移動效果
                        case .ended, .cancelled:
                            let threshold: CGFloat = 40
                            if translation.x < -threshold {
                                self.openRightActions()
                            } else if translation.x > threshold {
                                self.openLeftActions()
                            } else {
                                self.closeActions(animated: true)
                            }
                        default:
                            break
                        }
                    }
                }
                panGesture.delegate = self
                
                let tap = UITapGestureRecognizer { sender in
                    self.closeActions(animated: true)
                }
                self.contentView.addGestureRecognizers([tap,panGesture])
            } else {
                self.closeActions(animated: true)
                self.contentView.removeGestureRecognizers()
            }
        }
    }
    
    public let contentContainer = UIView()
    private let actionContainer = UIView()
    
    private var panGesture: UIPanGestureRecognizer!
    private var isOpen = false
    private let actionWidth: CGFloat = 80
    private var leftActionButtons: [PTActionLayoutButton] = []
    private var rightActionButtons: [PTActionLayoutButton] = []
    // SnapKit 的 leading 約束
    private var contentLeadingConstraint: Constraint?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Action container 在底層
        contentView.addSubview(actionContainer)
        actionContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Content container 在上層
        contentContainer.backgroundColor = .white
        contentView.addSubview(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.equalToSuperview()
            contentLeadingConstraint = make.leading.equalToSuperview().constraint
            make.trailing.equalToSuperview()
        }
    }
    
    public func configureLeftActions(_ actions: [PTSwipeAction]) {
        leftActionButtons.forEach { $0.removeFromSuperview() }
        leftActionButtons.removeAll()
        addButtons(actions, isLeft: true)
        setNeedsLayout()
    }

    public func configureRightActions(_ actions: [PTSwipeAction]) {
        rightActionButtons.forEach { $0.removeFromSuperview() }
        rightActionButtons.removeAll()
        addButtons(actions, isLeft: false)
        setNeedsLayout()
    }

    /// 配置 Action 按鈕
    public func addButtons(_ actions: [PTSwipeAction],isLeft: Bool) {
        // 建立新按鈕
        for (index, action) in actions.enumerated() {
            let button = PTActionLayoutButton()
            button.layoutStyle = .upImageDownTitle
            button.midSpacing = action.contentSpacing
            button.imageSize = action.imageSize
            button.setTitle(action.name, state: .normal)
            button.setBackgroundColor(action.backgroundColor, state: .normal)
            button.setTitleColor(action.nameColor, state: .normal)
            button.setImage(action.image, state: .normal)
            button.setTitleFont(action.nameFont, state: .normal)
            button.tag = index
            button.addActionHandlers(handler: { sender in
                action.handler?(sender)
                self.closeActions(animated: true)
            })
            actionContainer.addSubview(button)
            // SnapKit 排列
            button.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.width.equalTo(actionWidth)
                if isLeft {
                    make.leading.equalToSuperview().offset(CGFloat(index) * actionWidth)
                } else {
                    make.trailing.equalToSuperview().offset(-CGFloat(index) * actionWidth)
                }
            }
            if isLeft {
                leftActionButtons.append(button)
            } else {
                rightActionButtons.append(button)
            }
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
    }
            
    private func openLeftActions() {
        let totalWidth = CGFloat(leftActionButtons.count) * actionWidth
        contentLeadingConstraint?.update(offset: totalWidth)
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
        isOpen = true
    }

    private func openRightActions() {
        let totalWidth = CGFloat(rightActionButtons.count) * actionWidth
        contentLeadingConstraint?.update(offset: -totalWidth)
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
        isOpen = true
    }
    
    public func closeActions(animated: Bool) {
        contentLeadingConstraint?.update(offset: 0)
        let animations = { self.layoutIfNeeded() }
        animated ? UIView.animate(withDuration: 0.25, animations: animations) : animations()
        isOpen = false
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PTBaseSwipeCell: UIGestureRecognizerDelegate {
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = pan.velocity(in: contentView)
            return abs(velocity.x) > abs(velocity.y) // 只有橫向才開始
        }
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
