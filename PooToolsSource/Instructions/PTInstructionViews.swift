// English: Lightweight mask and content views for the native instruction overlay.
// Español: Vistas ligeras de máscara y contenido para el overlay de instrucciones nativo.
// 中文：原生引导浮层使用的轻量遮罩和内容视图。

import UIKit
#if SWIFT_PACKAGE
import PToolsOverlay
#endif

@MainActor
final class PTInstructionMaskView: UIView {
    private let borderLayer = CAShapeLayer()
    private var currentPath = UIBezierPath()
    private var cutoutRects: [CGRect] = []
    private var spotlight = PTInstructionSpotlight()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
        backgroundColor = .black
        layer.mask = CAShapeLayer()
        borderLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(borderLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func update(rects: [CGRect], spotlight: PTInstructionSpotlight, animated: Bool) {
        cutoutRects = rects
        self.spotlight = spotlight
        backgroundColor = spotlight.color

        let path = UIBezierPath(rect: bounds)
        for rect in rects {
            let cutout = makePath(for: rect.inset(by: spotlight.insets), shape: spotlight.shape)
            path.append(cutout)
        }
        path.usesEvenOddFillRule = true
        currentPath = path

        let mask = layer.mask as? CAShapeLayer
        mask?.fillRule = .evenOdd
        if animated, !UIAccessibility.isReduceMotionEnabled {
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = mask?.path
            animation.toValue = path.cgPath
            animation.duration = 0.18
            mask?.add(animation, forKey: "pt_instruction_path")
        }
        mask?.path = path.cgPath

        borderLayer.path = makeBorderPath(rects: rects, spotlight: spotlight).cgPath
        borderLayer.strokeColor = spotlight.borderColor?.cgColor
        borderLayer.lineWidth = spotlight.borderWidth
    }

    func containsCutout(_ point: CGPoint) -> Bool {
        cutoutRects.contains { $0.contains(point) }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let mask = layer.mask as? CAShapeLayer
        mask?.frame = bounds
        borderLayer.frame = bounds
        if !currentPath.isEmpty {
            let path = UIBezierPath(rect: bounds)
            for rect in cutoutRects {
                path.append(makePath(for: rect.inset(by: spotlight.insets), shape: spotlight.shape))
            }
            path.usesEvenOddFillRule = true
            mask?.path = path.cgPath
        }
    }

    private func makeBorderPath(rects: [CGRect], spotlight: PTInstructionSpotlight) -> UIBezierPath {
        let path = UIBezierPath()
        for rect in rects {
            path.append(makePath(for: rect.inset(by: spotlight.insets), shape: spotlight.shape))
        }
        return path
    }

    private func makePath(for rect: CGRect, shape: PTInstructionCutoutShape) -> UIBezierPath {
        switch shape {
        case .rectangle:
            return UIBezierPath(rect: rect)
        case let .roundedRectangle(cornerRadius):
            return UIBezierPath(roundedRect: rect, cornerRadius: min(cornerRadius, min(rect.width, rect.height) / 2))
        case .capsule:
            return UIBezierPath(roundedRect: rect, cornerRadius: min(rect.width, rect.height) / 2)
        case .circle:
            let side = min(rect.width, rect.height)
            return UIBezierPath(ovalIn: CGRect(x: rect.midX - side / 2, y: rect.midY - side / 2, width: side, height: side))
        case .oval:
            return UIBezierPath(ovalIn: rect)
        case let .custom(provider):
            return provider(rect) ?? UIBezierPath(rect: rect)
        }
    }
}

@MainActor
final class PTInstructionCardView: UIView {
    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?
    var onSkip: (() -> Void)?

    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionStack = UIStackView()
    private let contentStack = UIStackView()
    private let arrowLayer = CAShapeLayer()
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var topConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!
    private var arrowPoint: CGPoint?
    private var arrowPlacement: PTPopoverPlacement = .automatic
    private var arrowAppearance = PTArrowAppearance()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func configure(message: PTInstructionMessage, configuration: PTInstructionConfiguration) {
        apply(configuration: configuration)
        titleLabel.text = message.title
        titleLabel.isHidden = message.title == nil
        messageLabel.text = message.message

        actionStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if let previousTitle = message.previousTitle {
            let button = makeButton(title: previousTitle,
                                    color: configuration.messageColor,
                                    identifier: "pt.instructions.previous",
                                    action: { [weak self] in self?.onPrevious?() })
            actionStack.addArrangedSubview(button)
        }
        if let skipTitle = message.skipTitle {
            let button = makeButton(title: skipTitle,
                                    color: configuration.messageColor,
                                    identifier: "pt.instructions.skip",
                                    action: { [weak self] in self?.onSkip?() })
            actionStack.addArrangedSubview(button)
        }
        let nextButton = makeButton(title: message.nextTitle,
                                    color: configuration.accentColor,
                                    identifier: "pt.instructions.next",
                                    action: { [weak self] in self?.onNext?() })
        actionStack.addArrangedSubview(nextButton)
        setNeedsLayout()
    }

