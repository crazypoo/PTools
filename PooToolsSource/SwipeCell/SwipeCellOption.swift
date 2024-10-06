//
//  SwipeCellOption.swift
//  咪呐
//
//  Created by 九州所想 on 2022/3/24.
//  Copyright © 2022 MN. All rights reserved.
//

import UIKit

public class IndicatorView: UIView {
    open var color = UIColor.clear {
        didSet { setNeedsDisplay() }
    }
    
    public override func draw(_ rect: CGRect) {
        color.set()
        UIBezierPath(ovalIn: rect).fill()
    }
}

public enum ActionDescriptor {
    case read, unread, more, flag, trash, edit, custom
    
    public func image(forStyle style: ButtonStyle, displayMode: ButtonDisplayMode,cellHeight:CGFloat = 50) -> UIImage? {
        guard displayMode != .titleOnly else { return nil }
                
        var imageName: String = ""
        switch self {
        case .read: imageName = "envelope.open.fill"
        case .unread: imageName = "envelope.badge.fill"
        case .more: imageName = "ellipsis.circle.fill"
        case .flag: imageName = "flag.fill"
        case .trash: imageName = "trash.fill"
        case .edit: imageName =  "pencil"
        default:break
        }

        switch self {
        case .custom:
            return nil
        default:
            if style == .backgroundColor {
                let config = UIImage.SymbolConfiguration(pointSize: 23.0, weight: .regular)
                return UIImage(systemName: imageName, withConfiguration: config)
            } else {
                var circularIconSize:CGSize = .zero
                switch displayMode {
                case .imageOnly:
                    circularIconSize = CGSize(width: cellHeight - 10, height: cellHeight - 10)
                default:
                    circularIconSize = CGSize(width: cellHeight - 30, height: cellHeight - 30)
                }

                let config = UIImage.SymbolConfiguration(pointSize: circularIconSize.height / 2, weight: .regular)
                let image = UIImage(systemName: imageName, withConfiguration: config)?.withTintColor(.white, renderingMode: .alwaysTemplate)
                
                return circularIcon(with: color(forStyle: style), size: circularIconSize, icon: image)
            }
        }
    }
    
    public func color(forStyle style: ButtonStyle,customColor:UIColor? = .clear) -> UIColor {
        switch self {
        case .read, .unread: return UIColor.systemBlue
        case .more:
            if UITraitCollection.current.userInterfaceStyle == .dark {
                return UIColor.systemGray
            }
            return style == .backgroundColor ? UIColor.systemGray3 : UIColor.systemGray2
        case .flag: return UIColor.systemOrange
        case .trash: return UIColor.systemRed
        case .edit: return UIColor.systemBlue
        case .custom:
            if customColor != nil {
                return customColor!
            } else {
                return .clear
            }
        }
    }
    
    public func circularIcon(with color: UIColor, size: CGSize, icon: UIImage? = nil) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)

        UIBezierPath(ovalIn: rect).addClip()

        color.setFill()
        UIRectFill(rect)

        if let icon = icon {
            let iconRect = CGRect(x: (rect.size.width - icon.size.width) / 2,
                                  y: (rect.size.height - icon.size.height) / 2,
                                  width: icon.size.width,
                                  height: icon.size.height)
            icon.draw(in: iconRect, blendMode: .normal, alpha: 1.0)
        }

        defer { UIGraphicsEndImageContext() }

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

public enum ButtonDisplayMode {
    case titleAndImage, titleOnly, imageOnly
}

public enum ButtonStyle {
    case backgroundColor, circular
}
