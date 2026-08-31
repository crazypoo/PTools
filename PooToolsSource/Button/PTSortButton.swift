//
//  PTSortButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/3/1.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

@objc public enum PTSortButtonType: Int {
    case Normal
    case Increase
    case Decrease
}

// English: Selects whether the button displays one or two sort indicators.
// Español: Selecciona si el botón muestra uno o dos indicadores de ordenación.
// 中文：选择按钮显示一个还是两个排序指示图标。
@objc public enum PTSortButtonShowType: Int {
    case Tres
    case Dos
}

@objcMembers
public class PTSortButton: UIView {

    public var sortTypeHandler: ((PTSortButtonType) -> Void)?

    public var sortType: PTSortButtonType = .Normal {
        didSet {
            if oldValue != sortType {
                render()
            }
        }
    }

    public var buttonTitle: String = "" {
        didSet {
            if oldValue != buttonTitle {
                render()
                invalidateIntrinsicContentSize()
            }
        }
    }

    public var buttonTitleFont: UIFont = .appfont(size: 14) {
        didSet {
            if oldValue != buttonTitleFont {
                render()
                invalidateIntrinsicContentSize()
            }
        }
    }

    public var buttonTitleSelectedFont: UIFont = .appfont(size: 14) {
        didSet {
            if oldValue != buttonTitleSelectedFont {
                render()
                invalidateIntrinsicContentSize()
            }
        }
    }

    public var buttonTitleSelectedColor: UIColor = .white {
        didSet {
            if oldValue != buttonTitleSelectedColor {
                render()
            }
        }
    }

    public var buttonTitleNormalColor: UIColor = .lightGray {
        didSet {
            if oldValue != buttonTitleNormalColor {
                render()
            }
        }
    }

