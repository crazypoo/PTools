//
//  PTGAnimationImageView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 17/7/2026.
//  Copyright © 2026 crazypoo. All rights reserved.
//

import UIKit
import Lottie

open class PTGAnimationImageView: UIView {
    private var lastRasterSource: String?
    private var lastRasterTargetSize: CGSize = .zero

    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let source = imageSet as? String,
              source == lastRasterSource,
              source.isURL(),
              let url = URL(string: source),
              !["json", "gif", "svg", "webp", "mp4", "mov"].contains(url.pathExtension.lowercased()),
              bounds.width > 0, bounds.height > 0 else { return }
        let desired = bounds.size
        // Re-request only if the layout needs materially more pixels.
        // Prevents blurry category logos and home tiles after async layout/Duo resizing.
        guard desired.width > lastRasterTargetSize.width * 1.15 ||
              desired.height > lastRasterTargetSize.height * 1.15 else { return }
        lastRasterTargetSize = desired
        imageBG.loadImage(contentData: source,
                          emptyImage: PTAppBaseConfig.share.defaultPlaceholderImage,
                          targetSize: desired)
    }

    public var imageSet:Any? {
        didSet {
            if let findAny = imageSet {
                switch findAny {
                case let urlString as String:
                    if let lottieURL = URL(string: urlString),
                       lottieURL.pathExtension.contains("json"),
                       urlString.isURL() {
                        Task { @MainActor [weak self] in
                            let lottieAnimation = await LottieAnimation.loadedFrom(url: lottieURL)
                            // Reused cells may bind a different source while the JSON is
                            // downloading. Never let the old result hide the new image.
                            guard let self, (self.imageSet as? String) == urlString else { return }
                            if let findAnimation = lottieAnimation {
                                lottieView.isHidden = false
                                imageBG.isHidden = true
                                lottieView.animation = findAnimation
                                lottieView.play()
                            } else {
                                imageSet(media: urlString)
                            }
                        }
                    } else {
                        imageSet(media: urlString)
                    }
                default:
                    imageSet(media: findAny)
                }
            } else {
                imageSet(media: PTAppBaseConfig.share.defaultPlaceholderImage)
            }
        }
    }
    
    private func imageSet(media:Any) {
        lottieView.stop()
        lottieView.isHidden = true
        imageBG.isHidden = false
        let target = bounds.width > 0 && bounds.height > 0 ? bounds.size : nil
        lastRasterSource = media as? String
        lastRasterTargetSize = target ?? .zero
        imageBG.loadImage(contentData: media,
                          emptyImage: PTAppBaseConfig.share.defaultPlaceholderImage,
                          targetSize: target)
    }
    
    public override var contentMode: UIView.ContentMode {
        didSet {
            imageBG.contentMode = contentMode
            lottieView.contentMode = contentMode
        }
    }
    
    private let lottieView = LottieAnimationView()
    private lazy var imageBG:UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = false
        return view
    }()

    public override init(frame:CGRect) {
        super.init(frame: frame)
        
        lottieView.clipsToBounds = false
        lottieView.isHidden = true
        lottieView.loopMode = .autoReverse
        addSubviews([lottieView,imageBG])
        lottieView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        imageBG.isHidden = true
        imageBG.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
