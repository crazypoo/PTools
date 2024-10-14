//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

final class ElementNameView: LayerViewComponent {
    // MARK: - Properties

    private var contentFrame: CGRect = .zero {
        didSet {
            guard oldValue != contentFrame else { return }
            updateViews()
        }
    }

    private var contentFrameObserver: NSKeyValueObservation? {
        didSet {
            oldValue?.invalidate()
        }
    }

    enum DisplayMode: Swift.CaseIterable, MenuContentProtocol {
        case auto, iconAndText, text, icon

        var title: String {
            switch self {
            case .auto: return "Automatic"
            case .iconAndText: return "Icon And Text"
            case .text: return "Text"
            case .icon: return "Icon"
            }
        }

        var image: UIImage? { .none }

        static func allCases(for element: ViewHierarchyElementReference) -> [DisplayMode] { allCases }
    }

    override var tintColor: UIColor! {
        didSet {
            updateColors()
        }
    }

    var displayMode: DisplayMode = .auto {
        didSet {
            animate {
                self.updateViews()
            }
        }
    }

    var name: String? {
        get { label.text }
        set {
            label.text = newValue
            debounce(#selector(updateViews), after: .veryShort)
        }
    }

    var image: UIImage? {
        get { imageView.image }
        set {
            imageView.image = newValue
            debounce(#selector(updateViews), after: .veryShort)
        }
    }

    private let cornerRadius: CGFloat = 8

    private let contentColor: UIColor = .white

    // MARK: - Components

    private(set) lazy var label = UILabel().then {
        $0.font = UIFont(name: "MuktaMahee-Regular", size: 11)
        $0.textColor = contentColor
        $0.textAlignment = .center
    }

    private lazy var imageView = UIImageView().then {
        $0.tintColor = contentColor
    }

    private(set) lazy var roundedPillView = LayerViewComponent().then {
        $0.clipsToBounds = true
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.layer.borderWidth = 1 / UIScreen.main.scale

        $0.contentView.addArrangedSubviews(imageView, label)
        $0.contentView.alignment = .center
        $0.contentView.axis = .horizontal
        $0.contentView.spacing = cornerRadius / 2

        $0.contentView.layer.shadowOffset = CGSize(width: 0, height: 1)
        $0.contentView.layer.shadowOpacity = 1
        $0.contentView.layer.shadowRadius = 1

        enableRasterization()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        contentFrameObserver = superview?
            .layer
            .observe(\.bounds) { [weak self] layer, _ in
                guard let self = self else { return }
                self.contentFrame = layer.frame
            }
    }

    override func setup() {
        super.setup()

        resetShadow()

        installView(roundedPillView, .autoResizingMask)

        updateColors()

        enableRasterization()
    }

    deinit {
        contentFrameObserver = nil
    }

    func resetShadow() {
        layer.shadowOffset = .init(width: .zero, height: 1)
        layer.shadowOpacity = Float(colorStyle.disabledAlpha * 2)
        layer.shadowRadius = 1
    }

    @objc
    private func updateColors() {
        
        let darkerTintColor = tintColor.darkened(amount: 2 / 3)

        layer.shadowColor = darkerTintColor.cgColor
        roundedPillView.contentView.layer.shadowColor = darkerTintColor.cgColor
        roundedPillView.layer.borderColor = darkerTintColor.cgColor
        roundedPillView.backgroundColor = tintColor
    }

    @objc
    private func updateViews() {
        switch displayMode {
        case .iconAndText:
            label.isHidden = false
            imageView.isHidden = false

        case .text:
            label.isHidden = false
            imageView.isHidden = true

        case .icon:
            label.isHidden = true
            imageView.isHidden = false

        case .auto:
            layoutIfNeededAndCalculateContentThatFits()
        }

        label.alpha = label.isHidden ? 0 : 1
        imageView.alpha = imageView.isHidden ? 0 : 1
        roundedPillView.contentView.directionalLayoutMargins = .init(
            top: 1,
            leading: imageView.isHidden ? 6 : 3,
            bottom: 1,
            trailing: label.isHidden ? 3 : 6
        )
    }

    private func layoutIfNeededAndCalculateContentThatFits() {
        // 1. Un-hide subviews
        label.isHidden = name.isNilOrEmpty
        imageView.isHidden = image == nil

        // 2. Calculate fitting size layout
        roundedPillView.layoutIfNeeded()
        let fittingSize = systemLayoutSizeFitting(contentFrame.size)

        // 3. If there is enough space available show the label
        label.isHidden = !label.text.isNilOrEmpty && fittingSize.width > contentFrame.width * 1.15
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        roundedPillView.layer.cornerRadius = min(cornerRadius, roundedPillView.frame.height / 2)
    }
}
