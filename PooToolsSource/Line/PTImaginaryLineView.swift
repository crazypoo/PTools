//
//  PTImaginaryLineView.swift
//  PooTools_Example
//
//  Created by jax on 2022/8/31.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit

@objcMembers
public class PTImaginaryLineView: UIView {
    
    public var lineColor:UIColor? = .lightGray
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.clear.cgColor)
        context?.setLineDash(phase: 4, lengths: [4])
        context?.fill(self.bounds)
        context?.setStrokeColor(self.lineColor!.cgColor)
        context?.move(to: CGPoint.init(x: 0, y: 0))
        context?.addLine(to: CGPoint.init(x: self.frame.size.width, y: 0))
        context?.strokePath()
    }
}
