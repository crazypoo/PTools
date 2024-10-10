//
//  PTAlertTips.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 7/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwiftUI

public enum PTAlertTipsStyle {
    
    #if os(iOS)
    case Normal
    #endif
    
    #if os(iOS) || os(visionOS)
    case SupportVisionOS
    #endif
}

public enum PTAlertTipControl {
    public static func present(view: PTAlertTipsProtocol, completion: @escaping PTActionTask) {
        guard let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }
        view.present(on: window, completion: completion)
    }
    
    public static func present(title: String? = nil, subtitle: String? = nil, icon: PTAlertTipsIcon? = nil, style: PTAlertTipsStyle, haptic: PTAlertTipsHaptic? = nil) {
        switch style {
        #if os(iOS)
        case .Normal:
            guard let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }
            let view = PTAlertTipsLow(title: title, subtitle: subtitle, icon: icon)
            view.haptic = haptic
            view.present(on: window)
        #endif
        #if os(iOS) || os(visionOS)
        case .SupportVisionOS:
            guard let window = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first else { return }
            let view = PTAlertTipsHight(title: title, subtitle: subtitle, icon: icon)
            view.haptic = haptic
            view.present(on: window)
        #endif
        }
    }
    
    public static func dismissAllAlerts(completion: PTActionTask? = nil) {
        
        var alertViews: [PTAlertTipsProtocol] = []
        
        for window in UIApplication.shared.windows {
            for view in window.subviews {
                if let view = view as? PTAlertTipsProtocol {
                    alertViews.append(view)
                }
            }
        }
        
        if alertViews.isEmpty {
            completion?()
        } else {
            for (index, view) in alertViews.enumerated() {
                if index == .zero {
                    view.dismiss(completion: completion)
                } else {
                    view.dismiss(completion: nil)
                }
            }
            alertViews.first?.dismiss {
                completion?()
            }
        }
    }
}

public protocol PTAlertTipsProtocol {
    func present(on view: UIView, completion: PTActionTask?)
    func dismiss(completion: PTActionTask?)
}

public class PTAlertTipsLow: UIView,PTAlertTipsProtocol {
    open var dismissByTap: Bool = true
    open var dismissInTime: Bool = true
    open var duration: TimeInterval = 1.5
    open var haptic: PTAlertTipsHaptic? = nil
    
    public let titleLabel: UILabel?
    public let subtitleLabel: UILabel?
    public let iconView: UIView?
    
    public static var defaultContentColor = UIColor { trait in
        switch trait.userInterfaceStyle {
        case .dark: return UIColor(red: 127 / 255, green: 127 / 255, blue: 129 / 255, alpha: 1)
        default: return UIColor(red: 88 / 255, green: 87 / 255, blue: 88 / 255, alpha: 1)
        }
    }
    
    fileprivate weak var viewForPresent: UIView?
    fileprivate var presentDismissDuration: TimeInterval = 0.2
    fileprivate var presentDismissScale: CGFloat = 0.8
    
    private lazy var backgroundView: UIVisualEffectView = {
        let result: UIVisualEffectView
        #if !os(tvOS)
        result = UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
        #else
        result = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        #endif
        let view: UIVisualEffectView = result
        view.isUserInteractionEnabled = false
        return view
    }()
    
    public init(title: String?, subtitle: String?, icon: PTAlertTipsIcon?) {

        if let title = title {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .title2, weight: .bold)
            label.numberOfLines = 0
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 3
            style.alignment = .center
            label.attributedText = NSAttributedString(string: title, attributes: [.paragraphStyle: style])
            titleLabel = label
        } else {
            titleLabel = nil
        }
        
