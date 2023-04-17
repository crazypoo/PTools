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

    public init(startColor:UIColor,endColor:UIColor) {
        super.init(frame: CGRectZero)
        self.startColor = startColor
        self.endColor = endColor
        self.backgroundColor = UIColor.hex("0xedf0f4",alpha: 0.1)
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.configParam()
        self.starWave()
    }
    
    func configParam() {
        if self.waveWidth <= 0 {
            self.waveWidth = self.frame.size.width
        }
        
        if self.waveCycle <= 0 {
            self.waveCycle = 1.29 * .pi / self.waveWidth
        }
    }
    
    func changeFirstWaveLayerPath() {
        let path = CGMutablePath()
        var y = self.wavePointY
        path.move(to: CGPoint(x: 0, y: y))
        
        for x in stride(from: 0, to: self.waveWidth, by: 0.1) {
            y = self.waveAmplitude * 1.6 * sin((250 / self.waveWidth) * (x * .pi / 180) - self.waveOffsetX * .pi / 270) + self.wavePointY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: self.waveWidth, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        self.shapeLayer1.path = path
    }
    
    func changeSecondWaveLayerPath() {
        let path = CGMutablePath()
        var y = self.wavePointY
        path.move(to: CGPoint(x: 0, y: y))
        
        for x in stride(from: 0, to: self.waveWidth, by: 0.1) {
            y = self.waveAmplitude * 1.6 * sin((250 / self.waveWidth) * (x * .pi / 180) - self.waveOffsetX * .pi / 180) + self.wavePointY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: self.waveWidth, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.closeSubpath()
        self.shapeLayer2.path = path
    }
    
    func getCurrentWave() {
        self.waveOffsetX += self.waveSpeed
        self.changeFirstWaveLayerPath()
        self.changeSecondWaveLayerPath()
        self.layer.addSublayer(self.gradientLayer1)
        self.gradientLayer1.mask = self.shapeLayer1
        self.layer.addSublayer(self.gradientLayer2)
        self.gradientLayer2.mask = self.shapeLayer2
    }
    
    func starWave() {
        self.layer.addSublayer(self.shapeLayer1)
        self.layer.addSublayer(self.shapeLayer2)
        self.displayLink.add(to: .main, forMode: .common)
    }
}
