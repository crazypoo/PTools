//
//  PTLabel.swift
//  Diou
//
//  Created by ken lam on 2021/10/7.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit

@objc public enum PTVerticalAlignment:Int {
    case Top
    case Middle
    case Bottom
}

@objc public enum PTStrikeThroughAlignment:Int {
    case Top
    case Middle
    case Bottom
}

@objcMembers
public class PTLabel: UILabel {
        
    public var verticalAlignment : PTVerticalAlignment? = .Middle
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    public var strikeThroughAlignment : PTStrikeThroughAlignment? = .Middle
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }
    
    public var strikeThroughEnabled : Bool? = false
    {
        didSet
        {
            self.setNeedsDisplay()
        }
    }

    public var strikeThroughColor : UIColor = UIColor.systemRed
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var textRect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        switch verticalAlignment {
        case .Top:
            textRect.origin.y = bounds.origin.y
        case .Bottom:
            textRect.origin.y = bounds.origin.y + bounds.size.height - textRect.size.height
        case .Middle:
            break
        default:
            textRect.origin.y = bounds.origin.y + (bounds.size.height - textRect.size.height) / 2.0
        }
        
        if strikeThroughEnabled!
        {
            let strikeWidth = textRect.size.width
            var lineRect : CGRect? = .zero
            switch strikeThroughAlignment {
            case .Top:
                lineRect = CGRect.init(x: textRect.origin.x, y: textRect.origin.y, width: strikeWidth, height: 1)
            case .Bottom:
                lineRect = CGRect.init(x: textRect.origin.x, y: textRect.origin.y + textRect.size.height, width: strikeWidth, height: 1)
            default:
                lineRect = CGRect.init(x: textRect.origin.x, y: textRect.origin.y + textRect.size.height/2, width: strikeWidth, height: 1)
            }
            
            let context : CGContext = UIGraphicsGetCurrentContext()!
            context.setFillColor(self.strikeThroughColor.cgColor)
            context.fill(lineRect!)
        }
        return textRect
    }
    
    public override func drawText(in rect: CGRect)
    {
        let actualRect = self.textRect(forBounds: rect, limitedToNumberOfLines: self.numberOfLines)
        super.drawText(in: actualRect)
    }
}