        if let subtitle = subtitle {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .body)
            label.numberOfLines = 0
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 2
            style.alignment = .center
            label.attributedText = NSAttributedString(string: subtitle, attributes: [.paragraphStyle: style])
            subtitleLabel = label
        } else {
            subtitleLabel = nil
        }
        
        if let icon = icon {
            let view = icon.createView(lineThick: 9)
            iconView = view
        } else {
            iconView = nil
        }
        
        if icon == nil {
            layout = AlertLayout.message()
        } else {
            layout = AlertLayout(for: icon ?? .Heart)
        }
        
        titleLabel?.textColor = Self.defaultContentColor
        subtitleLabel?.textColor = Self.defaultContentColor
        iconView?.tintColor = Self.defaultContentColor
                
        super.init(frame: .zero)

        preservesSuperviewLayoutMargins = false
        insetsLayoutMarginsFromSafeArea = false
        
        backgroundColor = .clear
        addSubview(backgroundView)
        
        if let titleLabel = titleLabel {
            addSubview(titleLabel)
        }
        if let subtitleLabel = subtitleLabel {
            addSubview(subtitleLabel)
        }
        if let iconView = iconView {
            addSubview(iconView)
        }
        
        layoutMargins = layout.margins
        
        layer.masksToBounds = true
        layer.cornerRadius = 8
        layer.cornerCurve = .continuous
        
        switch icon {
        case .SpinnerSmall, .SpinnerLarge:
            dismissInTime = false
            dismissByTap = false
        default:
            dismissInTime = true
            dismissByTap = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func present(on view: UIView, completion: PTActionTask? = nil) {
        viewForPresent = view
        viewForPresent?.addSubview(self)
        guard let viewForPresent = viewForPresent else { return }
        
        alpha = 0
        sizeToFit()
        center = .init(x: viewForPresent.frame.midX, y: viewForPresent.frame.midY)
        transform = transform.scaledBy(x: presentDismissScale, y: presentDismissScale)
        
        if dismissByTap {
            let tapGesterRecognizer = UITapGestureRecognizer { sender in
                self.dismiss()
            }
            addGestureRecognizer(tapGesterRecognizer)
        }
        
        // Present
        
        haptic?.impact()
        
        UIView.animate(withDuration: presentDismissDuration, animations: {
            self.alpha = 1
            self.transform = CGAffineTransform.identity
        }, completion: { [weak self] finished in
            guard let self = self else { return }
            
            if let iconView = self.iconView as? PTAlertTipsAnimation {
                iconView.animation()
            }
            
            if self.dismissInTime {
                PTGCDManager.gcdAfter(time: self.duration) {
                    if self.alpha != 0 {
                        self.dismiss(completion: completion)
                    }
                }
            }
        })
    }
    
    @objc open func dismiss(completion: PTActionTask? = nil) {
        UIView.animate(withDuration: presentDismissDuration, animations: {
            self.alpha = 0
            self.transform = self.transform.scaledBy(x: self.presentDismissScale, y: self.presentDismissScale)
        }, completion: { [weak self] finished in
            self?.removeFromSuperview()
            completion?()
        })
    }
    
    private var layout: AlertLayout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard transform == .identity else { return }
        backgroundView.frame = bounds
        
        if let iconView = iconView {
            iconView.frame = .init(origin: .init(x: 0, y: layoutMargins.top), size: layout.iconSize)
            iconView.center.x = bounds.midX
        }
        if let titleLabel = titleLabel {
            titleLabel.layoutDynamicHeight(x: layoutMargins.left, y: iconView == nil ? layoutMargins.top : (iconView?.frame.maxY ?? 0) + layout.spaceBetweenIconAndTitle, width: frame.width - layoutMargins.left - layoutMargins.right)
        }
        if let subtitleLabel = subtitleLabel {
            let result: CGFloat
            if let titleLabel1 = titleLabel {
                result = titleLabel1.frame.maxY + 4
            } else {
                result = layoutMargins.top
            }
            let yPosition: CGFloat = result
            subtitleLabel.layoutDynamicHeight(x: layoutMargins.left, y: yPosition, width: frame.width - layoutMargins.left - layoutMargins.right)
        }
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width: CGFloat = 250
        frame = .init(x: frame.origin.x, y: frame.origin.y, width: width, height: frame.height)
        layoutSubviews()
        let height = subtitleLabel?.frame.maxY ?? titleLabel?.frame.maxY ?? iconView?.frame.maxY ?? .zero
        return .init(width: width, height: height + layoutMargins.bottom)
    }
    
    private class AlertLayout {
        
        var iconSize: CGSize
        var margins: UIEdgeInsets
        var spaceBetweenIconAndTitle: CGFloat
        
        public init(iconSize: CGSize, margins: UIEdgeInsets, spaceBetweenIconAndTitle: CGFloat) {
            self.iconSize = iconSize
            self.margins = margins
            self.spaceBetweenIconAndTitle = spaceBetweenIconAndTitle
        }
        
        convenience init() {
            self.init(iconSize: .init(width: 100, height: 100), margins: .init(top: 43, left: 16, bottom: 25, right: 16), spaceBetweenIconAndTitle: 41)
        }
        
        static func message() -> AlertLayout {
            let layout = AlertLayout()
            layout.margins = UIEdgeInsets(top: 23, left: 16, bottom: 23, right: 16)
            return layout
        }
        
        convenience init(for preset: PTAlertTipsIcon) {
            switch preset {
            case .Done:
                self.init(iconSize: .init(width: 112, height: 112), margins: .init(top: 63, left: Self.defaultHorizontalInset, bottom: 29, right: Self.defaultHorizontalInset), spaceBetweenIconAndTitle: 35)
            case .Heart:
                self.init(iconSize: .init(width: 112, height: 77), margins: .init(top: 49, left: Self.defaultHorizontalInset, bottom: 25, right: Self.defaultHorizontalInset), spaceBetweenIconAndTitle: 35)
            case .Error:
                self.init(iconSize: .init(width: 86, height: 86), margins: .init(top: 63, left: Self.defaultHorizontalInset, bottom: 29, right: Self.defaultHorizontalInset), spaceBetweenIconAndTitle: 39)
            case .SpinnerLarge, .SpinnerSmall:
                self.init(iconSize: .init(width: 16, height: 16), margins: .init(top: 58, left: Self.defaultHorizontalInset, bottom: 27, right: Self.defaultHorizontalInset), spaceBetweenIconAndTitle: 39)
            case .Custom(_):
                self.init(iconSize: .init(width: 100, height: 100), margins: .init(top: 43, left: Self.defaultHorizontalInset, bottom: 25, right: Self.defaultHorizontalInset), spaceBetweenIconAndTitle: 35)
            }
        }
        
        private static var defaultHorizontalInset: CGFloat {
            16
        }
    }
}

