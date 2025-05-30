//
//  PTChatTypingIndicator.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/2.
//

import UIKit

public class PTChatTypingIndicator: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    // MARK: Open
    open var dotColor = PTChatConfig.share.dotColor {
        didSet {
          dots.forEach { $0.backgroundColor = dotColor }
        }
    }

    /// The `CABasicAnimation` applied when `isBounceEnabled` is TRUE to move the dot to the correct
    /// initial offset
    open var initialOffsetAnimationLayer: CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.byValue = -bounceOffset
        animation.duration = 0.5
        animation.isRemovedOnCompletion = true
        return animation
    }

    /// The `CABasicAnimation` applied when `isBounceEnabled` is TRUE
    public var bounceAnimationLayer: CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.translation.y")
        animation.toValue = -bounceOffset
        animation.fromValue = bounceOffset
        animation.duration = 0.5
        animation.repeatCount = .infinity
        animation.autoreverses = true
        return animation
    }

    /// The `CABasicAnimation` applied when `isFadeEnabled` is TRUE
    public var opacityAnimationLayer: CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.5
        animation.duration = 0.5
        animation.repeatCount = .infinity
        animation.autoreverses = true
        return animation
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = bounds
        stackView.spacing = bounds.width > 0 ? 5 : 0
    }

    // MARK: - Animation API
    /// Sets the state of the `TypingIndicator` to animating and applies animation layers
    public func startAnimating() {
        defer { isAnimating = true }
        guard !isAnimating else { return }
        var delay: TimeInterval = 0
        for dot in dots {
            let currentDelay = delay // 捕获当前的 delay 值
            PTGCDManager.gcdAfter(time: delay) { [weak self] in
                guard let self = self else { return }
                if self.isBounceEnabled {
                    dot.layer.add(self.initialOffsetAnimationLayer, forKey: AnimationKeys.offset)
                    let bounceLayer = self.bounceAnimationLayer
                    bounceLayer.timeOffset = currentDelay + 0.33
                    dot.layer.add(bounceLayer, forKey: AnimationKeys.bounce)
                }
                if self.isFadeEnabled {
                    dot.layer.add(self.opacityAnimationLayer, forKey: AnimationKeys.opacity)
                }
            }
            delay += 0.33
        }
    }

    /// Sets the state of the `TypingIndicator` to not animating and removes animation layers
    public func stopAnimating() {
        defer { isAnimating = false }
        guard isAnimating else { return }
        dots.forEach {
            $0.layer.removeAnimation(forKey: AnimationKeys.bounce)
            $0.layer.removeAnimation(forKey: AnimationKeys.opacity)
        }
    }

    /// The offset that each dot will transform by during the bounce animation
    public var bounceOffset: CGFloat = 2.5

    /// A flag that determines if the bounce animation is added in `startAnimating()`
    public var isBounceEnabled = false

    /// A flag that determines if the opacity animation is added in `startAnimating()`
    public var isFadeEnabled = true

    /// A flag indicating the animation state
    public private(set) var isAnimating = false

    // MARK: - Subviews

    public let stackView = UIStackView()

    public let dots: [PTChatBubbleCircle] = {
        [PTChatBubbleCircle(), PTChatBubbleCircle(), PTChatBubbleCircle()]
    }()

    // MARK: Private

    /// Keys for each animation layer
    private enum AnimationKeys {
        static let offset = "typingIndicator.offset"
        static let bounce = "typingIndicator.bounce"
        static let opacity = "typingIndicator.opacity"
    }

    /// Sets up the view
    private func setupView() {
        dots.forEach {
          $0.backgroundColor = dotColor
          $0.heightAnchor.constraint(equalTo: $0.widthAnchor).isActive = true
          stackView.addArrangedSubview($0)
        }
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        addSubview(stackView)
    }
}
