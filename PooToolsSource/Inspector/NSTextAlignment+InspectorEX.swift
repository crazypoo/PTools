//
//  NSTextAlignment+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension NSTextAlignment: CaseIterable {
    public typealias AllCases = [NSTextAlignment]

    public static let allCases: [NSTextAlignment] = [
        .left,
        .center,
        .right,
        .justified,
        .natural
    ]
}

extension NSTextAlignment: CustomImageConvertible {
    var image: UIImage? {
        switch self {
        case .left:
            return IconKit.imageOfTextAlignmentLeft()

        case .center:
            return IconKit.imageOfTextAlignmentCenter()

        case .right:
            return IconKit.imageOfTextAlignmentRight()

        case .justified:
            return IconKit.imageOfTextAlignmentJustified()

        case .natural:
            return IconKit.imageOfTextAlignmentNatural()

        @unknown default:
            return nil
        }
    }
}
