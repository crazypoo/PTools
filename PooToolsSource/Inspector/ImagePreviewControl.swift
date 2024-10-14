//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ImagePreviewControlDelegate: AnyObject {
    func imagePreviewControlDidTap(_ imagePreviewControl: ImagePreviewControl)
}

final class ImagePreviewControl: BaseFormControl {
    // MARK: - Properties

    weak var delegate: ImagePreviewControlDelegate?

    var image: UIImage? {
        didSet {
            didUpdateImage()
        }
    }

    func updateSelectedImage(_ image: UIImage?) {
        self.image = image

        sendActions(for: .valueChanged)
    }

    override var isEnabled: Bool {
        didSet {
            tapGestureRecognizer.isEnabled = isEnabled
            accessoryControl.isEnabled = isEnabled
        }
    }

    private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapImage))

    private lazy var imageContainerView = UIImageView(image: IconKit.imageOfColorGrid().resizableImage(withCapInsets: .zero)).then {
        $0.backgroundColor = colorStyle.backgroundColor

        $0.clipsToBounds = true
        $0.layer.cornerRadius = 5

        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.setContentHuggingPriority(.required, for: .vertical)

        $0.heightAnchor.constraint(equalToConstant: elementInspectorAppearance.horizontalMargins).isActive = true

        $0.installView(imageView)
    }

    private lazy var imageView = UIImageView(image: image).then {
        $0.contentMode = .scaleAspectFit
    }

    private lazy var imageNameLabel = UILabel(
        .textStyle(.footnote),
        .textColor(colorStyle.textColor),
        .huggingPriority(.defaultHigh, for: .horizontal)
    )

    private(set) lazy var accessoryControl = AccessoryControl().then {
        $0.addGestureRecognizer(tapGestureRecognizer)

        $0.clipsToBounds = true

        $0.contentView.addArrangedSubview(imageNameLabel)

        $0.contentView.addArrangedSubview(imageContainerView)
    }

    // MARK: - Init

    init(title: String?, image: UIImage?) {
        self.image = image

        super.init(title: title)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        axis = .vertical

        titleLabel.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)

        contentView.addArrangedSubview(accessoryControl)

        didUpdateImage()
    }

    private func didUpdateImage() {
        imageView.image = image

        guard let image = image else {
            imageNameLabel.text = "None"
            return
        }

        imageNameLabel.text = image.assetName ?? image.sizeDesription
    }

    @objc private func tapImage() {
        delegate?.imagePreviewControlDidTap(self)
    }
}
