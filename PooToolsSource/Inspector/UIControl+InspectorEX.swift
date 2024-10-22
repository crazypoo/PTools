//
//  UIControl+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension UIControl.ContentHorizontalAlignment: @retroactive CaseIterable {
    public typealias AllCases = [UIControl.ContentHorizontalAlignment]

    public static let allCases: [UIControl.ContentHorizontalAlignment] = [
        .leading,
        .left,
        .center,
        .trailing,
        .right,
        .fill
    ]
}

extension UIControl.ContentHorizontalAlignment: CustomImageConvertible {
    var image: UIImage? {
        switch self {
        case .leading:
            return IconKit.imageOfHorizontalAlignmentLeading()

        case .left:
            return IconKit.imageOfHorizontalAlignmentLeft()

        case .center:
            return IconKit.imageOfHorizontalAlignmentCenter()

        case .right:
            return IconKit.imageOfHorizontalAlignmentRight()

        case .trailing:
            return IconKit.imageOfHorizontalAlignmentTrailing()

        case .fill:
            return IconKit.imageOfHorizontalAlignmentFill()

        @unknown default:
            return nil
        }
    }
}

extension UIControl.ContentVerticalAlignment: @retroactive CaseIterable {
    public typealias AllCases = [UIControl.ContentVerticalAlignment]

    public static let allCases: [UIControl.ContentVerticalAlignment] = [
        .top,
        .center,
        .bottom,
        .fill
    ]
}

extension UIControl.ContentVerticalAlignment: CustomImageConvertible {
    var image: UIImage? {
        switch self {
        case .center:
            return IconKit.imageOfVerticalAlignmentCenter()

        case .top:
            return IconKit.imageOfVerticalAlignmentTop()

        case .bottom:
            return IconKit.imageOfVerticalAlignmentBottom()

        case .fill:
            return IconKit.imageOfVerticalAlignmentFill()

        @unknown default:
            return nil
        }
    }
}

extension UIControl.State: CustomStringConvertible {
    var description: String {
        switch self {
        case .normal:
            return Texts.default

        case .highlighted:
            return "Highlighted"

        case .disabled:
            return "Disabled"

        case .selected:
            return "Selected"

        case .focused:
            return "Focused"

        case .application:
            return "Application"

        case .reserved:
            return "Reserved"

        default:
            return "Unknown"
        }
    }
}

extension UIControl {
    enum ScaleDirection {
        case `in`, out
    }

    func scale(_ type: ScaleDirection, for event: UIEvent?) {
        switch event?.type {
        case .presses, .touches:
            break

        default:
            return
        }

        let duration = type == .in ? 0.10 : 0.15

        UIView.animate(
            withDuration: duration,
            delay: .zero,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                switch type {
                case .in:
                    self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)

                case .out:
                    self.transform = .identity
                }
            }
        )
    }
}
