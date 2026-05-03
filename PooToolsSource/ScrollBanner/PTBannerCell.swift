//
//  PTBannerCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import AttributedString
import SwifterSwift
import SnapKit

public class PTBannerCell: PTBaseNormalCell {
    public static let ID = "PTBannerCell"
    
    let imageView = UIImageView()
    let playerContainer = UIView()
    let playButton = UIButton()

    public var videoURL: String?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.clipsToBounds = true

        contentView.addSubviews([imageView,playerContainer,playButton])

        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        playerContainer.snp.makeConstraints { $0.edges.equalToSuperview() }
        playButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(44)
        }
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        videoURL = nil
        playerContainer.layer.sublayers?.removeAll()
    }

    public func configure(_ data: PTBannerModel) {
        imageView.contentMode = data.imageViewContentMode
        if let url = data.media as? String,let urlString = url.urlToUnicodeURLString(),let mediaURL = URL(string: urlString) {
            let mediaReal = mediaURL.absoluteString
            let mediaEX =  mediaReal.pathExtension.lowercased()
            if GlobalVideoExts.contains(mediaEX) {
                videoURL = mediaReal
                playButton.isHidden = false
                playButton.isUserInteractionEnabled = true

                PTBannerVideoManager.shared.loadCover(url: mediaReal) { [weak self] img in
                    self?.imageView.image = img
                    if let _ = PTVideoFileCache.shared.cachedFileURL(for: mediaURL) {
                    } else {
                        PTVideoFileCache.shared.prepareVideo(url: mediaURL) { _ in }
                    }
                }
            } else {
                playButton.isHidden = true
                playButton.isUserInteractionEnabled = false
                imageView.loadImage(contentData: url)
            }
        } else {
            playButton.isHidden = true
            playButton.isUserInteractionEnabled = false
            imageView.loadImage(contentData: data)
        }
        
        contentView.viewCornerRectCorner(radius: data.cellCornerRadius,corner: data.corner)
    }
}
