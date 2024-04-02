//
//  PTChatBubbleCircle.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/2.
//

import UIKit

public class PTChatBubbleCircle: UIView {
    open override func layoutSubviews() {
        super.layoutSubviews()
        layer.mask = roundedMask(corners: .allCorners, radius: bounds.height / 2)
    }
    
    open func roundedMask(corners: UIRectCorner, radius: CGFloat) -> CAShapeLayer {
        let path = UIBezierPath(
          roundedRect: bounds,
          byRoundingCorners: corners,
          cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        return mask
    }
}
