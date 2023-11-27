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

    open var animationBlock:AnimationFinishBlock?
    
    open var iconImage:UIImage = UIColor.randomColor.createImageWithColor().transformImage(size: CGSize(width: 44, height: 44))
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
        
        addSubviews([showLabel, backgroundView])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        showLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emitterLayer.frame = CGRect(x: 0, y: 0, width: showLabel.frame.size.width, height: showLabel.frame.size.height)
        showLabel.layer.addSublayer(emitterLayer)
        emitterLayer.emitterShape = .circle
        emitterLayer.emitterMode = .outline
        emitterLayer.emitterPosition = CGPoint(x: showLabel.frame.size.width / 2, y: showLabel.frame.size.height / 2)
        emitterLayer.emitterSize = CGSize(width: 20, height: 20)
        
        let cell = CAEmitterCell()
        cell.name = "zanShape"
        cell.contents = iconImage.cgImage
        cell.alphaSpeed = -0.5
        cell.lifetime = 3
        cell.birthRate = 0
        cell.velocity = 300
        cell.velocityRange = 100
        cell.emissionRange = .pi / 8
        cell.emissionLatitude = -.pi
        cell.emissionLongitude = -.pi / 2
        cell.yAcceleration = 250
        emitterLayer.emitterCells = [cell]
    }
    
    public func beginAnimationFunction() {
        showLabel.isHidden = false
        backgroundView.isHidden = false
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
        aniMove.fromValue = showLabel.layer.position
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
        
        showLabel.layer.removeAllAnimations()
        showLabel.layer.add(aniGroup, forKey: "aniMove_aniScale_groupAnimation")
    }
}

extension PTCoinAnimation:CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, 
                                 finished flag: Bool) {
        if anim == showLabel.layer.animation(forKey: "babyCoin_scale") {
            babyCoinFadeAway()
            if animationBlock != nil {
                animationBlock!(true)
            }
        }
        
        if anim == showLabel.layer.animation(forKey: "aniMove_aniScale_groupAnimation") {
            showLabel.isHidden = true
            backgroundView.alpha = 0.6
            backgroundView.isHidden = true
        }
    }
}
