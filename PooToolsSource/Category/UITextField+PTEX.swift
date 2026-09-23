//
//  UITextField+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 14/1/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import Foundation

@MainActor private var maxLengthKey:UInt8 = 0

public extension UITextField {
    /// English: Adds a reusable left inset using the native left-view mechanism.
    /// Español: Añade un margen izquierdo reutilizable mediante el mecanismo nativo de leftView.
    /// 中文：使用系统 leftView 机制添加可复用的左侧内边距。
    @MainActor
    func addPaddingLeft(_ width: CGFloat) {
        guard width > 0 else {
            leftView = nil
            leftViewMode = .never
            return
        }

        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: width, height: bounds.height))
        leftView = paddingView
        leftViewMode = .always
    }

    /// English: Applies a color to the current placeholder without changing its text.
    /// Español: Aplica un color al placeholder actual sin cambiar su texto.
    /// 中文：在不改变占位文字的情况下设置当前 placeholder 的颜色。
    @MainActor
    func setPlaceHolderTextColor(_ color: UIColor) {
        guard let placeholder else { return }
        attributedPlaceholder = NSAttributedString(string: placeholder,
                                                    attributes: [.foregroundColor: color])
    }

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
