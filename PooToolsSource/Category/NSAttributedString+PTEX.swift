//
//  NSAttributedString+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit

public extension NSAttributedString {
    @objc func sizeOfAttributedString(width:CGFloat = CGFloat.greatestFiniteMagnitude,
                                      height:CGFloat = CGFloat.greatestFiniteMagnitude,
                                      options:NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]) -> CGSize {
        let attributedStringSize = boundingRect(with: CGSizeMake(width, height), options: options, context: nil)
        return attributedStringSize.size
    }
    
    func largestFontSize() -> CGFloat {
        var largestFontSize: CGFloat = 0

        self.enumerateAttribute(.font, in: NSRange(location: 0, length: self.length), options: []) { value, range, stop in
            if let font = value as? UIFont {
                if font.pointSize > largestFontSize {
                    largestFontSize = font.pointSize
                }
            }
        }

        return largestFontSize
    }
}
