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

@objcMembers
public class PTRateView: UIView {
    public var rateBlock:PTRateScoreBlock?
    
    public var viewConfig:PTRateConfig? {
        didSet {
            guard let config = viewConfig else { return }
            scorePercent = config.scorePercent
            removeSubviews()
            loaded = false
            initView()
        }
    }
    fileprivate lazy var backgroundStarView:UIView = createStartView(image: viewConfig!.bImage, tag: PTRateBackgroundViewTags)
    fileprivate lazy var foregroundStarView:UIView = createStartView(image: viewConfig!.fImage, tag: PTRateForegroundViewTags)

    fileprivate var scorePercent:CGFloat? = 0 {
        didSet {
            guard let scorePercent = scorePercent else { return }
            PTGCDManager.gcdAfter(time: 0.1) {
                self.layoutSubviews()
            }
            
            rateBlock?(scorePercent)
        }
    }
    
    fileprivate var loaded:Bool = false
    
    public init(viewConfig:PTRateConfig) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
        initView()
    }
    
    func initView() {
        guard let config = viewConfig else { return }
        if config.canTap {
            let tapGes = UITapGestureRecognizer { [weak self] sender in
                guard let self = self else { return }
                let ges = sender as! UITapGestureRecognizer
                let tapPoint = ges.location(in: self)
                self.handleTapGesture(tapPoint)
            }
            tapGes.numberOfTapsRequired = 1
            addGestureRecognizers([tapGes])
        }
        
        scorePercent = config.scorePercent

        PTGCDManager.gcdAfter(time: 0.1) {
            self.addSubviews([self.backgroundStarView,self.foregroundStarView])

            self.backgroundStarView.snp.makeConstraints({ make in
                make.edges.equalToSuperview()
            })
            
            self.foregroundStarView.snp.makeConstraints({ make in
                make.top.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.width.equalTo(0)
            })
            
            self.updateForegroundStarViewWidth(animated: config.hadAnimation)
            self.loaded = true
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    fileprivate func handleTapGesture(_ tapPoint: CGPoint) {
        guard let config = viewConfig else { return }
        let offSet = tapPoint.x
        let realStarScore = offSet / (self.frame.size.width / CGFloat(config.numberOfStar))
        let starScore = config.allowIncompleteStar ? Float(realStarScore) : ceilf(Float(realStarScore))
        self.scorePercent = CGFloat(starScore) / CGFloat(config.numberOfStar)
        self.updateForegroundStarViewWidth(animated: config.hadAnimation)
    }
        
    fileprivate func updateForegroundStarViewWidth(animated: Bool = false) {
        guard let scorePercent = scorePercent else { return }
        let foregroundWidth = self.frame.size.width * scorePercent
        let animationTimeInterval = animated ? 0.2 : 0
        UIView.animate(withDuration: animationTimeInterval) {
            self.foregroundStarView.snp.updateConstraints { make in
                make.width.equalTo(foregroundWidth)
            }
        }
    }

    fileprivate func createStartView(image: UIImage, tag: Int) -> UIView {
        guard let config = viewConfig else { return UIView() }
        let contentV = UIView()
        contentV.clipsToBounds = true
        contentV.backgroundColor = .clear
        contentV.isUserInteractionEnabled = tag == PTRateForegroundViewTags ? true : false

        let itemW = (self.frame.size.width - config.itemSpacing * CGFloat(config.numberOfStar - 1)) / CGFloat(config.numberOfStar)
        
        for i in 0..<config.numberOfStar {
            let imageV = UIImageView(image: image)
            imageV.contentMode = config.imageContentMode
            imageV.tag = tag + i
            contentV.addSubview(imageV)
            imageV.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(CGFloat(i) * itemW + config.itemSpacing * CGFloat(i))
                make.top.bottom.equalToSuperview()
                make.width.equalTo(itemW)
            }
        }
        return contentV
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
