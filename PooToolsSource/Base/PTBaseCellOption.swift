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

public protocol PTCellBindable: PTAnyCellBindable {
    associatedtype ModelType
    func bind(model: ModelType)
}

public protocol PTAnyCellBindable {
    func pt_bindAny(_ model: Any)
}

public extension PTCellBindable {
    
    func pt_bindAny(_ model: Any) {
        guard let model = model as? ModelType else { return }
        bind(model: model)
    }
}

@objcMembers
open class PTBaseNormalCell: UICollectionViewCell,@MainActor PTCellRegisterable {
    
    public var isStaticCell:Bool = false {
        didSet {
            layer.shouldRasterize = isStaticCell
        }
    }
    
    override public init(frame:CGRect) {
        super.init(frame: frame)
        setupBaseCell()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBaseCell()
    }

    private func setupBaseCell() {
        isUserInteractionEnabled = true
        contentView.isOpaque = true
        layer.shouldRasterize = isStaticCell
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    open class func cellSize() -> CGSize {
        CGSize(width: 1, height: 1)
    }
    
    // ✅ 标准 reuseID（统一入口）
    open class var reuseID: String {
        String(describing: self)
    }

    // ✅ 保留你的 API（兼容旧代码）
    open class func cellIdentifier() -> String {
        reuseID
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
    public var cellCanSwipe: Bool = false {
        didSet {
            guard oldValue != cellCanSwipe else { return }
            if cellCanSwipe {
                installSwipeGesture()
            } else {
                closeActions(animated: false)
                removeSwipeGestures()
            }
        }
    }
    
    public let contentContainer = UIView()
    private let actionContainer = UIView()
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gesture.delegate = self
        return gesture
    }()
    private var tapGesture: UITapGestureRecognizer?

    private var contentOffsetX: CGFloat = 0
    private let actionWidth: CGFloat = 80
    private var leftActionButtons: [PTActionLayoutButton] = []
    private var rightActionButtons: [PTActionLayoutButton] = []

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSwipeUI()
    }

    private func setupSwipeUI() {
        // 操作按钮放在内容视图下方，内容视图只负责平移显示。
        contentView.addSubview(actionContainer)
        actionContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentContainer.backgroundColor = .white
        contentView.addSubview(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    public func configureLeftActions(_ actions: [PTSwipeAction]) {
        closeActions(animated: false)
        leftActionButtons.forEach { $0.removeFromSuperview() }
        leftActionButtons.removeAll()
        addButtons(actions, isLeft: true)
        setNeedsLayout()
    }

    public func configureRightActions(_ actions: [PTSwipeAction]) {
        closeActions(animated: false)
        rightActionButtons.forEach { $0.removeFromSuperview() }
        rightActionButtons.removeAll()
        addButtons(actions, isLeft: false)
        setNeedsLayout()
    }

    /// 添加一组滑动操作按钮。
    public func addButtons(_ actions: [PTSwipeAction], isLeft: Bool) {
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
            button.addActionHandlers(handler: { [weak self] sender in
                action.handler?(sender)
                self?.closeActions(animated: true)
            })
            actionContainer.addSubview(button)
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

    private var leftActionWidth: CGFloat {
        CGFloat(leftActionButtons.count) * actionWidth
    }

    private var rightActionWidth: CGFloat {
        CGFloat(rightActionButtons.count) * actionWidth
    }

    private func installSwipeGesture() {
        guard panGesture.view == nil else { return }
        contentView.addGestureRecognizer(panGesture)
    }

    private func removeSwipeGestures() {
        if let tapGesture {
            contentView.removeGestureRecognizer(tapGesture)
            self.tapGesture = nil
        }
        contentView.removeGestureRecognizer(panGesture)
    }

    private func addCloseGestureIfNeeded() {
        guard tapGesture == nil else { return }
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleCloseTap))
        tapGesture = gesture
        contentView.addGestureRecognizer(gesture)
    }

    private func removeCloseGesture() {
        guard let tapGesture else { return }
        contentView.removeGestureRecognizer(tapGesture)
        self.tapGesture = nil
    }

    @objc private func handleCloseTap() {
        closeActions(animated: true)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: contentView)

        switch gesture.state {
        case .began:
            UIView.performWithoutAnimation {
                contentContainer.layer.removeAllAnimations()
            }
            panStartOffset = contentOffsetX
            addCloseGestureIfNeeded()
        case .changed:
            setContentOffset(panStartOffset + translation.x, animated: false)
        case .ended, .cancelled, .failed:
            let proposedOffset = panStartOffset + translation.x
            let velocity = gesture.velocity(in: contentView).x
            finishPan(proposedOffset: proposedOffset, velocity: velocity)
        default:
            break
        }
    }

    private var panStartOffset: CGFloat = 0

    private func finishPan(proposedOffset: CGFloat, velocity: CGFloat) {
        let velocityThreshold: CGFloat = 300
        if velocity < -velocityThreshold, rightActionWidth > 0 {
            openRightActions()
        } else if velocity > velocityThreshold, leftActionWidth > 0 {
            openLeftActions()
        } else if proposedOffset > leftActionWidth / 2, leftActionWidth > 0 {
            openLeftActions()
        } else if proposedOffset < -rightActionWidth / 2, rightActionWidth > 0 {
            openRightActions()
        } else {
            closeActions(animated: true)
        }
    }

    private func setContentOffset(_ offset: CGFloat, animated: Bool) {
        let safeOffset = offset.isFinite ? offset : 0
        let clampedOffset = max(-rightActionWidth, min(safeOffset, leftActionWidth))
        contentOffsetX = clampedOffset

        let updates = {
            self.contentContainer.transform = CGAffineTransform(translationX: clampedOffset, y: 0)
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: updates)
        } else {
            UIView.performWithoutAnimation(updates)
        }

        if abs(clampedOffset) < 0.5 {
            removeCloseGesture()
        } else {
            addCloseGestureIfNeeded()
        }
    }

    private func openLeftActions() {
        guard leftActionWidth > 0 else {
            closeActions(animated: true)
            return
        }
        setContentOffset(leftActionWidth, animated: true)
    }

    private func openRightActions() {
        guard rightActionWidth > 0 else {
            closeActions(animated: true)
            return
        }
        setContentOffset(-rightActionWidth, animated: true)
    }

    public func closeActions(animated: Bool) {
        setContentOffset(0, animated: animated)
    }

    /// 清理两侧按钮，供复用和重新绑定时使用。
    public func resetSwipeActions() {
        closeActions(animated: false)
        leftActionButtons.forEach { $0.removeFromSuperview() }
        rightActionButtons.forEach { $0.removeFromSuperview() }
        leftActionButtons.removeAll()
        rightActionButtons.removeAll()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        resetSwipeActions()
        cellCanSwipe = false
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSwipeUI()
    }
}

extension PTBaseSwipeCell: UIGestureRecognizerDelegate {
    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = pan.velocity(in: contentView)
            return abs(velocity.x) > abs(velocity.y)
        }
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === panGesture else { return false }
        return !(otherGestureRecognizer.view is UICollectionView)
    }
}
