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
    public var scorePercent: CGFloat = 1 {
        didSet { scorePercent = min(max(scorePercent, 0), 1) }
    }
    public var numberOfStar: Int = 5
    public var fImage: UIImage = "🌟".emojiToImage(emojiFont: .appfont(size: 24))
    public var bImage: UIImage = "⭐️".emojiToImage(emojiFont: .appfont(size: 24))
    public var canTap: Bool = false
    public var hadAnimation: Bool = false
    public var allowIncompleteStar: Bool = false
    public var itemSpacing: CGFloat = 0
    public var imageContentMode: UIView.ContentMode = .scaleAspectFill
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

        // 优化：只有当已有的子视图数量与配置的星星数量不一致时，才重新创建 View。
        if backgroundStarView.subviews.count != config.numberOfStar {
            backgroundStarView.removeSubviews()
            createStars(in: backgroundStarView, image: config.bImage, baseTag: PTRateBackgroundViewTags)
        } else {
            // 数量一致，只更新图片和显示模式
            updateExistingStars(in: backgroundStarView, image: config.bImage, baseTag: PTRateBackgroundViewTags)
        }

        if foregroundStarView.subviews.count != config.numberOfStar {
            foregroundStarView.removeSubviews()
            createStars(in: foregroundStarView, image: config.fImage, baseTag: PTRateForegroundViewTags)
        } else {
            updateExistingStars(in: foregroundStarView, image: config.fImage, baseTag: PTRateForegroundViewTags)
        }

        if config.canTap {
            addGestures()
        } else {
            gestureRecognizers?.forEach { removeGestureRecognizer($0) }
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
        if count == 0 { return }
        
        let totalSpacing = config.itemSpacing * CGFloat(count - 1)
        let itemW = (bounds.width - totalSpacing) / CGFloat(count)

        for i in 0..<count {
            let left = CGFloat(i) * (itemW + config.itemSpacing)
            let frame = CGRect(x: left, y: 0, width: itemW, height: bounds.height)
            
            if let bg = backgroundStarView.viewWithTag(PTRateBackgroundViewTags + i) {
                bg.frame = frame
            }
            if let fg = foregroundStarView.viewWithTag(PTRateForegroundViewTags + i) {
                fg.frame = frame
            }
        }
    }

    private func updateForegroundWidth(animated: Bool) {
        let width = bounds.width * scorePercent
        foregroundStarView.snp.updateConstraints { make in
            make.width.equalTo(width)
        }
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        } else {
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
    
    // 性能优化：更新已有星星的属性
    private func updateExistingStars(in container: UIView, image: UIImage, baseTag: Int) {
        guard let config = viewConfig else { return }
        for i in 0..<config.numberOfStar {
            if let imgV = container.viewWithTag(baseTag + i) as? UIImageView {
                imgV.image = image
                imgV.contentMode = config.imageContentMode
            }
        }
    }

    // MARK: Touch Logic (Tap & Pan)
    private func addGestures() {
        gestureRecognizers?.forEach { removeGestureRecognizer($0) }
        
        // 体验升级：同时支持点击和滑动
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTouch(_:)))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleTouch(_:)))
        
        addGestureRecognizer(tap)
        addGestureRecognizer(pan)
    }

    @objc private func handleTouch(_ gesture: UIGestureRecognizer) {
        guard let config = viewConfig else { return }

        let x = gesture.location(in: self).x
        let count = CGFloat(config.numberOfStar)
        
        // 安全处理：防止除数为0的情况
        guard count > 0, bounds.width > 0 else { return }
        
        // 精确度修复：将间距 itemSpacing 计算在内
        let totalSpacing = config.itemSpacing * (count - 1)
        let itemW = (bounds.width - totalSpacing) / count
        let unitWidth = itemW + config.itemSpacing // 每一组（星星+间距）的跨度
        
        var score: CGFloat = 0
        
        // 边界限制处理
        if x <= 0 {
            score = 0
        } else if x >= bounds.width {
            score = count
        } else {
            // 计算当前触摸点在第几个星星的区间内
            let index = Int(x / unitWidth)
            // 计算在该区间内偏移了多少
            let remainder = x.truncatingRemainder(dividingBy: unitWidth)
            
            if config.allowIncompleteStar {
                // 半星/精确模式：如果触摸点落在间距上，得分最高也就是填满当前星星 (remainder / itemW 最高为 1)
                let fraction = min(remainder / itemW, 1.0)
                score = CGFloat(index) + fraction
            } else {
                // 整星模式：只要摸到了这个星星所在的区间（哪怕是一点点），就给一颗完整的星
                score = CGFloat(index) + (remainder > 0 ? 1 : 0)
            }
        }
        
        scorePercent = min(max(score / count, 0), 1)

        // 如果是手势滑动过程，取消动画跟随手指；如果是点击结束，则播放动画
        let isPanning = (gesture as? UIPanGestureRecognizer)?.state == .changed
        updateForegroundWidth(animated: config.hadAnimation && !isPanning)
        
        rateBlock?(scorePercent)
    }
}