    public var upNormalImage: Any = UIColor.lightGray.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) {
        didSet {
            render()
        }
    }

    public var upSelectedImage: Any = UIColor.systemRed.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) {
        didSet {
            render()
        }
    }

    public var dosDecreaseImage: Any = UIColor.systemRed.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) {
        didSet {
            render()
        }
    }

    public var dowmNormalImage: Any = UIColor.lightGray.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) {
        didSet {
            render()
        }
    }

    public var downSelectedImage: Any = UIColor.systemBlue.createImageWithColor().transformImage(size: CGSize(width: 10, height: 10)) {
        didSet {
            render()
        }
    }

    public var contentImageSpace: CGFloat = 2 {
        didSet {
            if oldValue != contentImageSpace {
                setNeedsLayout()
            }
        }
    }

    public var imageSpace: CGFloat = 4 {
        didSet {
            if oldValue != imageSpace {
                setNeedsLayout()
            }
        }
    }

    public var imageSize: CGSize = CGSize(width: 6, height: 4) {
        didSet {
            if oldValue != imageSize {
                setNeedsLayout()
                invalidateIntrinsicContentSize()
            }
        }
    }

    fileprivate lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.adjustsFontForContentSizeCategory = true
        return view
    }()

    fileprivate lazy var upImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()

    fileprivate lazy var downImage: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        return view
    }()

    fileprivate var showType: PTSortButtonShowType = .Tres
    private var lastLayoutSize: CGSize = .zero
    private var needsConstraintUpdate = true
    private var upImageToken: String?
    private var downImageToken: String?
    private var hasInstalledSubviews = false

    public init(showType: PTSortButtonShowType = .Tres) {
        self.showType = showType
        super.init(frame: .zero)
        commonInit()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setUpViews()
        isAccessibilityElement = true
        accessibilityTraits = .button
        render()
    }

    func setUpViews() {
        guard !hasInstalledSubviews else { return }
        hasInstalledSubviews = true

        switch showType {
        case .Tres:
            addSubview(titleLabel)
            addSubview(upImage)
            addSubview(downImage)
        case .Dos:
            addSubview(titleLabel)
            addSubview(upImage)
            downImage.isHidden = true
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    private func render() {
        guard hasInstalledSubviews else { return }

        let isSelected = sortType != .Normal
        titleLabel.text = buttonTitle
        titleLabel.font = isSelected ? buttonTitleSelectedFont : buttonTitleFont
        titleLabel.textColor = isSelected ? buttonTitleSelectedColor : buttonTitleNormalColor

        let upSource: Any
        let downSource: Any?
        switch showType {
        case .Tres:
            switch sortType {
            case .Normal:
                upSource = upNormalImage
                downSource = dowmNormalImage
            case .Increase:
                upSource = upSelectedImage
                downSource = dowmNormalImage
            case .Decrease:
                upSource = upNormalImage
                downSource = downSelectedImage
            }
        case .Dos:
            switch sortType {
            case .Normal:
                upSource = upNormalImage
            case .Increase:
                upSource = upSelectedImage
            case .Decrease:
                upSource = dosDecreaseImage
            }
            downSource = nil
        }

        loadImage(upSource, into: upImage, token: &upImageToken)
        if let downSource {
            loadImage(downSource, into: downImage, token: &downImageToken)
        } else if downImageToken != nil {
            downImageToken = nil
            downImage.cancelImageLoad()
            downImage.image = nil
        }

        accessibilityLabel = buttonTitle
        accessibilityValue = accessibilitySortValue
        setNeedsLayout()
    }

    private var accessibilitySortValue: String {
        switch sortType {
        case .Normal: return "Normal"
        case .Increase: return "Increase"
        case .Decrease: return "Decrease"
        }
    }

    private func loadImage(_ source: Any, into imageView: UIImageView, token: inout String?) {
        let newToken = imageSourceToken(source)
        guard token != newToken else { return }

        token = newToken
        imageView.cancelImageLoad()
        imageView.image = nil
        imageView.loadImage(contentData: source)
    }

    private func imageSourceToken(_ source: Any) -> String {
        if let image = source as? UIImage {
            return "image:\(ObjectIdentifier(image)):\(image.size.width)x\(image.size.height)"
        }
        if let url = source as? URL {
            return "url:\(url.absoluteString)"
        }
        if let string = source as? String {
            return "string:\(string)"
        }
        if let data = source as? Data {
            return "data:\(data.count):\(data.hashValue)"
        }
        return String(reflecting: source)
    }

    @objc private func handleTap() {
        switch sortType {
        case .Normal:
            sortType = .Increase
        case .Increase:
            sortType = .Decrease
        case .Decrease:
            sortType = .Normal
        }
        sortTypeHandler?(sortType)
        accessibilityValue = accessibilitySortValue
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.size != lastLayoutSize || needsConstraintUpdate else { return }

        lastLayoutSize = bounds.size
        needsConstraintUpdate = false

        let safeImageSize = CGSize(width: max(0, imageSize.width), height: max(0, imageSize.height))
        let safeContentSpace = max(0, contentImageSpace)
        let safeImageSpace = max(0, imageSpace)
        let width = max(0, bounds.width)
        let height = max(0, bounds.height)
        let maxTitleWidth = max(0, width - safeContentSpace - safeImageSize.width)
        let measuredTitleWidth = min(maxTitleWidth,
                                     max(0, titleLabel.sizeThatFits(CGSize(width: maxTitleWidth,
                                                                            height: height)).width + 5))
        let titleLeft = max(0, (width - measuredTitleWidth - safeContentSpace - safeImageSize.width) / 2)
        let realImageSize: CGSize
        if showType == .Tres {
            let availableImageHeight = max(0, (height - safeImageSpace) / 2)
            realImageSize = CGSize(width: safeImageSize.width,
                                   height: min(safeImageSize.height, availableImageHeight))
        } else {
            realImageSize = CGSize(width: safeImageSize.width,
                                   height: min(safeImageSize.height, height))
        }

        titleLabel.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(titleLeft)
            make.width.equalTo(measuredTitleWidth)
        }

        upImage.snp.remakeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(safeContentSpace)
            make.size.equalTo(realImageSize)
            if showType == .Tres {
                make.bottom.equalTo(titleLabel.snp.centerY).offset(-(safeImageSpace / 2))
            } else {
                make.centerY.equalToSuperview()
            }
            make.right.lessThanOrEqualToSuperview()
        }

        if showType == .Tres {
            downImage.snp.remakeConstraints { make in
                make.left.right.equalTo(upImage)
                make.top.equalTo(upImage.snp.bottom).offset(safeImageSpace)
                make.height.equalTo(realImageSize.height)
            }
        }
    }

    public override var intrinsicContentSize: CGSize {
        let titleSize = titleLabel.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                        height: CGFloat.greatestFiniteMagnitude))
        let safeImageSize = CGSize(width: max(0, imageSize.width), height: max(0, imageSize.height))
        let width = titleSize.width + max(0, contentImageSpace) + safeImageSize.width
        let height = max(titleSize.height, showType == .Tres ? safeImageSize.height * 2 + max(0, imageSpace) : safeImageSize.height)
        return CGSize(width: width, height: height)
    }

    public override func accessibilityActivate() -> Bool {
        handleTap()
        return true
    }
}