@available(iOS 13, visionOS 1, *)
public class PTAlertTipsHight: UIView, PTAlertTipsProtocol {
    
    open var dismissByTap: Bool = true
    open var dismissInTime: Bool = true
    open var duration: TimeInterval = 1.5
    open var haptic: PTAlertTipsHaptic? = nil
    
    public let titleLabel: UILabel?
    public let subtitleLabel: UILabel?
    public let iconView: UIView?
    
    public static var defaultContentColor = UIColor { trait in
        #if os(visionOS)
        return .label
        #else
        switch trait.userInterfaceStyle {
        case .dark: return UIColor(red: 127 / 255, green: 127 / 255, blue: 129 / 255, alpha: 1)
        default: return UIColor(red: 88 / 255, green: 87 / 255, blue: 88 / 255, alpha: 1)
        }
        #endif
    }
    
    fileprivate weak var viewForPresent: UIView?
    fileprivate var presentDismissDuration: TimeInterval = 0.2
    fileprivate var presentDismissScale: CGFloat = 0.8
    
    private lazy var backgroundView: UIView = {
        #if os(visionOS)
        let swiftUIView = VisionGlassBackgroundView(cornerRadius: 12)
        let host = UIHostingController(rootView: swiftUIView)
        let hostView = host.view ?? UIView()
        hostView.isUserInteractionEnabled = false
        return hostView
        #else
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        view.isUserInteractionEnabled = false
        return view
        #endif
    }()
    
