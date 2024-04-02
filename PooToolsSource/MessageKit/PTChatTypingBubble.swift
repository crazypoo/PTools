//
//  PTChatTypingBubble.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/2.
//

import UIKit

public class PTChatTypingBubble: UIView {
    
    public private(set) var isAnimating = false

    ///顯示正在輸入動畫
    public let typingIndicator = PTChatTypingIndicator()
    public let contentBubble = UIView()
    public let cornerBubble = PTChatBubbleCircle()
    public let tinyBubble = PTChatBubbleCircle()

    open var isPulseEnabled = true

    open override var backgroundColor: UIColor? {
        set {
            [contentBubble, cornerBubble, tinyBubble].forEach { $0.backgroundColor = newValue }
        }
        get {
            contentBubble.backgroundColor
        }
    }

    //MARK: - Animation Layers
    open var contentPulseAnimationLayer: CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = 1.04
        animation.duration = 1
        animation.repeatCount = .infinity
        animation.autoreverses = true
        return animation
    }

    open var circlePulseAnimationLayer: CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1
        animation.toValue = 1.1
        animation.duration = 0.5
        animation.repeatCount = .infinity
        animation.autoreverses = true
        return animation
    }

    private enum AnimationKeys {
        static let pulse = "typingBubble.pulse"
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    open func setupSubviews() {
        addSubview(tinyBubble)
        addSubview(cornerBubble)
        addSubview(contentBubble)
        contentBubble.addSubview(typingIndicator)
        backgroundColor = .white
    }

    open override func layoutSubviews() {
      super.layoutSubviews()

        // To maintain the iMessage like bubble the width:height ratio of the frame
        // must be close to 1.65

        // In order to prevent NaN crash when assigning the frame of the contentBubble
        guard bounds.width > 0, bounds.height > 0 else { return }

        let ratio = bounds.width / bounds.height
        let extraRightInset = bounds.width - 1.65 / ratio * bounds.width

        let tinyBubbleRadius: CGFloat = bounds.height / 6
        tinyBubble.frame = CGRect( x: 0, y: bounds.height - tinyBubbleRadius, width: tinyBubbleRadius, height: tinyBubbleRadius)

        let cornerBubbleRadius = tinyBubbleRadius * 2
        let offset: CGFloat = tinyBubbleRadius / 6
        cornerBubble.frame = CGRect( x: tinyBubbleRadius - offset, y: bounds.height - (1.5 * cornerBubbleRadius) + offset, width: cornerBubbleRadius, height: cornerBubbleRadius)

        let contentBubbleFrame = CGRect( x: tinyBubbleRadius + offset, y: 0, width: bounds.width - (tinyBubbleRadius + offset) - extraRightInset, height: bounds.height - (tinyBubbleRadius + offset))
        let contentBubbleFrameCornerRadius = contentBubbleFrame.height / 2

        contentBubble.frame = contentBubbleFrame
        contentBubble.layer.cornerRadius = contentBubbleFrameCornerRadius

        let insets = UIEdgeInsets( top: offset, left: contentBubbleFrameCornerRadius / 1.25, bottom: offset, right: contentBubbleFrameCornerRadius / 1.25)
        typingIndicator.frame = contentBubble.bounds.inset(by: insets)
    }

    open func startAnimating() {
        defer { isAnimating = true }
        guard !isAnimating else { return }
        typingIndicator.startAnimating()
        if isPulseEnabled {
            contentBubble.layer.add(contentPulseAnimationLayer, forKey: AnimationKeys.pulse)
            [cornerBubble, tinyBubble].forEach { $0.layer.add(circlePulseAnimationLayer, forKey: AnimationKeys.pulse) }
        }
    }

    open func stopAnimating() {
        defer { isAnimating = false }
        guard isAnimating else { return }
        typingIndicator.stopAnimating()
        [contentBubble, cornerBubble, tinyBubble].forEach { $0.layer.removeAnimation(forKey: AnimationKeys.pulse) }
    }
}
