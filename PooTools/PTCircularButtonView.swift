//
//  PTCircularButtonView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 17/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

class PTCircularButtonView: UIView {
    let centerButton = UIButton()
    let buttonRadius: CGFloat = 30
    let outerButtonRadius: CGFloat = 30
    let sectorButtonCount = 4
    let sectorAngle: CGFloat = .pi / 2

    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        centerButton.frame = CGRect(x: frame.size.width / 2 - buttonRadius, y: frame.size.height / 2 - buttonRadius, width: buttonRadius * 2, height: buttonRadius * 2)
        centerButton.layer.cornerRadius = buttonRadius
        centerButton.backgroundColor = .blue
        centerButton.setTitle("Center", for: .normal)
        centerButton.addTarget(self, action: #selector(centerButtonTapped), for: .touchUpInside)
        self.addSubview(centerButton)
        
        createDirectionButtons()
    }
    
    @objc func centerButtonTapped() {
        print("Center button tapped")
    }
    
    func createDirectionButtons() {
        let directions = ["Up", "Down", "Left", "Right"]
        let angles: [CGFloat] = [3 * .pi / 2, .pi / 2, .pi, 0]
        
        for i in 0..<4 {
            let angle = angles[i]
            let x = centerButton.center.x + (buttonRadius + outerButtonRadius) * cos(angle) - outerButtonRadius
            let y = centerButton.center.y - (buttonRadius + outerButtonRadius) * sin(angle) - outerButtonRadius
            let outerButton = UIButton(frame: CGRect(x: x, y: y, width: outerButtonRadius * 2, height: outerButtonRadius * 2))
            outerButton.layer.cornerRadius = outerButtonRadius
            outerButton.backgroundColor = .green
            outerButton.setTitle(directions[i], for: .normal)
            outerButton.addTarget(self, action: #selector(outerButtonTapped), for: .touchUpInside)
            self.addSubview(outerButton)
        }
    }
    
    @objc func outerButtonTapped(sender: UIButton) {
        if let buttonTitle = sender.title(for: .normal) {
            print("Tapped on \(buttonTitle) button")
        }
    }
}

class CircularFanView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let tapGes = UITapGestureRecognizer { sender in
            let point = sender.location(in: self)
            let center = CGPoint(x: self.bounds.size.width / 2, y: self.bounds.size.height / 2)

            // 计算点击位置相对于中心的角度
            let angle = atan2(point.y - center.y, point.x - center.x)
                        
            if angle >= -.pi/4 && angle < .pi/4 {
                // 处理点击右侧扇形的事件
                PTNSLogConsole("Right sector tapped")
            } else if angle >= .pi/4 && angle < 3 * .pi/4 {
                // 处理点击上方扇形的事件
                PTNSLogConsole("Bottom sector tapped")
            } else if (angle >= 3 * .pi/4 && angle < .pi) || (angle >= -.pi && angle < -(3 * .pi/4))  {
                // 处理点击左侧扇形的事件
                PTNSLogConsole("Left sector tapped")
            } else {
                PTNSLogConsole("Top sector tapped")
            }

        }
        self.addGestureRecognizer(tapGes)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: rect.size.width / 2, y: rect.size.height / 2)
        let radius = min(rect.size.width, rect.size.height) / 2
        
        // 绘制圆
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        circlePath.close()
        UIColor.clear.setFill()
        circlePath.fill()
        
        // 绘制四个扇形，分布在上下左右象限
        let angles: [CGFloat] = [-.pi/4, .pi/4, 3 * .pi/4, -3 * .pi/4]
        
        angles.enumerated().forEach { index,startAngle in
            let endAngle = startAngle + (.pi / 2)
            let fanPath = UIBezierPath()
            fanPath.move(to: center)
            fanPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            fanPath.close()
            
            var fanColor: UIColor
            switch index {
            case 0:
                fanColor = .blue
            case 1:
                fanColor = .red
            case 2:
                fanColor = .green
            case 3:
                fanColor = .yellow
            default:
                fanColor = .clear
            }
            
            fanColor.setFill() // 设置扇形的填充颜色
            fanPath.fill()
        }
    }
}

