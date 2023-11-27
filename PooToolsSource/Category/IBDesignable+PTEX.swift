//
//  IBDesignable+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 11/11/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import Foundation
import UIKit

// MARK: - UILabel localize Key extention for language in story board
@IBDesignable public extension UILabel {
    @IBInspectable var localizeKey: String? {
        set {
            // set new value from dictionary
            PTGCDManager.gcdMain {
                self.text = newValue?.localized()
            }
        }
        get {
            text
        }
    }
}

// MARK: - UIButton localize Key extention for language in story board
@IBDesignable public extension UIButton {
    @IBInspectable var localizeKey: String? {
        set {
            // set new value from dictionary
            PTGCDManager.gcdMain {
                self.setTitle(newValue?.localized(), for: .normal)
            }
        }
        get {
            titleLabel?.text
        }
    }
}

// MARK: - UITextView localize Key extention for language in story board
@IBDesignable public extension UITextView {

    @IBInspectable var localizeKey: String? {
        set {
            // set new value from dictionary
            PTGCDManager.gcdMain {
                self.text = newValue?.localized()
            }
        }
        get {
            text
        }
    }
}

// MARK: - UITextField localize Key extention for language in story board
@IBDesignable public extension UITextField {
    @IBInspectable var localizeKey: String? {
        set {
            // set new value from dictionary
            PTGCDManager.gcdMain {
                self.placeholder = newValue?.localized()
            }
        }
        get {
            placeholder
        }
    }
}

// MARK: - UINavigationItem localize Key extention for language in story board
@IBDesignable public extension UINavigationItem {
    @IBInspectable var localizeKey: String? {
        set {
            // set new value from dictionary
            PTGCDManager.gcdMain {
                self.title = newValue?.localized()
            }
        }
        get {
            title
        }
    }
}