    func apply(configuration: PTInstructionConfiguration) {
        backgroundColor = configuration.cardColor
        layer.cornerRadius = configuration.cardCornerRadius
        titleLabel.textColor = configuration.titleColor
        messageLabel.textColor = configuration.messageColor
        leadingConstraint.constant = configuration.contentPadding
        trailingConstraint.constant = -configuration.contentPadding
        topConstraint.constant = configuration.contentPadding
        bottomConstraint.constant = -configuration.contentPadding
        accessibilityIdentifier = "pt.instructions.content"
        titleLabel.accessibilityIdentifier = "pt.instructions.title"
        messageLabel.accessibilityIdentifier = "pt.instructions.message"
    }

    func configure(customView: UIView) {
        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        contentStack.addArrangedSubview(customView)
        actionStack.isHidden = true
        titleLabel.isHidden = true
        messageLabel.isHidden = true
        setNeedsLayout()
    }

    func updateArrow(placement: PTPopoverPlacement,
                     point: CGPoint?,
                     appearance: PTArrowAppearance) {
        arrowPlacement = placement
        arrowPoint = point
        arrowAppearance = appearance
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        guard arrowAppearance.isVisible,
              let point = arrowPoint,
              arrowAppearance.size.width > 0,
              arrowAppearance.size.height > 0 else {
            arrowLayer.path = nil
            return
        }

        let halfWidth = arrowAppearance.size.width / 2
        switch arrowPlacement {
        case .top, .topLeading, .topTrailing:
            path.move(to: CGPoint(x: point.x - halfWidth, y: bounds.height - 1))
            path.addLine(to: CGPoint(x: point.x, y: bounds.height + arrowAppearance.size.height))
            path.addLine(to: CGPoint(x: point.x + halfWidth, y: bounds.height - 1))
        case .bottom, .bottomLeading, .bottomTrailing:
            path.move(to: CGPoint(x: point.x - halfWidth, y: 1))
            path.addLine(to: CGPoint(x: point.x, y: -arrowAppearance.size.height))
            path.addLine(to: CGPoint(x: point.x + halfWidth, y: 1))
        case .leading:
            path.move(to: CGPoint(x: bounds.width - 1, y: point.y - halfWidth))
            path.addLine(to: CGPoint(x: bounds.width + arrowAppearance.size.height, y: point.y))
            path.addLine(to: CGPoint(x: bounds.width - 1, y: point.y + halfWidth))
        case .trailing:
            path.move(to: CGPoint(x: 1, y: point.y - halfWidth))
            path.addLine(to: CGPoint(x: -arrowAppearance.size.height, y: point.y))
            path.addLine(to: CGPoint(x: 1, y: point.y + halfWidth))
        case .automatic:
            arrowLayer.path = nil
            return
        }
        path.close()
        arrowLayer.path = path.cgPath
        arrowLayer.fillColor = arrowAppearance.fillColor.cgColor
        arrowLayer.strokeColor = arrowAppearance.borderColor?.cgColor
        arrowLayer.lineWidth = arrowAppearance.borderWidth
    }

    private func setupView() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 18
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.16
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 5)
        layer.addSublayer(arrowLayer)

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0

        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(messageLabel)
        actionStack.axis = .horizontal
        actionStack.spacing = 8
        actionStack.alignment = .center
        contentStack.addArrangedSubview(actionStack)
        addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        leadingConstraint = contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18)
        trailingConstraint = contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18)
        topConstraint = contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 16)
        bottomConstraint = contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }

    private func makeButton(title: String,
                            color: UIColor,
                            identifier: String,
                            action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(color, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.accessibilityIdentifier = identifier
        button.addAction(UIAction { _ in action() }, for: .primaryActionTriggered)
        return button
    }
}
