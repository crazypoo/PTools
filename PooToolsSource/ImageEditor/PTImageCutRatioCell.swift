//
//  PTImageCutRatioCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit

#if SWIFT_PACKAGE
// English: Import Core explicitly for the shared collection cell base class.
// Español: Importamos Core explícitamente para la clase base compartida de celdas.
// 中文：显式导入 Core，使用共享的列表 Cell 基类。
import ptools
#endif

//MARK: Cut Image
class PTImageCutRatioCell: PTBaseNormalCell {
    static let ID = "PTImageCutRatioCell"
        
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 3
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        PTUIAccessibility.applyDynamicType(to: label, font: PTImageEditorConfig.share.cutTitleFont)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.shadowColor = UIColor.black.withAlphaComponent(0.3).cgColor
        label.layer.shadowOffset = .zero
        label.layer.shadowOpacity = 1
        return label
    }()
    
    var image: UIImage?
    
    var ratio: PTImageClipRatio?
    private var previewWidthConstraint: Constraint?
    private var previewHeightConstraint: Constraint?
    private var lastPreviewSize = CGSize.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([imageView,titleLabel])
        imageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-14)
            previewWidthConstraint = make.width.equalTo(65).constraint
            previewHeightConstraint = make.height.equalTo(65).constraint
        }
        
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let ratio = ratio, let image = image else {
            return
        }
        
        var w: CGFloat = 0, h: CGFloat = 0
        let imageMaxW = min(max(1, bounds.width - 15), max(1, bounds.height - 28))
        if ratio.whRatio == 0 {
            let maxSide = max(image.size.width, image.size.height)
            w = imageMaxW * image.size.width / maxSide
            h = imageMaxW * image.size.height / maxSide
        } else {
            if ratio.whRatio >= 1 {
                w = imageMaxW
                h = w / ratio.whRatio
            } else {
                h = imageMaxW
                w = h * ratio.whRatio
            }
        }
        guard w.isFinite, h.isFinite, w > 0, h > 0 else { return }
        imageView.layer.cornerRadius = ratio.isCircle ? min(w, h) / 2 : 3
        let size = CGSize(width: w, height: h)
        if size != lastPreviewSize {
            lastPreviewSize = size
            previewWidthConstraint?.update(offset: w)
            previewHeightConstraint?.update(offset: h)
        }
    }
        
    func configureCell(image: UIImage, ratio: PTImageClipRatio) {
        imageView.image = image
        titleLabel.text = ratio.title
        self.image = image
        self.ratio = ratio
        
        setNeedsLayout()
    }
}
