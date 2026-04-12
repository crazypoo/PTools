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

let maxLength: CGFloat = 200
let minLength: CGFloat = 2
let framePerSecond: CGFloat = 60
let maxWaitingFrame: CGFloat = 30
let lengthIteration: CGFloat = 8
let rotateIteration: CGFloat = 4
let loadingHudSpace: CGFloat = 5

@objc public enum PTHudStatus: Int {
    case Decrease
    case Increase
    case Waiting
}

@objcMembers
public class PTHudConfig: NSObject {
    public static let share = PTHudConfig()
    
    open var lineWidth: CGFloat = 2
    open var length: CGFloat = maxLength
    // 建议：确保 hexString 扩展在解析失败时有默认颜色，避免强制解包 (!) 导致崩溃
    open var hudColors: [UIColor] = [
        UIColor(hexString: "#F05783") ?? .red,
        UIColor(hexString: "#FCB644") ?? .orange,
        UIColor(hexString: "#88BD33") ?? .green,
        UIColor(hexString: "#E5512D") ?? .brown,
        UIColor(hexString: "#3ABCAB") ?? .cyan
    ]
    open var masked: Bool = true
    open var backgroundColor: UIColor = .clear
    
    fileprivate var conterViewSize: CGFloat = 100
    public func conterViewSizeSet(@PTClampedPropertyWrapper(range: 100...CGFloat.kSCREEN_WIDTH) size: CGFloat) {
        conterViewSize = size
    }
}

@objcMembers
public class PTHudView: UIView {
    
    fileprivate let hudShare = PTHudConfig.share
    
    lazy var centerView: UIView = {
        let view = UIView()
        view.backgroundColor = .DevMaskColor // 你的自定义扩展颜色
        return view
    }()
    
    lazy var hudView: PTLoadingHud = {
        let views = PTLoadingHud(frame: .zero)
        return views
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(centerView)
        centerView.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.width.height.equalTo(hudShare.conterViewSize)
        }
        centerView.viewCorner(radius: hudShare.conterViewSize * 0.1)
        
        centerView.addSubview(hudView)
        hudView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(loadingHudSpace)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func hudShow() {
        if PTHudConfig.share.hudColors.count < 2 {
            // 保留你的自定义日志
            PTNSLogConsole("不可以小于两个颜色", levelType: .error, loggerType: .alert)
            return
        }
        backgroundColor = PTHudConfig.share.backgroundColor
        AppWindows?.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        centerView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        UIView.animate(withDuration: 0.3 / 1.5, animations: {
            self.centerView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.3 / 2, animations: {
                self.centerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                UIView.animate(withDuration: 0.3 / 2) {
                    self.centerView.transform = .identity
                }
            }
        }
    }
    
    public func hide(duration: TimeInterval = 0.35, completion: PTActionTask?) {
        UIView.animate(withDuration: duration, animations: {
            self.centerView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if PTHudConfig.share.masked {
            return super.hitTest(point, with: event)
        } else {
            for view in subviews {
                if let responder = view.hitTest(view.convert(point, from: self), with: event) {
                    return responder
                }
            }
            return nil
        }
    }
}

@objcMembers
public class PTLoadingHud: UIView {
    open var hudConfig = PTHudConfig.share
    open var length: CGFloat = maxLength
    open var gradualColor: UIColor = .randomColor
    open var finalColor: UIColor = .randomColor
    open var prevColor: UIColor = .randomColor
    open var rotateAngle: NSInteger = NSInteger(arc4random() % 360)
    open var colorIndex: NSInteger = 0
    open var waitingFrameCount: NSInteger = 0
    open var status: PTHudStatus = .Decrease
    
    // 引入 CADisplayLink 来驱动动画
    private var displayLink: CADisplayLink?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func degressToRadian(angle: CGFloat) -> CGFloat {
        return CGFloat.pi * angle / 180.0
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setLineCap(.round)
        context.setLineWidth(hudConfig.lineWidth)
        
        // 动态计算圆心和半径，适应 AutoLayout 的变化
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 3
        
        // 直接使用 .cgColor 进行设置，性能更好且代码更简洁
        if status == .Waiting && length == minLength {
            context.setStrokeColor(gradualColor.cgColor)
        } else {
            context.setStrokeColor(finalColor.cgColor)
        }
        
        let deltaLength = sin(Double(length) / 360.0 * (Double.pi / 2.0)) * 360.0
        let startAngle = degressToRadian(angle: CGFloat(-deltaLength))
        
        context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: 0, clockwise: false)
        context.strokePath()
        
        // 注意：这里删除了之前使用的 self.perform() 方法
    }
    
    @objc func refreshCricle() {
        // CADisplayLink 默认在主线程回调，因此直接更新逻辑即可
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
                let colorAPercent: CGFloat = CGFloat(self.waitingFrameCount) / maxWaitingFrame
                let colorBPercent = 1 - colorAPercent
                
                // 保留你原本获取渐变色的逻辑，如果 mixed(withColor:) 是你的扩展
                let transparentColorA = finalColor.withAlphaComponent(colorAPercent)
                let transparentColorB = prevColor.withAlphaComponent(colorBPercent)
                self.gradualColor = transparentColorA.mixed(withColor: transparentColorB)
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
        
        // 移除多余的 GCD 和 Task 切换，直接在当前(主)线程更新 UI
        self.transform = CGAffineTransform(rotationAngle: self.degressToRadian(angle: CGFloat(self.rotateAngle)))
        self.setNeedsDisplay()
    }
    
    // MARK: - 生命周期与定时器管理
    private func setupDisplayLink() {
        if displayLink == nil {
            displayLink = CADisplayLink(target: self, selector: #selector(refreshCricle))
            // preferredFramesPerSecond 可以控制帧率，这里保持你原有的逻辑，默认为最高刷新率
            displayLink?.add(to: .main, forMode: .common)
        }
    }
    
    private func invalidateDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

extension PTLoadingHud {
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview != nil {
            colorIndex = Int(arc4random()) % hudConfig.hudColors.count
            finalColor = hudConfig.hudColors[colorIndex]
            setupDisplayLink() // 添加到视图时开启定时器
        } else {
            invalidateDisplayLink() // 移除视图时销毁定时器，防止内存泄漏
        }
    }
}
