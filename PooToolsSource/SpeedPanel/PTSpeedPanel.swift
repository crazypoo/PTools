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
    // 最大速度
    open var maxValue:CGFloat = 100
    // 刻度线数量
    open var numberOfTicks = 8
    // 刻度颜色
    open var ticksColor:UIColor = .white
    // 刻度颜色
    open var ticksLableFont:UIFont = .appfont(size: 16)
    // 刻度颜色
    open var ticksLableColor:UIColor = .white
    // 进度颜色
    open var progressColor:UIColor = .randomColor
    // 进度底部颜色
    open var progressBackgroundColor:UIColor = .lightGray
}

@objcMembers
public class PTSpeedPanel: UIView {
    open var callBack:PTPanelDetailTask? = nil

    fileprivate var viewConfig : PTSpeedPanelConfig!
    
    // 当前速度
    fileprivate var currentSpeed: CGFloat = 0

    // 仪表盘半径
    fileprivate var panelRadius:CGFloat {
        get {
            bounds.size.width / 2
        }
    }
    
    // 仪表盘图层
    let panelLayer = CAShapeLayer()
    let panelLayerBackground = CAShapeLayer()
    
    // 刻度线图层
    let tickLayer = CAShapeLayer()

    public init(viewConfig:PTSpeedPanelConfig) {
        super.init(frame: .zero)
        self.viewConfig = viewConfig
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        createGaugeLayer()
        createGaugeLayerBackground()
        createTickLayer()
        layer.addSublayer(panelLayerBackground)
        layer.addSublayer(panelLayer)
        layer.addSublayer(tickLayer)
        
        PTGCDManager.gcdAfter(time: 0.5) {
            self.animationStart()
        }
    }
    
    // 创建仪表盘图层
    fileprivate func createGaugeLayer() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let path = UIBezierPath(arcCenter: center, radius: panelRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        panelLayer.path = path.cgPath
        panelLayer.strokeColor = viewConfig.progressColor.cgColor
        panelLayer.fillColor = UIColor.clear.cgColor
        panelLayer.lineWidth = 20
        panelLayer.lineCap = .round
    }
    
    fileprivate func createGaugeLayerBackground() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let path = UIBezierPath(arcCenter: center, radius: panelRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        panelLayerBackground.path = path.cgPath
        panelLayerBackground.strokeColor = viewConfig.progressBackgroundColor.cgColor
        panelLayerBackground.fillColor = UIColor.clear.cgColor
        panelLayerBackground.lineWidth = 20
        panelLayerBackground.lineCap = .round
    }
    
    // 创建刻度线图层
    fileprivate func createTickLayer() {
        let center = CGPoint(x: frame.size.width/2.0, y: frame.size.height/2.0)
        let tickRadius = panelRadius
        
        let tickPath = UIBezierPath()
        
        for i in 0..<viewConfig.numberOfTicks {
            let tickAngle = -CGFloat.pi / 2 + CGFloat(i) * (2 * CGFloat.pi / CGFloat(viewConfig.numberOfTicks))
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
            label.text = "\(Int(viewConfig.maxValue / CGFloat(viewConfig.numberOfTicks) * CGFloat(i)))"
            self.addSubview(label)
        }
        
        tickLayer.path = tickPath.cgPath
        tickLayer.strokeColor = viewConfig.ticksColor.cgColor
        tickLayer.lineWidth = 2
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
            self.updateSpeed(speed: self.currentSpeed)
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
        currentSpeed = speed
        updatePanel()
        if callBack != nil {
            callBack!(currentSpeed)
        }
    }
}
