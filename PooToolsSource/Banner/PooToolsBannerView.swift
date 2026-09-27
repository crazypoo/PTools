// English: UIKit renderer for standard, growing, floating, and compact banners.
// Español: Renderer UIKit para banners estándar, crecientes, flotantes y compactos.
// 中文：标准、增长、浮动和紧凑 Banner 的 UIKit 渲染器。

import UIKit
#if canImport(PToolsSymbols)
import PToolsSymbols
#endif

@MainActor
public final class PooToolsBannerView: UIView {
    public private(set) var banner: PTBanner
    public var onTapRequest: (@MainActor @Sendable () -> Void)?
    public var onSwipeRequest: (@MainActor @Sendable () -> Void)?

    private let theme: PTBannerThemeProviding
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let contentStack = UIStackView()
    private let leadingContainer = UIView()
    private let textStack = UIStackView()
    private let trailingContainer = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let actionStack = UIStackView()
    private var contentLeadingConstraint: NSLayoutConstraint!
    private var contentTrailingConstraint: NSLayoutConstraint!
    private var contentTopConstraint: NSLayoutConstraint!
    private var contentBottomConstraint: NSLayoutConstraint!
    private var panStartTransform: CGAffineTransform = .identity

    public init(banner: PTBanner,
                theme: PTBannerThemeProviding = PTBannerDefaultTheme()) {
        self.banner = banner
        self.theme = theme
        super.init(frame: .zero)
        setupView()
        registerTraitChangeObservation()
        apply(banner)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: banner.configuration.cornerRadius).cgPath
    }

    // English: Observe iOS 17 trait changes without using the deprecated lifecycle callback.
    // Español: Observa los cambios de traits de iOS 17 sin usar el callback de ciclo de vida obsoleto.
    // 中文：使用 iOS 17 的 trait 观察 API，避免依赖已弃用的生命周期回调。
    private func registerTraitChangeObservation() {
        registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self
        ]) { (bannerView: PooToolsBannerView, previousTraitCollection: UITraitCollection) in
            guard previousTraitCollection.hasDifferentColorAppearance(comparedTo: bannerView.traitCollection)
                || previousTraitCollection.accessibilityContrast != bannerView.traitCollection.accessibilityContrast else { return }
            bannerView.applyAppearance()
        }
    }

    public func apply(_ banner: PTBanner) {
        self.banner = banner
        configureLabels()
        configureAccessories()
        configureActions()
        applyAppearance()
        let insets = banner.configuration.contentInsets
        contentLeadingConstraint.constant = insets.leading
        contentTrailingConstraint.constant = -insets.trailing
        contentTopConstraint.constant = insets.top
        contentBottomConstraint.constant = -insets.bottom
        accessibilityValue = accessibilityText
        setNeedsLayout()
    }

    private func setupView() {
        isUserInteractionEnabled = true
        translatesAutoresizingMaskIntoConstraints = false
        accessibilityIdentifier = "pt.banner"
        layer.masksToBounds = false

        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        contentStack.axis = .horizontal
        contentStack.alignment = .center
        contentStack.spacing = 10
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        contentLeadingConstraint = contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: banner.configuration.contentInsets.leading)
        contentTrailingConstraint = contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -banner.configuration.contentInsets.trailing)
        contentTopConstraint = contentStack.topAnchor.constraint(equalTo: topAnchor, constant: banner.configuration.contentInsets.top)
        contentBottomConstraint = contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -banner.configuration.contentInsets.bottom)
        NSLayoutConstraint.activate([
            contentLeadingConstraint,
            contentTrailingConstraint,
            contentTopConstraint,
            contentBottomConstraint
        ])

        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 2
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        leadingContainer.setContentHuggingPriority(.required, for: .horizontal)
        leadingContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingContainer.setContentHuggingPriority(.required, for: .horizontal)
        trailingContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentStack.addArrangedSubview(leadingContainer)
        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(trailingContainer)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(pan)
    }

    private func configureLabels() {
        configure(titleLabel, with: banner.content.title, identifier: "pt.banner.title")
        configure(subtitleLabel, with: banner.content.subtitle, identifier: "pt.banner.subtitle")
        textStack.removeAllArrangedSubviews()
        if titleLabel.isHidden == false {
            textStack.addArrangedSubview(titleLabel)
        }
        if subtitleLabel.isHidden == false {
            textStack.addArrangedSubview(subtitleLabel)
        }
        if textStack.arrangedSubviews.isEmpty {
            textStack.addArrangedSubview(UIView())
        }
    }

    private func configure(_ label: UILabel, with text: PTBannerText?, identifier: String) {
        label.accessibilityIdentifier = identifier
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = banner.configuration.textOverflow == .truncate ? 1 : 0
        label.lineBreakMode = banner.configuration.textOverflow == .truncate ? .byTruncatingTail : .byWordWrapping
        label.isHidden = text == nil
        switch text {
        case let .string(value):
            label.attributedText = nil
            label.text = value
        case let .attributed(value):
            label.text = nil
            label.attributedText = value
        case nil:
            label.text = nil
            label.attributedText = nil
        }
    }

    private func configureAccessories() {
        leadingContainer.removeAllSubviews()
        trailingContainer.removeAllSubviews()
        if let leading = banner.content.leading {
            addAccessory(makeAccessory(leading), to: leadingContainer)
        }
        if let trailing = banner.content.trailing {
            addAccessory(makeAccessory(trailing), to: trailingContainer)
        }
    }

    // English: Center each accessory so custom views cannot remain ambiguously positioned.
    // Español: Centra cada accesorio para que las vistas personalizadas no queden sin posición.
    // 中文：将每个附件居中，避免自定义 View 位置不明确。
    private func addAccessory(_ view: UIView, to container: UIView) {
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    private func makeAccessory(_ accessory: PTBannerAccessory) -> UIView {
        let view: UIView
        switch accessory {
        case let .image(image):
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            view = imageView
        case let .symbol(symbol):
            let imageView = UIImageView(image: PTSymbolResolver.image(symbol))
            imageView.contentMode = .scaleAspectFit
            view = imageView
        case let .view(builder):
            view = builder()
        case .activity:
            let activity = UIActivityIndicatorView(style: .medium)
            activity.startAnimating()
            view = activity
        case let .progress(value):
            let progress = UIProgressView(progressViewStyle: .default)
            progress.progress = Float(min(max(value, 0), 1))
            view = progress
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(lessThanOrEqualToConstant: 32),
            view.heightAnchor.constraint(lessThanOrEqualToConstant: 32)
        ])
        return view
    }

    private func configureActions() {
        actionStack.removeAllArrangedSubviews()
        guard banner.actions.isEmpty == false else {
            trailingContainer.isHidden = banner.content.trailing == nil
            return
        }
        actionStack.axis = .horizontal
        actionStack.spacing = 6
        actionStack.alignment = .center
        for action in banner.actions {
            let button = UIButton(type: .system)
            button.accessibilityIdentifier = "pt.banner.action"
            button.accessibilityLabel = action.title
            button.setTitle(action.title, for: .normal)
            button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
            button.addAction(UIAction { _ in action.handler?() }, for: .touchUpInside)
            button.addAction(UIAction { [weak self] _ in self?.onTapRequest?() }, for: .touchUpInside)
            actionStack.addArrangedSubview(button)
        }
        trailingContainer.addSubview(actionStack)
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionStack.leadingAnchor.constraint(equalTo: trailingContainer.leadingAnchor),
            actionStack.trailingAnchor.constraint(equalTo: trailingContainer.trailingAnchor),
            actionStack.topAnchor.constraint(equalTo: trailingContainer.topAnchor),
            actionStack.bottomAnchor.constraint(equalTo: trailingContainer.bottomAnchor)
        ])
        trailingContainer.isHidden = false
    }

    private func applyAppearance() {
        let appearance = theme.appearance(for: banner.style, traits: traitCollection)
        let background = banner.configuration.backgroundColor ?? appearance.backgroundColor
        let tint = banner.configuration.tintColor ?? appearance.tintColor
        let border = banner.configuration.borderColor ?? appearance.borderColor
        let shouldUseMaterial = UIAccessibility.isReduceTransparencyEnabled == false && banner.configuration.backgroundColor == nil
        blurView.isHidden = !shouldUseMaterial
        backgroundColor = shouldUseMaterial ? .clear : background
        blurView.backgroundColor = background.withAlphaComponent(0.15)
        layer.cornerRadius = banner.configuration.cornerRadius
        layer.borderColor = border.cgColor
        layer.borderWidth = traitCollection.accessibilityContrast == .high ? 1 : 0.5
        layer.shadowColor = banner.configuration.shadowColor.cgColor
        layer.shadowOpacity = banner.configuration.showsShadow ? 0.16 : 0
        layer.shadowRadius = banner.configuration.showsShadow ? 12 : 0
        layer.shadowOffset = CGSize(width: 0, height: 5)
        titleLabel.textColor = appearance.titleColor
        subtitleLabel.textColor = appearance.subtitleColor
        titleLabel.font = .preferredFont(forTextStyle: banner.configuration.layoutMode == .compact ? .subheadline : .headline)
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        tintColor = tint
        accessibilityLabel = accessibilityText
    }

    private var accessibilityText: String {
        let title: String
        switch banner.content.title {
        case let .string(value):
            title = value
        case let .attributed(value):
            title = value.string
        case nil:
            title = ""
        }
        let subtitle: String
        switch banner.content.subtitle {
        case let .string(value):
            subtitle = value
        case let .attributed(value):
            subtitle = value.string
        case nil:
            subtitle = ""
        }
        return [title, subtitle].filter { $0.isEmpty == false }.joined(separator: ", ")
    }

    @objc private func handleTap() {
        onTapRequest?()
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        switch gesture.state {
        case .began:
            panStartTransform = transform
        case .changed:
            let direction: CGFloat = banner.configuration.position == .top ? -1 : 1
            let offset = max(0, direction * translation.y)
            transform = panStartTransform.translatedBy(x: 0, y: direction * offset)
        case .ended, .cancelled:
            let direction: CGFloat = banner.configuration.position == .top ? -1 : 1
            let offset = direction * translation.y
            if offset > max(44, bounds.height * 0.3) || direction * velocity.y > 600 {
                onSwipeRequest?()
            } else {
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: UIAccessibility.isReduceMotionEnabled ? 0.1 : 0.2,
                                                                delay: 0,
                                                                options: [.curveEaseOut]) {
                    self.transform = self.panStartTransform
                }
            }
        default:
            break
        }
    }
}
