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
    open var scorePercent : CGFloat = 1 {
        didSet {
            scorePercent = min(max(scorePercent,0),1)
        }
    }
    ///展示的数量,默认5个
    open var numberOfStar : Int = 5
    ///已经选择的图片
    open var fImage:UIImage = "🌟".emojiToImage(emojiFont: .appfont(size: 24))
    ///未选择的图片
    open var bImage:UIImage = "⭐️".emojiToImage(emojiFont: .appfont(size: 24))
    ///是否可以点击
    open var canTap:Bool = false
    ///是否有动画
    open var hadAnimation:Bool = false
    ///是否显示全星
    open var allowIncompleteStar:Bool = false
}

@objcMembers
public class PTRateView: UIView {
    open var rateBlock:PTRateScoreBlock?
    
    open var viewConfig:PTRateConfig? {
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

        for i in 0..<config.numberOfStar {
            let imageV = UIImageView(image: image)
            imageV.contentMode = .scaleAspectFit
            imageV.tag = tag + i
            contentV.addSubview(imageV)
            imageV.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(CGFloat(i) * self.frame.size.width / CGFloat(config.numberOfStar))
                make.top.bottom.equalToSuperview()
                make.width.equalTo(self.frame.size.width / CGFloat(config.numberOfStar))
            }
        }
        return contentV
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
