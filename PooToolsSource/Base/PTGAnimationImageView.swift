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
    public var imageSet:Any? {
        didSet {
            if let findAny = imageSet {
                switch findAny {
                case let urlString as String:
                    if urlString.pathExtension.contains("json"),urlString.isURL(),let lottieURL = URL(string: urlString) {
                        Task { @MainActor in
                            let lottieAnimation = await LottieAnimation.loadedFrom(url: lottieURL)
                            if let findAnimation = lottieAnimation {
                                lottieView.isHidden = false
                                imageBG.isHidden = true
                                lottieView.animation = findAnimation
                                lottieView.play()
                            } else {
                                lottieView.isHidden = true
                                lottieView.stop()
                                imageBG.isHidden = false
                                imageBG.loadImage(contentData: urlString)
                            }
                        }
                    } else {
                        lottieView.isHidden = true
                        lottieView.stop()
                        imageBG.isHidden = false
                        imageBG.loadImage(contentData: urlString)
                    }
                default:
                    lottieView.isHidden = true
                    lottieView.stop()
                    imageBG.isHidden = false
                    imageBG.loadImage(contentData: findAny)
                }
            } else {
                lottieView.stop()
                lottieView.isHidden = true
                imageBG.isHidden = false
                imageBG.image = PTAppBaseConfig.share.defaultPlaceholderImage
            }
        }
    }
    
    private let lottieView = LottieAnimationView()
    private lazy var imageBG:UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = false
        return view
    }()

    public override init(frame:CGRect) {
        super.init(frame: frame)
        
        lottieView.contentMode = .scaleAspectFit
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
