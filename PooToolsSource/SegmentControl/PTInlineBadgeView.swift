import UIKit

#if canImport(ptools)
import ptools
#endif

// English: Inline badge renderer that reuses the Core badge contract without overlay positioning.
// Español: Renderizador de insignia integrada que reutiliza el contrato Core sin posicionamiento superpuesto.
// 中文：复用 Core 角标契约的内嵌角标渲染器，不使用覆盖层定位。
@MainActor
internal final class PTInlineBadgeView: UIView {
    private let label = UILabel()
    private var content: PTBadgeContent?
    private var configuration = PTBadgeConfiguration()
    private var interactionController: PTBadgeInteractionController?
    private var traitChangeRegistration: (any UITraitChangeRegistration)?

    var onRemove: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isAccessibilityElement = false
        traitChangeRegistration = registerForTraitChanges([UITraitUserInterfaceStyle.self]) { [weak self] (_: PTInlineBadgeView, _: UITraitCollection) in
            self?.render()
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reduceMotionStatusDidChange),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                               object: nil)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 1
        label.isAccessibilityElement = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func reduceMotionStatusDidChange() {
        render()
    }

    var badgeContent: PTBadgeContent? { content }

    override var intrinsicContentSize: CGSize {
        guard let content else { return .zero }
        return PTBadgeLayoutMetrics.size(for: content, configuration: configuration)
    }

    func apply(content: PTBadgeContent,
               configuration: PTBadgeConfiguration,
               onRemove: (() -> Void)?) {
        self.content = content
        self.configuration = configuration
        self.onRemove = onRemove
        isHidden = false
        alpha = 1
        transform = .identity
        invalidateIntrinsicContentSize()
        render()
        updateInteractionController()
    }

    func reset() {
        interactionController?.invalidate()
        interactionController = nil
        content = nil
        onRemove = nil
        isHidden = true
        alpha = 1
        transform = .identity
        PTBadgeAnimationDriver.remove(from: layer)
        invalidateIntrinsicContentSize()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateInteractionController()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        render()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }

    private func render() {
        guard let content else {
            isHidden = true
            PTBadgeAnimationDriver.remove(from: layer)
            return
        }

        let size = PTBadgeLayoutMetrics.size(for: content, configuration: configuration)
        guard size.width > 0, size.height > 0 else {
            isHidden = true
            PTBadgeAnimationDriver.remove(from: layer)
            return
        }

        isHidden = false
        backgroundColor = configuration.bgColor
        label.text = PTBadgeLayoutMetrics.displayText(for: content, configuration: configuration)
        label.font = configuration.font
        label.textColor = configuration.textColor
        label.layer.borderWidth = max(0, configuration.borderWidth.isFinite ? configuration.borderWidth : 0)
        label.layer.borderColor = configuration.borderColor.cgColor
        updateCornerRadius(for: size)
        layer.masksToBounds = true
        label.layer.masksToBounds = true
        PTBadgeAnimationDriver.apply(to: layer,
                                     animation: configuration.animType,
                                     isVisible: true,
                                     isAttachedToWindow: window != nil)
        setNeedsLayout()
    }

    private func updateCornerRadius(for size: CGSize? = nil) {
        let resolvedSize = size ?? bounds.size
        let radius = PTBadgeLayoutMetrics.cornerRadius(for: resolvedSize,
                                                       configuration: configuration)
        layer.cornerRadius = radius
        label.layer.cornerRadius = radius
    }

    private func updateInteractionController() {
        guard content != nil else {
            interactionController?.invalidate()
            return
        }

        if interactionController == nil {
            interactionController = PTBadgeInteractionController(hostView: superview,
                                                                  draggableView: self,
                                                                  usesTransform: true,
                                                                  removesViewOnDelete: false)
        }
        interactionController?.onRemove = { [weak self] in
            guard let self else { return }
            self.content = nil
            self.isHidden = true
            self.alpha = 1
            self.transform = .identity
            self.invalidateIntrinsicContentSize()
            self.interactionController?.invalidate()
            self.onRemove?()
        }
        interactionController?.update(hostView: superview,
                                      isEnabled: configuration.canDragToDelete,
                                      longPressTime: configuration.longPressTime)
    }
}
