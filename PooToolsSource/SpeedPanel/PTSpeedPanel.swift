//
//  PTSpeedPanel.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 12/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public typealias PTPanelDetailTask = (_ speed:CGFloat)->Void

public class PTSpeedPanelConfig:NSObject {
    static let share = PTSpeedPanelConfig()
    
    // 最大速度
    public var maxValue:CGFloat = 100
    // 刻度线数量
    public var numberOfTicks:Int = 8
    // 刻度颜色
    public var ticksColor:UIColor = .white
    // 刻度颜色
    public var ticksLableFont:UIFont = .appfont(size: 16)
    // 刻度颜色
    public var ticksLableColor:UIColor = .white
    // 进度颜色
    public var progressColor:UIColor = .randomColor
    // 进度底部颜色
    public var progressBackgroundColor:UIColor = .lightGray
}

public class PTSpeedPanel: UIView {
    public var callBack:PTPanelDetailTask? = nil

    let viewConfig = PTSpeedPanelConfig.share
    
    // 当前速度
    fileprivate var currentSpeed: CGFloat = 0

    // 仪表盘半径
    fileprivate var panelRadius:CGFloat {
        get {
            return self.bounds.size.width / 2
        }
    }
    
    // 仪表盘图层
    let panelLayer = CAShapeLayer()
    let panelLayerBackground = CAShapeLayer()
    
    // 刻度线图层
    let tickLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.createGaugeLayer()
        self.createGaugeLayerBackground()
        self.createTickLayer()
        self.layer.addSublayer(self.panelLayerBackground)
        self.layer.addSublayer(self.panelLayer)
        self.layer.addSublayer(self.tickLayer)
        
        PTGCDManager.gcdAfter(time: 0.5) {
            self.animationStart()
        }
    }
    
    // 创建仪表盘图层
    fileprivate func createGaugeLayer() {
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let path = UIBezierPath(arcCenter: center, radius: self.panelRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        self.panelLayer.path = path.cgPath
        self.panelLayer.strokeColor = self.viewConfig.progressColor.cgColor
        self.panelLayer.fillColor = UIColor.clear.cgColor
        self.panelLayer.lineWidth = 20
        self.panelLayer.lineCap = .round
    }
    
    fileprivate func createGaugeLayerBackground() {
        let center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let path = UIBezierPath(arcCenter: center, radius: self.panelRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        self.panelLayerBackground.path = path.cgPath
        self.panelLayerBackground.strokeColor = self.viewConfig.progressBackgroundColor.cgColor
        self.panelLayerBackground.fillColor = UIColor.clear.cgColor
        self.panelLayerBackground.lineWidth = 20
        self.panelLayerBackground.lineCap = .round
    }
    
    // 创建刻度线图层
    fileprivate func createTickLayer() {
        let center = CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0)
        let tickRadius = self.panelRadius
        
        let tickPath = UIBezierPath()
        
        for i in 0..<self.viewConfig.numberOfTicks {
            let tickAngle = -CGFloat.pi / 2 + CGFloat(i) * (2 * CGFloat.pi / CGFloat(self.viewConfig.numberOfTicks))
            let startPoint = CGPoint(x: center.x + tickRadius * sin(tickAngle), y: center.y + tickRadius * cos(tickAngle))
            let endPoint = CGPoint(x: center.x + (tickRadius - 20) * sin(tickAngle), y: center.y + (tickRadius - 20) * cos(tickAngle))
            tickPath.move(to: startPoint)
            tickPath.addLine(to: endPoint)
            
            let labelSize: CGFloat = 30
            let labelCenter = CGPoint(x: center.x + (tickRadius - 40) * cos(tickAngle), y: center.y + (tickRadius - 40) * sin(tickAngle))
            let label = UILabel(frame: CGRect(x: labelCenter.x - labelSize / 2, y: labelCenter.y - labelSize / 2, width: labelSize, height: labelSize))
            label.textAlignment = .center
            label.font = self.viewConfig.ticksLableFont
            label.textColor = self.viewConfig.ticksLableColor
            label.text = "\(Int(self.viewConfig.maxValue / CGFloat(self.viewConfig.numberOfTicks) * CGFloat(i)))"
            self.addSubview(label)
        }
        
        self.tickLayer.path = tickPath.cgPath
        self.tickLayer.strokeColor = self.viewConfig.ticksColor.cgColor
        self.tickLayer.lineWidth = 2
    }
        
    // 更新仪表盘
    fileprivate func updatePanel() {
        PTGCDManager.gcdMain {
            let center = CGPoint(x: self.frame.size.width/2.0, y: self.frame.size.height/2.0)
            let startAngle = -CGFloat.pi / 2
            let endAngle = startAngle + 2 * CGFloat.pi * (self.currentSpeed / self.viewConfig.maxValue)
            
            let path = UIBezierPath(arcCenter: center, radius: self.panelRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            
            self.panelLayer.path = path.cgPath
        }
    }

    fileprivate func animationStart() {
        let timer = Timer.scheduledTimer(timeInterval: 0.005, repeats: true) { timer in
            self.currentSpeed += 1
            self.updateSpeed(speed: CGFloat(self.viewConfig.numberOfTicks))
            if self.currentSpeed >= self.viewConfig.maxValue {
                timer.invalidate()
                self.animationEnd()
            }
        }
        timer.fire()
    }
    
    fileprivate func animationEnd() {
        let time = Timer.scheduledTimer(timeInterval: 0.005, repeats: true) { timer in
            self.currentSpeed -= 1
            self.updateSpeed(speed: self.currentSpeed)
            if self.currentSpeed <= 0 {
                timer.invalidate()
            }
        }
        time.fire()
    }
    
    // 更新速度
    public func updateSpeed(speed: CGFloat) {
        self.currentSpeed = speed
        self.updatePanel()
        if self.callBack != nil {
            self.callBack!(self.currentSpeed)
        }
    }
}
