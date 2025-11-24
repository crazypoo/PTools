//
//  PTRateView.swift
//  PooTools_Example
//
//  Created by jax on 2022/8/29.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

public typealias PTRateScoreBlock = (_ score:CGFloat) -> Void

let PTRateBackgroundViewTags = 4567
let PTRateForegroundViewTags = 7654

@objcMembers
public class PTRateConfig: NSObject {
    ///默认得分范围0~1默认1
    public var scorePercent : CGFloat = 1 {
        didSet {
            scorePercent = min(max(scorePercent,0),1)
        }
    }
    ///展示的数量,默认5个
    public var numberOfStar : Int = 5
    ///已经选择的图片
    public var fImage:UIImage = "🌟".emojiToImage(emojiFont: .appfont(size: 24))
    ///未选择的图片
    public var bImage:UIImage = "⭐️".emojiToImage(emojiFont: .appfont(size: 24))
    ///是否可以点击
    public var canTap:Bool = false
    ///是否有动画
    public var hadAnimation:Bool = false
    ///是否显示全星
    public var allowIncompleteStar:Bool = false
    ///圖片間隔
    public var itemSpacing:CGFloat = 0
    ///圖片展示模式
    public var imageContentMode:UIView.ContentMode = .scaleAspectFill
}

// MARK: - View
@objcMembers
public class PTRateView: UIView {

    // MARK: Public
    public var rateBlock: PTRateScoreBlock?
    public var viewConfig: PTRateConfig? {
        didSet {
            guard let config = viewConfig else { return }
            scorePercent = config.scorePercent
            reloadUI()
        }
    }

    // MARK: Private
    private var scorePercent: CGFloat = 1
    private var isPrepared = false
    
    private let backgroundStarView = UIView()
    private let foregroundStarView = UIView()

    // MARK: - Init
    public init(viewConfig: PTRateConfig) {
        self.viewConfig = viewConfig
        super.init(frame: .zero)
        setupBaseUI()
        reloadUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Setup
    private func setupBaseUI() {
        backgroundColor = .clear
        
        addSubviews([backgroundStarView, foregroundStarView])
        backgroundStarView.clipsToBounds = true
        foregroundStarView.clipsToBounds = true

        backgroundStarView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        foregroundStarView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(0)
        }
    }

    private func reloadUI() {
        guard let config = viewConfig else { return }

        backgroundStarView.removeSubviews()
        foregroundStarView.removeSubviews()

        createStars(in: backgroundStarView,
                    image: config.bImage,
                    baseTag: PTRateBackgroundViewTags)

        createStars(in: foregroundStarView,
                    image: config.fImage,
                    baseTag: PTRateForegroundViewTags)

        if config.canTap {
            addTapGesture()
        }

        setNeedsLayout()
        layoutIfNeeded()
        updateForegroundWidth(animated: config.hadAnimation)
    }

    // MARK: Layout
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        updateStarFrames()
        updateForegroundWidth(animated: false)
    }

    private func updateStarFrames() {
        guard let config = viewConfig else { return }
        
        let count = config.numberOfStar
        let totalSpacing = config.itemSpacing * CGFloat(count - 1)
        let itemW = (bounds.width - totalSpacing) / CGFloat(count)

        for i in 0..<count {
            let left = CGFloat(i) * (itemW + config.itemSpacing)
            
            if let bg = backgroundStarView.viewWithTag(PTRateBackgroundViewTags + i) {
                bg.frame = CGRect(x: left, y: 0, width: itemW, height: bounds.height)
            }
            if let fg = foregroundStarView.viewWithTag(PTRateForegroundViewTags + i) {
                fg.frame = CGRect(x: left, y: 0, width: itemW, height: bounds.height)
            }
        }
    }

    private func updateForegroundWidth(animated: Bool) {
        let width = bounds.width * scorePercent
        foregroundStarView.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
        
        UIView.animate(withDuration: animated ? 0.2 : 0.0) {
            self.layoutIfNeeded()
        }
    }

    // MARK: Stars Builder
    private func createStars(in container: UIView, image: UIImage, baseTag: Int) {
        guard let config = viewConfig else { return }

        for i in 0..<config.numberOfStar {
            let imgV = UIImageView(image: image)
            imgV.contentMode = config.imageContentMode
            imgV.tag = baseTag + i
            container.addSubview(imgV)
        }
    }

    // MARK: Tap Logic
    private func addTapGesture() {
        gestureRecognizers?.forEach { removeGestureRecognizer($0) }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap(_ tap: UITapGestureRecognizer) {
        guard let config = viewConfig else { return }

        let x = tap.location(in: self).x
        let starWidth = bounds.width / CGFloat(config.numberOfStar)
        
        let raw = x / starWidth
        let score = config.allowIncompleteStar ? CGFloat(raw) : CGFloat(ceil(raw))
        
        scorePercent = min(max(score / CGFloat(config.numberOfStar), 0), 1)

        updateForegroundWidth(animated: config.hadAnimation)
        rateBlock?(scorePercent)
    }
}
