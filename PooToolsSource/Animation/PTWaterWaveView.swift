//
//  PTWaterWaveView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/2/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SwifterSwift

@objcMembers
public class PTWaterWaveView: UIView {

    lazy var displayLink : CADisplayLink = {
        let dLink = CADisplayLink(target: self, selector: #selector(self.getCurrentWave))
        return dLink
    }()
    
    lazy var shapeLayer1 : CAShapeLayer = {
        let sLayer = CAShapeLayer()
        return sLayer
    }()
    
    lazy var shapeLayer2 : CAShapeLayer = {
        let sLayer = CAShapeLayer()
        return sLayer
    }()
    
    lazy var gradientLayer1 : CAGradientLayer = {
        let gLayer = CAGradientLayer()
        gLayer.frame = self.bounds
        gLayer.locations = [0,1]
        gLayer.startPoint = CGPoint(x: 0, y: 0)
        gLayer.endPoint = CGPoint(x: 1, y: 0)
        gLayer.colors = [self.startColor.cgColor,self.endColor.cgColor]
        return gLayer
    }()
    
    lazy var gradientLayer2 : CAGradientLayer = {
        let gLayer = CAGradientLayer()
        gLayer.frame = self.bounds
        gLayer.locations = [0,1]
        gLayer.startPoint = CGPoint(x: 0, y: 0)
        gLayer.endPoint = CGPoint(x: 1, y: 0)
        gLayer.colors = [self.startColor.cgColor,self.endColor.cgColor]
        return gLayer
    }()
    
    private var startColor:UIColor = .randomColor
    private var endColor:UIColor = .randomColor
    
    public var waveWidth:CGFloat = 0
    public var waveheight:CGFloat = 10
    //MARK: 波浪的顏色
    ///波浪的顏色
    public var waveColor:UIColor = .white
    //MARK: 速度
    ///速度
    public var waveSpeed:CGFloat = 2.5
    //MARK: 波浪的X軸移位
    ///波浪的X軸移位
    public var waveOffsetX:CGFloat = 0
    public var wavePointY:CGFloat = 208
    //MARK: 振幅
    ///振幅
    public var waveAmplitude:CGFloat = 10
    //MARK: 週期
    ///週期
    public var waveCycle:CGFloat = 0

    public init(startColor:UIColor,
                endColor:UIColor) {
        super.init(frame: CGRectZero)
        self.startColor = startColor
        self.endColor = endColor
        backgroundColor = UIColor.hex("0xedf0f4",alpha: 0.1)
        layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        configParam()
        starWave()
    }
    
    func configParam() {
        if waveWidth <= 0 {
            waveWidth = frame.size.width
        }
        
        if waveCycle <= 0 {
            waveCycle = 1.29 * .pi / waveWidth
        }
    }
    
    func changeFirstWaveLayerPath() {
        let path = CGMutablePath()
        var y = wavePointY
        path.move(to: CGPoint(x: 0, y: y))
        
        for x in stride(from: 0, to: waveWidth, by: 0.1) {
            y = waveAmplitude * 1.6 * sin((250 / waveWidth) * (x * .pi / 180) - waveOffsetX * .pi / 270) + wavePointY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: waveWidth, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        shapeLayer1.path = path
    }
    
    func changeSecondWaveLayerPath() {
        let path = CGMutablePath()
        var y = wavePointY
        path.move(to: CGPoint(x: 0, y: y))
        
        for x in stride(from: 0, to: waveWidth, by: 0.1) {
            y = waveAmplitude * 1.6 * sin((250 / waveWidth) * (x * .pi / 180) - waveOffsetX * .pi / 180) + wavePointY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: waveWidth, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        shapeLayer2.path = path
    }
    
    func getCurrentWave() {
        waveOffsetX += waveSpeed
        changeFirstWaveLayerPath()
        changeSecondWaveLayerPath()
        layer.addSublayer(gradientLayer1)
        gradientLayer1.mask = shapeLayer1
        layer.addSublayer(gradientLayer2)
        gradientLayer2.mask = shapeLayer2
    }
    
    func starWave() {
        layer.addSublayer(shapeLayer1)
        layer.addSublayer(shapeLayer2)
        displayLink.add(to: .main, forMode: .common)
    }
}
