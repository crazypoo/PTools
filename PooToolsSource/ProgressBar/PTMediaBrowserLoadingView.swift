//
//  PTMediaBrowserLoadingView.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 25/10/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

@objc public enum PTLoadingViewMode:Int {
    case LoopDiagram
    case PieDiagram
}

public let PTLoadingBackgroundColor:UIColor = .DevMaskColor
public let PTLoadingItemSpace :CGFloat = 10

@objcMembers
public class PTMediaBrowserLoadingView: UIView {
    
    public var progress:CGFloat = 0 {
        didSet {
            self.setNeedsDisplay()
            if progress >= 1 {
                PTGCDManager.gcdMain {
                    self.hudHide()
                }
            }
        }
    }
    
    fileprivate var progressMode:PTLoadingViewMode = .LoopDiagram
    
    lazy var backgroundView:UIView = {
        let view = UIView()
        view.backgroundColor = .DevMaskColor
        return view
    }()
    
    public init(type:PTLoadingViewMode) {
        super.init(frame: .zero)
        progressMode = type
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        let xCenter = rect.size.width * 0.5
        let yCenter = rect.size.height * 0.5
        UIColor.white.set()
        
        switch progressMode {
        case .PieDiagram:
            let radius = min(xCenter, yCenter) - PTLoadingItemSpace
            let w = radius * 2 - PTLoadingItemSpace
            let h = w
            let x = (rect.size.width - 2) * 0.5
            let y = (rect.size.height - 2) * 0.5
            ctx!.addEllipse(in: CGRect.init(x: x, y: y, width: w, height: h))
            ctx!.fillPath()
            
            PTLoadingBackgroundColor.set()
            ctx!.move(to: CGPoint(x: xCenter, y: yCenter))
            ctx?.addLine(to: CGPoint(x: xCenter, y: 0))
            let piFloat :CGFloat = -.pi
            let to = (piFloat * 0.5 + progress * .pi * 2 + 0.01)
            ctx!.addArc(center: CGPoint(x: xCenter, y: yCenter), radius: yCenter / 2, startAngle: (piFloat * 0.5), endAngle: to, clockwise: true)
            ctx!.closePath()
            ctx!.fillPath()
        case .LoopDiagram:
            ctx!.setLineWidth(4)
            ctx!.setLineCap(.round)
            let piFloat :CGFloat = -.pi
            let to = (piFloat * 0.5 + progress * .pi * 2 + 0.05)
            let radius = min(rect.size.width, rect.self.size.height) * 0.5 - PTLoadingItemSpace
            ctx!.addArc(center: CGPoint(x: xCenter, y: yCenter), radius: radius, startAngle: (piFloat * 0.5), endAngle: to, clockwise: false)
            ctx!.strokePath()
        }
        
        viewCorner(radius: rect.size.height * 0.1)
    }
    
    public func hudShow(hudSize:CGSize = .init(width: 64, height: 64)) {
        AppWindows?.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        backgroundView.addSubviews([self])
        self.snp.makeConstraints { make in
            make.size.equalTo(hudSize)
            make.centerX.centerY.equalToSuperview()
        }
        
        self.transform = CGAffineTransformScale(.identity, 0.001, 0.001)
        UIView.animate(withDuration: 0.3 / 1.5) {
            self.transform = CGAffineTransformScale(.identity, 1.1, 1.1)
        } completion: { finish in
            UIView.animate(withDuration: 0.3 / 2) {
                self.transform = CGAffineTransformScale(.identity, 0.9, 0.9)
            } completion: { finish in
                UIView.animate(withDuration: 0.3 / 2) {
                    self.transform = .identity
                }
            }
        }
    }
    
    public func hudHide() {
        self.backgroundView.removeFromSuperview()
        self.removeFromSuperview()
    }
}
