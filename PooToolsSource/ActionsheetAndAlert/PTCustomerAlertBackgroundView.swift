//
//  PTCustomerAlertBackgroundView.swift
//  PooTools
//
// English: Own the alert surface so UIKit version checks never leak into the controller layout.
// Español: Encapsula la superficie para que las comprobaciones de versión no entren en el diseño del controlador.
// 中文：独立管理 Alert 背景表面，避免系统版本判断污染控制器布局。
//

import UIKit

@MainActor
final class PTCustomerAlertBackgroundView: UIView {
    let contentView = UIView()

    var appearance: PTCustomerAlertAppearance = .default {
        didSet { updateAppearance() }
    }

    var legacyVisualStyle: PTVisualStyle = .automatic {
        didSet { updateAppearance() }
    }

    var legacyCornerRadius: CGFloat = 15 {
        didSet { updateAppearance() }
    }

    var contentBackgroundColor: UIColor? {
        didSet { updateAppearance() }
    }

    private let surfaceView = UIVisualEffectView(frame: .zero)
    private let tintView = UIView(frame: .zero)
    private var traitChangeRegistration: (any UITraitChangeRegistration)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func setupView() {
        isOpaque = false
        clipsToBounds = false
        isAccessibilityElement = false

        surfaceView.isUserInteractionEnabled = true
        surfaceView.isAccessibilityElement = false
        surfaceView.clipsToBounds = true
        addSubview(surfaceView)

        tintView.isUserInteractionEnabled = false
        surfaceView.contentView.addSubview(tintView)
        surfaceView.contentView.addSubview(contentView)

        traitChangeRegistration = registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self
        ]) { [weak self] (_: PTCustomerAlertBackgroundView, _: UITraitCollection) in
            self?.updateAppearance()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityAppearanceDidChange),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )

        updateAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        surfaceView.frame = bounds
        tintView.frame = surfaceView.bounds
        contentView.frame = surfaceView.contentView.bounds
        surfaceView.layer.cornerRadius = resolvedCornerRadius
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: resolvedCornerRadius
        ).cgPath
    }

    @objc
    private func accessibilityAppearanceDidChange() {
        updateAppearance()
    }

    private var resolvedCornerRadius: CGFloat {
        switch appearance.cornerStyle {
        case .system:
            guard legacyCornerRadius.isFinite else { return 15 }
            return max(0, legacyCornerRadius)
        case .fixed(let value):
            guard value.isFinite else { return 15 }
            return max(0, value)
        }
    }

    private func updateAppearance() {
        let cornerRadius = resolvedCornerRadius
        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
        layer.shadowColor = UIColor.black.withAlphaComponent(0.16).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 8)
        layer.borderWidth = 1 / max(UIScreen.main.scale, 1)

        let borderAlpha = traitCollection.accessibilityContrast == .high
            ? min(1, max(appearance.separatorAlpha, 0.5))
            : min(1, max(appearance.separatorAlpha, 0))
        layer.borderColor = UIColor.separator
            .withAlphaComponent(borderAlpha)
            .resolvedColor(with: traitCollection)
            .cgColor

        surfaceView.layer.cornerRadius = cornerRadius
        surfaceView.layer.cornerCurve = .continuous
        surfaceView.backgroundColor = resolvedSolidBackgroundColor
        surfaceView.effect = resolvedEffect

        let usesEffect = surfaceView.effect != nil && contentBackgroundColor == nil
        tintView.isHidden = !usesEffect
        tintView.backgroundColor = resolvedTintColor
        contentView.backgroundColor = .clear
        setNeedsLayout()
    }

    private var resolvedEffect: UIVisualEffect? {
        guard contentBackgroundColor == nil else { return nil }
        guard legacyVisualStyle != .classic else { return nil }
        guard !appearance.respectsReduceTransparency || !UIAccessibility.isReduceTransparencyEnabled else {
            return nil
        }

        if legacyVisualStyle == .material {
            return UIBlurEffect(style: .systemMaterial)
        }

        guard appearance.glassEnabled else { return nil }

        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            switch appearance.glassStyle {
            case .clear:
                return UIGlassEffect(style: .clear)
            case .automatic, .regular:
                return UIGlassEffect(style: .regular)
            }
        }
        #endif

        switch appearance.glassStyle {
        case .clear:
            return UIBlurEffect(style: .systemThinMaterial)
        case .automatic, .regular:
            return UIBlurEffect(style: .systemMaterial)
        }
    }

    private var resolvedSolidBackgroundColor: UIColor {
        if let contentBackgroundColor {
            return contentBackgroundColor.resolvedColor(with: traitCollection)
        }
        return UIColor.secondarySystemBackground.resolvedColor(with: traitCollection)
    }

    private var resolvedTintColor: UIColor {
        guard contentBackgroundColor == nil else { return .clear }
        switch appearance.glassStyle {
        case .clear:
            return UIColor.systemBackground.withAlphaComponent(0.06)
        case .automatic, .regular:
            return UIColor.systemBackground.withAlphaComponent(0.12)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
