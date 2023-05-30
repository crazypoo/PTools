//
//  PTHudView.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/9.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import SnapKit

let maxLength:CGFloat = 200
let minLength:CGFloat = 2
let framePerSecond:CGFloat = 60
let maxWaitingFrame:CGFloat = 30
let lengthIteration:CGFloat = 8
let rotateIteration:CGFloat = 4
let conterViewSize:CGFloat = 100
let loadingHudSpace:CGFloat = 5

enum PTHudStatus:Int {
    case Decrease
    case Increase
    case Waiting
}

@objcMembers
public class PTHudConfig:NSObject {
    public var lineWidth:CGFloat = 2
    public var length:CGFloat = maxLength
    public var hudColors:[UIColor] = [UIColor(hexString: "#F05783")!,UIColor(hexString: "#FCB644")!,UIColor(hexString: "#88BD33")!,UIColor(hexString: "#E5512D")!,UIColor(hexString: "#3ABCAB")!]
    public var masked:Bool = true
    public var backgroundColor:UIColor = .clear
}

@objcMembers
public class PTHudView: UIView {
    public var hudConfig:PTHudConfig = PTHudConfig()
    
    lazy var centerView:UIView = {
        let view = UIView()
        view.backgroundColor = .DevMaskColor
        return view
    }()
    
    lazy var hudView:PTLoadingHud = {
        let views = PTLoadingHud.init(frame: CGRect(x: loadingHudSpace, y: loadingHudSpace, width: conterViewSize - loadingHudSpace * 2, height: conterViewSize - loadingHudSpace * 2))
        views.hudConfig = self.hudConfig
        return views
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(centerView)
        centerView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.width.height.equalTo(conterViewSize)
        }
        centerView.viewCorner(radius: conterViewSize * 0.1)
        centerView.addSubview(hudView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hudShow() {
        if hudConfig.hudColors.count < 2 {
            PTNSLogConsole("不可以小于两个颜色")
            return
        }
        backgroundColor = hudConfig.backgroundColor
        AppWindows?.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        centerView.transform = CGAffineTransformScale(.identity, 0.001, 0.001)
        UIView.animate(withDuration: 0.3 / 1.5) {
            self.centerView.transform = CGAffineTransformScale(.identity, 1.1, 1.1)
        } completion: { finish in
            UIView.animate(withDuration: 0.3 / 2) {
                self.centerView.transform = CGAffineTransformScale(.identity, 0.9, 0.9)
            } completion: { finish in
                UIView.animate(withDuration: 0.3 / 2) {
                    self.centerView.transform = .identity
                }
            }
        }
    }
    
    func hide(completion:(()->Void)?) {
        UIView.animate(withDuration: 1) {
            self.centerView.alpha = 0
        } completion: { finish in
            self.removeFromSuperview()
            if completion != nil {
                completion!()
            }
        }
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if hudConfig.masked {
            return super.hitTest(point, with: event)
        } else {
            for view in subviews {
                if let responder : UIView = view.hitTest(view.convert(point, from: self), with: event) {
                    return responder
                }
            }
            return nil
        }
    }
}

public class PTLoadingHud:UIView {
    var hudConfig:PTHudConfig = PTHudConfig()
    var length:CGFloat = maxLength
    var gradualColor:UIColor = .randomColor
    var finalColor:UIColor = .randomColor
    var prevColor:UIColor = .randomColor
    var rotateAngle:NSInteger = NSInteger(arc4random()%360)
    var colorIndex:NSInteger = 0
    var waitingFrameCount:NSInteger = 0
    var status:PTHudStatus = .Decrease
    var circleCenter:CGPoint = .zero
    var circleRadius:CGFloat = 0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        circleCenter = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        circleRadius = frame.size.width / 3
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func degressToRadian(angle:CGFloat)->CGFloat {
        Double.pi * angle / 180
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        let context = UIGraphicsGetCurrentContext()
        context?.setLineCap(.round)
        context?.setLineWidth(hudConfig.lineWidth)
        
        if status == .Waiting && length == minLength {
            context?.setStrokeColor(red: gradualColor.rgbaValueModel().redFloat, green: gradualColor.rgbaValueModel().greenFloat, blue: gradualColor.rgbaValueModel().blueFloat, alpha: gradualColor.rgbaValueModel().alphaFloat)
        } else {
            context?.setStrokeColor(red: finalColor.rgbaValueModel().redFloat, green: finalColor.rgbaValueModel().greenFloat, blue: finalColor.rgbaValueModel().blueFloat, alpha: finalColor.rgbaValueModel().alphaFloat)
        }
        
        let deltaLength = sin(length / 360 * (Double.pi / 2)) * 360
        let startAngle = degressToRadian(angle: -deltaLength)
        context?.addArc(center: circleCenter, radius: circleRadius, startAngle: startAngle, endAngle: 0, clockwise: false)
        
        context?.strokePath()
        self.perform(#selector(refreshCricle), with: nil, afterDelay: 1 / framePerSecond)
    }
    
    @objc func refreshCricle() {
        PTGCDManager.gcdMain {
            switch self.status {
            case .Decrease:
                self.length -= lengthIteration
                self.rotateAngle += Int(rotateIteration)
                
                if self.length <= minLength {
                    self.length = minLength
                    self.status = .Waiting
                    self.colorIndex += 1
                    self.colorIndex %= self.hudConfig.hudColors.count
                    self.prevColor = self.finalColor
                    self.finalColor = self.hudConfig.hudColors[self.colorIndex]
                }
            case .Increase:
                self.length += lengthIteration
                let deltaLength = sin(lengthIteration / 360 * (Double.pi / 2)) * 360
                self.rotateAngle += Int((rotateIteration + deltaLength))
                
                if self.length >= maxLength {
                    self.length = maxLength
                    self.status = .Waiting
                }
            case .Waiting:
                self.waitingFrameCount += 1
                self.rotateAngle += Int(rotateIteration)
                
                if self.length == minLength {
                    let colorAPercent:CGFloat = CGFloat(self.waitingFrameCount) / maxWaitingFrame
                    let colorBPercent = 1 - colorAPercent
                    let transparentColorA = UIColor(red: self.finalColor.rgbaValueModel().redFloat, green: self.finalColor.rgbaValueModel().greenFloat, blue: self.finalColor.rgbaValueModel().blueFloat, alpha: colorAPercent)
                    let transparentColorB = UIColor(red: self.prevColor.rgbaValueModel().redFloat, green: self.prevColor.rgbaValueModel().greenFloat, blue: self.prevColor.rgbaValueModel().blueFloat, alpha: colorBPercent)
                    self.gradualColor = transparentColorA.mixColor(otherColor: transparentColorB)
                }
                
                if self.waitingFrameCount == Int(maxWaitingFrame) {
                    self.waitingFrameCount = 0
                    if self.length == minLength {
                        self.status = .Increase
                    } else {
                        self.status = .Decrease
                    }
                }
            }
            self.rotateAngle %= 360
            PTGCDManager.gcdMain {
                self.transform = CGAffineTransformMakeRotation(self.degressToRadian(angle: CGFloat(self.rotateAngle)))
                self.setNeedsDisplay()
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension PTLoadingHud {
    public override func willMove(toSuperview newSuperview: UIView?) {
        if newSuperview != nil {
            colorIndex = Int(arc4random()) % hudConfig.hudColors.count
            finalColor = hudConfig.hudColors[colorIndex]
        } else {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(refreshCricle), object: nil)
        }
    }
}

