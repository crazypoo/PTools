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
        
    //MARK: 設置文字的位置
    ///設置文字的位置
    public func setVerticalAlignment(value:PTVerticalAlignment) {
        verticalAlignment = value
    }
    
    private var verticalAlignment : PTVerticalAlignment? = .Middle {
        didSet {
            self.setNeedsDisplay()
        }
    }

    //MARK: 設置橫線的位置
    ///設置橫線的位置
    public func setStrikeThroughAlignment(value:PTStrikeThroughAlignment) {
        strikeThroughAlignment = value
    }

    private var strikeThroughAlignment : PTStrikeThroughAlignment? = .Middle {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    //MARK: 設置是否帶橫線
    ///設置是否帶橫線,加載此方法須要在GCD上延時一點時間
    public func setStrikeThroughEnabled(value:Bool) {
        strikeThroughEnabled = value
    }
    
    private var strikeThroughEnabled : Bool? = false {
        didSet {
            self.setNeedsDisplay()
        }
    }

    //MARK: 設置橫線顏色
    ///設置橫線顏色
    public var strikeThroughColor : UIColor = UIColor.systemRed
    
    override init(frame: CGRect) {
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
        
        if strikeThroughEnabled! {
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
            context.setFillColor(strikeThroughColor.cgColor)
            context.fill(lineRect!)
        }
        return textRect
    }
    
    public override func drawText(in rect: CGRect) {
        let actualRect = textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
        super.drawText(in: actualRect)
    }
}
