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
    public var scorePercent : CGFloat = 1
    {
        didSet
        {
            if scorePercent > 1
            {
                scorePercent = 1
            }
            else if scorePercent < 0
            {
                scorePercent = 0
            }
        }
    }
    ///展示的数量,默认5个
    public var numberOfStar : Int = 5
    ///已经选择的图片
    public var fImage:UIImage = UIColor.red.createImageWithColor()
    ///未选择的图片
    public var bImage:UIImage = UIColor.blue.createImageWithColor()
    ///是否可以点击
    public var canTap:Bool = false
    ///是否有动画
    public var hadAnimation:Bool = false
    ///是否显示全星
    public var allowIncompleteStar:Bool = false
}

@objcMembers
public class PTRateView: UIView {
    public var rateBlock:PTRateScoreBlock?
    
    public var viewConfig:PTRateConfig? = PTRateConfig()
    {
        didSet
        {
            self.scorePercent = self.viewConfig!.scorePercent
            self.removeSubviews()
            self.layoutSubviews()
        }
    }
    fileprivate lazy var backgroundStarView:UIView = self.createStartView(image: self.viewConfig!.bImage, tag: PTRateBackgroundViewTags)
    fileprivate lazy var foregroundStarView:UIView = self.createStartView(image: self.viewConfig!.fImage, tag: PTRateForegroundViewTags)

    fileprivate var scorePercent:CGFloat? = 0
    {
        didSet
        {
            PTUtils.gcdAfter(time: 0.1) {
                self.layoutSubviews()
            }
            
            if self.rateBlock != nil
            {
                self.rateBlock!(self.scorePercent!)
            }
        }
    }
    
    public init(viewConfig:PTRateConfig)
    {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
        
        if self.viewConfig!.canTap
        {
            let tapGes = UITapGestureRecognizer.init { sender in
                let ges = sender as! UITapGestureRecognizer
                let tapPoint = ges.location(in: self)
                let offSet = tapPoint.x
                let realStartScore = offSet / (self.frame.size.width / CGFloat(self.viewConfig!.numberOfStar))
                let starScore = self.viewConfig!.allowIncompleteStar ? Float(realStartScore) : ceilf(Float(realStartScore))
                self.scorePercent = CGFloat(starScore) / CGFloat(self.viewConfig!.numberOfStar)
            }
            tapGes.numberOfTapsRequired = 1
            self.addGestureRecognizer(tapGes)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.addSubviews([self.backgroundStarView,self.foregroundStarView])

        self.backgroundStarView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        self.foregroundStarView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        
        let animationTimeInterval = self.viewConfig!.hadAnimation ? 0.2 : 0
        UIView.animate(withDuration: animationTimeInterval) {
            self.foregroundStarView.frame = CGRect.init(x: 0, y: 0, width: self.frame.size.width * self.scorePercent!, height: self.frame.size.height)
        }
    }
    
    fileprivate func createStartView(image:UIImage,tag:Int) ->UIView
    {
        let contentV = UIView()
        contentV.clipsToBounds = true
        contentV.backgroundColor = .clear
        
        for i in 0..<self.viewConfig!.numberOfStar
        {
            let imageV = UIImageView(image: image)
            imageV.contentMode = .scaleAspectFit
            imageV.tag = tag + i
            contentV.addSubview(imageV)
            imageV.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(CGFloat(i) * self.frame.size.width / CGFloat(self.viewConfig!.numberOfStar))
                make.top.bottom.equalToSuperview()
                make.width.equalTo(self.frame.size.width / CGFloat(self.viewConfig!.numberOfStar))
            }
        }
        return contentV
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
