//
//  PTCroppingPresetCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

class PTVideoEditorCroppingPresetCell: PTBaseNormalCell {
    // MARK: Public Properties

    override var isSelected: Bool {
        didSet {
            updateUI()
        }
    }

    // MARK: Private Properties

    private lazy var stack: UIStackView = makeStackView()
    private lazy var title: UILabel = makeTitle()
    private lazy var imageView: UIImageView = makeImageView()

    private var viewModel: PTVideoEditorCroppingPresetCellViewModel!

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: Bindings

extension PTVideoEditorCroppingPresetCell {
    func configure(with viewModel: PTVideoEditorCroppingPresetCellViewModel) {
        title.text = viewModel.name
        imageView.image = Bundle.podBundleImage(bundleName:PTVideoEditorPodBundleName,imageName:viewModel.imageName)
    
        let scale = 48 / Bundle.podBundleImage(bundleName:PTVideoEditorPodBundleName,imageName:viewModel.imageName).size.width
        imageView.snp.remakeConstraints { make in
            make.width.equalTo(imageView.image!.size.width * scale)
            make.height.equalTo(imageView.image!.size.height * scale)
        }

        PTGCDManager.gcdMain {
            self.imageView.viewCorner(borderWidth: 1,borderColor: .lightGray)
        }
        
        self.viewModel = viewModel
    }
}

// MARK: UI

fileprivate extension PTVideoEditorCroppingPresetCell {
    func setupUI() {
        setupView()
        setupConstraints()
    }

    func setupView() {
        addSubview(stack)
    }

    func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(48)
        }
        
        stack.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
    }

    func updateUI() {
        title.font = isSelected ? .systemFont(ofSize: 12.0, weight: .medium) : .systemFont(ofSize: 12.0)
        imageView.tintColor = isSelected ? .croppingPresetSelected : .croppingPreset
    }

    func makeTitle() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12.0)
        label.textColor = UIColor.foreground
        return label
    }

    func makeImageView() -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.tintColor = .croppingPreset
        return view
    }

    func makeStackView() -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [
            imageView,
            title
        ])

        stack.spacing = 10.0
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        return stack
    }
}
