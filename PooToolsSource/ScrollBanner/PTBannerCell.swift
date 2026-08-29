//
//  PTBannerCell.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 30/3/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import AVFoundation
import AttributedString
import SwifterSwift
import SnapKit

@MainActor
public class PTBannerCell: PTBaseNormalCell {
    public static let ID = "PTBannerCell"
    
    let imageView = PTGAnimationImageView()
    let playerContainer = UIView()
    let playButton = UIButton()

    public var videoURL: String?
    var playAction: (() -> Void)?
    private var configurationToken = UUID()
    private var coverTask: Task<Void, Never>?

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

        playButton.addActionHandlers { [weak self] sender in
            guard let self else { return }
            self.playAction?()
            sender.isSelected.toggle()
        }
    }

    public required init?(coder: NSCoder) { super.init(coder: coder) }

    public override func layoutSubviews() {
        super.layoutSubviews()
        playerContainer.layer.sublayers?.compactMap { $0 as? AVPlayerLayer }.forEach { layer in
            layer.frame = playerContainer.bounds
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        configurationToken = UUID()
        coverTask?.cancel()
        coverTask = nil
        PTBannerPlayerManager.shared.stopIfContainerBelongs(to: playerContainer)
        imageView.imageSet = nil
        videoURL = nil
        playAction = nil
        playButton.isSelected = false
        playButton.isHidden = true
        playButton.isUserInteractionEnabled = false
    }

    public func configure(_ data: PTBannerModel,
                          placeholder: UIImage? = nil,
                          showPlayButton: Bool = true) {
        configurationToken = UUID()
        let token = configurationToken
        coverTask?.cancel()
        coverTask = nil
        imageView.contentMode = data.imageViewContentMode
        videoURL = nil
        playAction = nil
        playButton.isSelected = false
        playButton.isHidden = true
        playButton.isUserInteractionEnabled = false
        imageView.imageSet = placeholder

        if let mediaURL = mediaURL(from: data.media) {
            let mediaEX = mediaURL.pathExtension.lowercased()
            if GlobalVideoExts.contains(mediaEX) {
                videoURL = mediaURL.absoluteString
                playButton.isHidden = !showPlayButton
                playButton.isUserInteractionEnabled = showPlayButton

                coverTask = PTBannerVideoManager.shared.loadCover(url: mediaURL) { [weak self, token] image in
                    guard let self,
                          self.configurationToken == token,
                          let image else { return }
                    self.imageView.imageSet = image
                    self.coverTask = nil
                }
            } else {
                imageView.imageSet = mediaURL.absoluteString
            }
        } else if let media = data.media {
            // English: Apply non-URL media directly so UIImage, Data, and named assets are not replaced by the placeholder.
            // Español: Aplica directamente los medios que no son URL para no reemplazar UIImage, Data o recursos nombrados por el marcador.
            // 中文：直接应用非 URL 媒体，避免 UIImage、Data 和命名资源被占位图覆盖。
            imageView.imageSet = media
        }
        
        contentView.viewCornerRectCorner(radius: data.cellCornerRadius,corner: data.corner)
    }

    private func mediaURL(from media: Any?) -> URL? {
        if let url = media as? URL {
            return url
        }
        if let asset = media as? AVURLAsset {
            return asset.url
        }
        guard let value = media as? String else { return nil }
        let decoded = value.urlToUnicodeURLString() ?? value
        return URL(string: decoded)
    }
}