    public init(title: String?, subtitle: String?, icon: PTAlertTipsIcon?) {
        
        if let title = title {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .body, weight: .semibold, addPoints: -2)
            label.numberOfLines = 0
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 3
            style.alignment = .left
            label.attributedText = NSAttributedString(string: title, attributes: [.paragraphStyle: style])
            titleLabel = label
        } else {
            titleLabel = nil
        }
        
        if let subtitle = subtitle {
            let label = UILabel()
            label.font = UIFont.preferredFont(forTextStyle: .footnote)
            label.numberOfLines = 0
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 2
            style.alignment = .left
            label.attributedText = NSAttributedString(string: subtitle, attributes: [.paragraphStyle: style])
            subtitleLabel = label
        } else {
            subtitleLabel = nil
        }
        
        if let icon = icon {
            let view = icon.createView(lineThick: 3)
            iconView = view
        } else {
            iconView = nil
        }
        
        titleLabel?.textColor = Self.defaultContentColor
        subtitleLabel?.textColor = Self.defaultContentColor
        iconView?.tintColor = Self.defaultContentColor
        
        super.init(frame: .zero)
        
        preservesSuperviewLayoutMargins = false
        insetsLayoutMarginsFromSafeArea = false
        
        backgroundColor = .clear
        addSubview(backgroundView)
        
        if let titleLabel = titleLabel {
            addSubview(titleLabel)
        }
        if let subtitleLabel = subtitleLabel {
            addSubview(subtitleLabel)
        }
        
        if let iconView = iconView {
            addSubview(iconView)
        }
        
        if subtitleLabel == nil {
            layoutMargins = .init(top: 17, left: 15, bottom: 17, right: 15 + ((icon == nil) ? .zero : 3))
        } else {
            layoutMargins = .init(top: 15, left: 15, bottom: 15, right: 15 + ((icon == nil) ? .zero : 3))
        }
        
