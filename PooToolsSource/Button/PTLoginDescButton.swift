//
//  PTLoginDescButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 9/12/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import AttributedString
import SnapKit
import SwifterSwift

public class PTLoginDescConfig: NSObject {
    public var textColor_L: DynamicColor = DynamicColor(hexString: "7f7f7f") ?? .clear
    public var textColor_R: DynamicColor = DynamicColor(hexString: "7f7f7f") ?? .clear
    public var textColor_line: DynamicColor = DynamicColor(hexString: "7f7f7f") ?? .clear
    public var textFont: UIFont = .appfont(size: 12)
    public var leftDesc: String = "A"
    public var rightDesc: String = "B"
    public var leftAttributedDesc: ASAttributedString?
    public var rightAttributedDesc: ASAttributedString?
    public var numberOfLines: Int = 1
    public var lineBreakMode: NSLineBreakMode = .byWordWrapping
    public var lineWidth: CGFloat = 1
    public var lineTopNBottomSpace: CGFloat = 2
    public var itemSpace: CGFloat = 8
}

public enum PTLoginDescButtonType {
    case Left, Right
}

private final class PTLoginDescLabel: UILabel {
    var activationHandler: (() -> Bool)?

    override func accessibilityActivate() -> Bool {
        activationHandler?() ?? super.accessibilityActivate()
    }
}

open class PTLoginDescButton: UIView {

    public var descHandler: ((PTLoginDescButtonType) -> Void)?

    private let viewConfig: PTLoginDescConfig
    private let leftDesc = PTLoginDescLabel()
    private let rightDesc = PTLoginDescLabel()
    private let verLine = UIView()
    private let stackView = UIStackView()

    public init(config: PTLoginDescConfig = PTLoginDescConfig()) {
        viewConfig = config
        super.init(frame: .zero)
        setupView()
        reloadConfiguration()
    }

    required public init?(coder: NSCoder) {
        viewConfig = PTLoginDescConfig()
        super.init(coder: coder)
        setupView()
        reloadConfiguration()
    }

    public func reloadConfiguration() {
        configure(label: leftDesc,
                  attributedText: viewConfig.leftAttributedDesc,
                  plainText: viewConfig.leftDesc,
                  color: viewConfig.textColor_L,
                  type: .Left)
        configure(label: rightDesc,
                  attributedText: viewConfig.rightAttributedDesc,
                  plainText: viewConfig.rightDesc,
                  color: viewConfig.textColor_R,
                  type: .Right)

        stackView.spacing = sanitizedNonNegative(viewConfig.itemSpace)
        verLine.backgroundColor = viewConfig.textColor_line
        verLine.isHidden = leftDesc.isHidden || rightDesc.isHidden
        verLine.snp.remakeConstraints { make in
            make.width.equalTo(sanitizedNonNegative(viewConfig.lineWidth))
            make.top.bottom.equalToSuperview().inset(sanitizedNonNegative(viewConfig.lineTopNBottomSpace))
        }
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    private func setupView() {
        stackView.axis = .horizontal
        stackView.alignment = .fill
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.addArrangedSubview(leftDesc)
        stackView.addArrangedSubview(verLine)
        stackView.addArrangedSubview(rightDesc)

        [leftDesc, rightDesc].forEach { label in
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            label.setContentHuggingPriority(.required, for: .horizontal)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        verLine.setContentHuggingPriority(.required, for: .horizontal)
        verLine.setContentCompressionResistancePriority(.required, for: .horizontal)

        leftDesc.activationHandler = { [weak self] in
            guard let self, self.descHandler != nil else { return false }
            self.descHandler?(.Left)
            return true
        }
        rightDesc.activationHandler = { [weak self] in
            guard let self, self.descHandler != nil else { return false }
            self.descHandler?(.Right)
            return true
        }
    }

    private func configure(label: PTLoginDescLabel,
                           attributedText: ASAttributedString?,
                           plainText: String,
                           color: UIColor,
                           type: PTLoginDescButtonType) {
        label.numberOfLines = max(0, viewConfig.numberOfLines)
        label.lineBreakMode = viewConfig.lineBreakMode

        let source = attributedText ?? ASAttributedString(string: plainText)
        guard source.length > 0 else {
            label.attributed.text = nil
            label.isHidden = true
            label.accessibilityLabel = nil
            return
        }

        let fallbackAction = ASAttributedString.Attribute.action { [weak self] in
            self?.descHandler?(type)
        }
        let styledText = ASAttributedString(source, with: [
            .font(viewConfig.textFont),
            .foreground(color),
            .paragraph(.alignment(.center), .lineBreakMode(viewConfig.lineBreakMode)),
            fallbackAction
        ])
        label.attributed.text = styledText
        label.isHidden = false
        label.accessibilityLabel = styledText.value.string
        label.accessibilityTraits = .button
    }

    private func sanitizedNonNegative(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return max(0, value)
    }
}
