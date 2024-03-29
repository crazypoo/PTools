//
//  PTImaginaryLineView.swift
//  PooTools_Example
//
//  Created by jax on 2022/8/31.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@objc public enum PTImaginaryLineType:Int{
    case Ver
    case Hor
}

@objcMembers
public class PTImaginaryLineView: UIView {
    
    //MARK: 虛線顏色
    ///虛線顏色
    open var lineColor:UIColor? = .lightGray
    //MARK: 虛線方向
    ///虛線方向
    open var lineType:PTImaginaryLineType? = .Hor
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.setLineDash(phase: 4, lengths: [4])
        context?.fill(bounds)
        context?.setStrokeColor(lineColor!.cgColor)
        switch lineType {
        case .Hor:
            context?.move(to: CGPoint.init(x: 0, y: frame.size.height / 2))
            context?.addLine(to: CGPoint.init(x: frame.size.width, y: 0))
        default:
            context?.move(to: CGPoint.init(x: frame.size.width / 2, y: 0))
            context?.addLine(to: CGPoint.init(x: frame.size.width / 2, y: frame.size.height))
        }
        context?.strokePath()
    }
}
