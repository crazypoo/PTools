//
//  LineButton.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

// Called when the button's highlighted is false.
protocol LineButtonDelegate: AnyObject {
    func lineButtonUnHighlighted()
}

// Side, Edge LineButton
class LineButton: UIButton {
    weak var delegate: LineButtonDelegate?
    
    private var type: ButtonLineType
    
    override var isHighlighted: Bool {
        didSet {
            if !self.isHighlighted {
                self.delegate?.lineButtonUnHighlighted()
            }
        }
    }
    
    // MARK: Init
    init(_ type: ButtonLineType) {
        self.type = type
        super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        
        self.setTitle(nil, for: .normal)
        self.translatesAutoresizingMaskIntoConstraints = false
        if type != .center {
            self.widthConstraint(constant: 50)
            self.heightConstraint(constant: 50)
            self.alpha = 0
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func edgeLine(_ color: UIColor?) {
        self.setImage(self.type.view(color)?.imageWithView?.withRenderingMode(.alwaysOriginal), for: .normal)
    }
}

enum ButtonLineType {
    case center
    case leftTop, rightTop, leftBottom, rightBottom, top, left, right, bottom
    
    var rotate: CGFloat {
        switch self {
        case .leftTop:
            return 0
        case .rightTop:
            return CGFloat.pi/2
        case .rightBottom:
            return CGFloat.pi
        case .leftBottom:
            return CGFloat.pi/2*3
        case .top:
            return 0
        case .left:
            return CGFloat.pi/2*3
        case .right:
            return CGFloat.pi/2
        case .bottom:
            return CGFloat.pi
        case .center:
            return 0
        }
    }
    
    var yMargin: CGFloat {
        switch self {
        case .rightBottom, .bottom:
            return 1
        default:
            return 0
        }
    }
    
    var xMargin: CGFloat {
        switch self {
        case .leftBottom:
            return 1
        default:
            return 0
        }
    }
    
    func view(_ color: UIColor?) -> UIView? {
        var view: UIView?
        if self == .leftTop || self == .rightTop || self == .leftBottom || self == .rightBottom {
            view = ButtonLineType.EdgeView(self, color: color)
        } else {
            view = ButtonLineType.SideView(self, color: color)
        }
        view?.isOpaque = false
        view?.tintColor = color
        return view
    }
    
    class LineView: UIView {
        var type: ButtonLineType
        var color: UIColor?
        init(_ type: ButtonLineType, color: UIColor?) {
            self.type = type
            self.color = color
            super.init(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        func apply(_ path: UIBezierPath) {
            var pathTransform  = CGAffineTransform.identity
            pathTransform = pathTransform.translatedBy(x: 25, y: 25)
            pathTransform = pathTransform.rotated(by: self.type.rotate)
            pathTransform = pathTransform.translatedBy(x: -25 - self.type.xMargin, y: -25 - self.type.yMargin)
            path.apply(pathTransform)
            path.closed()
                .strokeFill(self.color ?? .white)
        }
    }
    
    class EdgeView: LineView {
        override func draw(_ rect: CGRect) {
            let path = UIBezierPath()
                .move(6, 6)
                .line(6, 20)
                .line(8, 20)
                .line(8, 8)
                .line(20, 8)
                .line(20, 6)
                .line(6, 6)
            self.apply(path)
        }
    }
    class SideView: LineView {
        override func draw(_ rect: CGRect) {
            let path = UIBezierPath()
                .move(15, 6)
                .line(35, 6)
                .line(35, 8)
                .line(15, 8)
                .line(15, 6)
            self.apply(path)
        }
    }
}
