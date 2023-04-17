//
//  PTCoinAnimation.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift
import SnapKit

@objcMembers
public class PTCoinAnimation: UIView {

    public var animationBlock:AnimationFinishBlock?
    
    public var iconImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
    lazy var emitterLayer = CAEmitterLayer()
    
    public lazy var showLabel:UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        view.textColor = UIColor.colorBase(R: 254/255, G: 211/255, B: 10/255, A: 1)
        view.isHidden = true
        return view
    }()

    lazy var backgroundView:UIView = {
        let view = UIView()
        view.backgroundColor = .blue.withAlphaComponent(0.6)
        view.isHidden = true
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubviews([self.showLabel,self.backgroundView])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.showLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        
        self.backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.emitterLayer.frame = CGRect(x: 0, y: 0, width: self.showLabel.frame.size.width, height: self.showLabel.frame.size.height)
        self.showLabel.layer.addSublayer(self.emitterLayer)
        self.emitterLayer.emitterShape = .circle
        self.emitterLayer.emitterMode = .outline
        self.emitterLayer.emitterPosition = CGPoint(x: self.showLabel.frame.size.width / 2, y: self.showLabel.frame.size.height / 2)
        self.emitterLayer.emitterSize = CGSize(width: 20, height: 20)
        
        let cell = CAEmitterCell()
        cell.name = "zanShape"
        cell.contents = self.iconImage.cgImage
        cell.alphaSpeed = -0.5
        cell.lifetime = 3
        cell.birthRate = 0
        cell.velocity = 300
        cell.velocityRange = 100
        cell.emissionRange = .pi / 8
        cell.emissionLatitude = -.pi
        cell.emissionLongitude = -.pi / 2
        cell.yAcceleration = 250
        self.emitterLayer.emitterCells = [cell]
    }
    
    public func beginAnimationFunction() {
        self.showLabel.isHidden = false
        self.backgroundView.isHidden = false
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5,options: .curveLinear) {
            let effectAnimation = CABasicAnimation(keyPath: "emitterCells.zanShape.birthRate")
            effectAnimation.fromValue = 30
            effectAnimation.toValue = 0
            effectAnimation.duration = 0
            effectAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.emitterLayer.add(effectAnimation, forKey: "zanCount")
            
            let aniScale = CABasicAnimation(keyPath: "transform.scale")
            aniScale.fromValue = 0.5
            aniScale.toValue = 3
            aniScale.duration = 1.5
            aniScale.delegate = self
            aniScale.isRemovedOnCompletion = false
            aniScale.repeatCount = 1
            self.showLabel.layer.add(aniScale, forKey: "babyCoin_scale")
        }
        
        UIView.animate(withDuration: 3) {
            self.backgroundView.alpha = 0
        }
    }
    
    func babyCoinFadeAway() {
        let aniMove = CABasicAnimation(keyPath: "position")
        aniMove.fromValue = self.showLabel.layer.position
        aniMove.toValue = CGPoint(x: CGFloat.kSCREEN_WIDTH, y: CGFloat.kSCREEN_HEIGHT)
        
        let aniScale = CABasicAnimation(keyPath: "transform.scale")
        aniScale.fromValue = 3
        aniScale.toValue = 0.5
        
        let aniGroup = CAAnimationGroup()
        aniGroup.duration = 1
        aniGroup.repeatCount = 1
        aniGroup.delegate = self
        aniGroup.animations = [aniMove,aniScale]
        aniGroup.isRemovedOnCompletion = false
        
        self.showLabel.layer.removeAllAnimations()
        self.showLabel.layer.add(aniGroup, forKey: "aniMove_aniScale_groupAnimation")
    }
}

extension PTCoinAnimation:CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim == self.showLabel.layer.animation(forKey: "babyCoin_scale") {
            self.babyCoinFadeAway()
            if self.animationBlock != nil {
                self.animationBlock!(true)
            }
        }
        
        if anim == self.showLabel.layer.animation(forKey: "aniMove_aniScale_groupAnimation") {
            self.showLabel.isHidden = true
            self.backgroundView.alpha = 0.6
            self.backgroundView.isHidden = true
        }
    }
}
