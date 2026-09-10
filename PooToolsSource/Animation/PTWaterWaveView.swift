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
    
    open var waveWidth:CGFloat = 0
    open var waveheight:CGFloat = 10
    //MARK: 波浪的顏色
    ///波浪的顏色
    open var waveColor:UIColor = .white
    //MARK: 速度
    ///速度
    open var waveSpeed:CGFloat = 2.5
    //MARK: 波浪的X軸移位
    ///波浪的X軸移位
    open var waveOffsetX:CGFloat = 0
    open var wavePointY:CGFloat = 208
    //MARK: 振幅
    ///振幅
    open var waveAmplitude:CGFloat = 10
    //MARK: 週期
    ///週期
    open var waveCycle:CGFloat = 0

    public init(startColor:UIColor,
                endColor:UIColor) {
        super.init(frame: CGRectZero)
        self.startColor = startColor
        self.endColor = endColor
        backgroundColor = UIColor.hex("0xedf0f4",alpha: 0.1)
        layer.masksToBounds = true
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reduceMotionStatusDidChange),
                                               name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                               object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        configParam()
        starWave()
    }

    // English: Keeps the decorative wave static when Reduce Motion is enabled.
    // Español: Mantiene la ola decorativa estática cuando Reducir movimiento está activado.
    // 中文：开启“减弱动态效果”时让装饰波浪保持静态。
    @objc private func reduceMotionStatusDidChange() {
        updateWaveMotion()
    }

    private func updateWaveMotion() {
        ensureWaveLayers()
        displayLink.invalidate()
        if UIAccessibility.isReduceMotionEnabled {
            changeFirstWaveLayerPath()
            changeSecondWaveLayerPath()
            return
        }
        guard window != nil else { return }
        displayLink.add(to: .main, forMode: .common)
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        updateWaveMotion()
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
        ensureWaveLayers()
        updateWaveMotion()
    }

    // English: Installs each wave layer once before changing paths or display-link state.
    // Español: Instala cada capa de onda una sola vez antes de cambiar rutas o el estado del display link.
    // 中文：在修改路径或 DisplayLink 状态前，确保每个波浪图层只安装一次。
    private func ensureWaveLayers() {
        if shapeLayer1.superlayer !== layer {
            layer.addSublayer(shapeLayer1)
        }
        if shapeLayer2.superlayer !== layer {
            layer.addSublayer(shapeLayer2)
        }
    }

    deinit {
        displayLink.invalidate()
        NotificationCenter.default.removeObserver(self,
                                                   name: UIAccessibility.reduceMotionStatusDidChangeNotification,
                                                   object: nil)
    }
}