        layer.masksToBounds = true
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        
        switch icon {
        case .SpinnerSmall, .SpinnerLarge:
            dismissInTime = false
            dismissByTap = false
        default:
            dismissInTime = true
            dismissByTap = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func present(on view: UIView, completion: PTActionTask? = nil) {
        viewForPresent = view
        viewForPresent?.addSubview(self)
        guard let viewForPresent = viewForPresent else { return }
        
        alpha = 0
        sizeToFit()
        center.x = viewForPresent.frame.midX
        #if os(visionOS)
        frame.origin.y = viewForPresent.safeAreaInsets.top + 24
        #elseif os(iOS)
        frame.origin.y = viewForPresent.frame.height - viewForPresent.safeAreaInsets.bottom - frame.height - 64
        #endif
        
        transform = transform.scaledBy(x: presentDismissScale, y: presentDismissScale)
        
        if dismissByTap {
            let tapGesterRecognizer = UITapGestureRecognizer { sender in
                self.dismiss()
            }
            addGestureRecognizer(tapGesterRecognizer)
        }
        
        // Present
        
        haptic?.impact()
        
        UIView.animate(withDuration: presentDismissDuration, animations: {
            self.alpha = 1
            self.transform = CGAffineTransform.identity
        }, completion: { [weak self] finished in
            guard let self = self else { return }
            
            if let iconView = self.iconView as? PTAlertTipsAnimation {
                iconView.animation()
            }
            
            if self.dismissInTime {
                PTGCDManager.gcdAfter(time: self.duration) {
                    if self.alpha != 0 {
                        self.dismiss(completion: completion)
                    }
                }
            }
        })
    }
    
    @objc open func dismiss(completion: PTActionTask? = nil) {
        UIView.animate(withDuration: presentDismissDuration, animations: {
            self.alpha = 0
            self.transform = self.transform.scaledBy(x: self.presentDismissScale, y: self.presentDismissScale)
        }, completion: { [weak self] finished in
            self?.removeFromSuperview()
            completion?()
        })
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard transform == .identity else { return }
        backgroundView.frame = bounds
        layout(maxWidth: frame.width)
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        layout(maxWidth: nil)

        let maxX = subviews.sorted(by: { $0.frame.maxX > $1.frame.maxX }).first?.frame.maxX ?? .zero
        let currentNeedWidth = maxX + layoutMargins.right
        let maxWidth = {
            if let viewForPresent = self.viewForPresent {
                return min(viewForPresent.frame.width * 0.8, 270)
            } else {
                return 270
            }
        }()
        let usingWidth = min(currentNeedWidth, maxWidth)
        layout(maxWidth: usingWidth)
        let height = subtitleLabel?.frame.maxY ?? titleLabel?.frame.maxY ?? .zero
        return .init(width: usingWidth, height: height + layoutMargins.bottom)
    }
    
    private func layout(maxWidth: CGFloat?) {
        
        let spaceBetweenLabelAndIcon: CGFloat = 12
        let spaceBetweenTitleAndSubtitle: CGFloat = 4
        
        if let iconView = iconView {
            iconView.frame = .init(x: layoutMargins.left, y: .zero, width: 20, height: 20)
            let xPosition = iconView.frame.maxX + spaceBetweenLabelAndIcon
            if let maxWidth = maxWidth {
                let labelWidth = maxWidth - xPosition - layoutMargins.right
                titleLabel?.frame = .init(x: xPosition, y: layoutMargins.top, width: labelWidth, height: titleLabel?.frame.height ?? .zero)
                titleLabel?.sizeToFit()
                subtitleLabel?.frame = .init(x: xPosition, y: (titleLabel?.frame.maxY ?? layoutMargins.top) + spaceBetweenTitleAndSubtitle, width: labelWidth, height: subtitleLabel?.frame.height ?? .zero)
                subtitleLabel?.sizeToFit()
            } else {
                titleLabel?.sizeToFit()
                titleLabel?.frame.origin.x = xPosition
                titleLabel?.frame.origin.y = layoutMargins.top
                subtitleLabel?.sizeToFit()
                subtitleLabel?.frame.origin.x = xPosition
                subtitleLabel?.frame.origin.y = (titleLabel?.frame.maxY ?? layoutMargins.top) + spaceBetweenTitleAndSubtitle
            }
        } else {
            if let maxWidth = maxWidth {
                let labelWidth = maxWidth - layoutMargins.left - layoutMargins.right
                titleLabel?.frame = .init(x: layoutMargins.left, y: layoutMargins.top, width: labelWidth, height: titleLabel?.frame.height ?? .zero)
                titleLabel?.sizeToFit()
                subtitleLabel?.frame = .init(x: layoutMargins.left, y: (titleLabel?.frame.maxY ?? layoutMargins.top) + spaceBetweenTitleAndSubtitle, width: labelWidth, height: subtitleLabel?.frame.height ?? .zero)
                subtitleLabel?.sizeToFit()
            } else {
                titleLabel?.sizeToFit()
                titleLabel?.frame.origin.x = layoutMargins.left
                titleLabel?.frame.origin.y = layoutMargins.top
                subtitleLabel?.sizeToFit()
                subtitleLabel?.frame.origin.x = layoutMargins.left
                subtitleLabel?.frame.origin.y = (titleLabel?.frame.maxY ?? layoutMargins.top) + spaceBetweenTitleAndSubtitle
            }
        }
        iconView?.center.y = frame.height / 2
    }
    
    #if os(visionOS)
    struct VisionGlassBackgroundView: View {
        
        let cornerRadius: CGFloat
        
        var body: some View {
            ZStack {
                Color.clear
            }
            .glassBackgroundEffect(in: .rect(cornerRadius: cornerRadius))
            .opacity(0.4)
        }
    }
    #endif
}
