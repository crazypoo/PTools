//
//  UITextField+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Foundation
import SwifterSwift

private var maxLengthKey:UInt8 = 0

public extension UITextField {
    var maxLength: Int {
        get {
            guard let length = getAssociatedObject(forKey: &maxLengthKey) as? Int else { return Int.max }
            return length
        } set {
            set(associatedObject: newValue, forKey: &maxLengthKey)
            addTarget(self, action: #selector(checkMaxLength), for: .editingChanged)
        }
    }
    
    @objc func checkMaxLength(textField: UITextField) {
        
        guard let prospectiveText:NSString = textField.text?.nsString, prospectiveText.length > maxLength else { return }
        let selection = selectedTextRange
        text = prospectiveText.substring(to: maxLength)
        selectedTextRange = selection
    }
    
    func setCursorAboveText() {
        let padding = textRect(forBounds: self.bounds)
        let cursorFrame = CGRect(x: padding.origin.x, y: padding.origin.y, width: 2, height: padding.size.height)
        tintColor = .clear
        let cursor = UIView(frame: cursorFrame)
        cursor.backgroundColor = .randomColor
        addSubview(cursor)
    }
    
    func removeTargetsAndActions() {
        removeTarget(nil, action: nil, for: .allEvents)
    }
}

public extension UITextField {
    func set(associatedObject object: Any,
             forKey key: UnsafeRawPointer) {
        objc_setAssociatedObject(self, key, object, .OBJC_ASSOCIATION_RETAIN)
    }

    func getAssociatedObject(forKey key: UnsafeRawPointer) -> Any? {
        objc_getAssociatedObject(self, key)
    }
}
