//
//  UITextField+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UITextField {
    convenience init(_ options: Option...) {
        self.init(options)
    }
    
    convenience init(_ options: Options) {
        self.init()
        apply(textFieldOptions: options)
    }
}

public extension UITextField {
    
    func apply(textFieldOptions: Options) {
        textFieldOptions.forEach { option in
            switch option {
            case let .text(text):
                self.text = text
                
            case let .attributedText(attributedText):
                self.attributedText = attributedText
                
            case let .textColor(textColor):
                self.textColor = textColor
                
            case let .font(font):
                self.font = font
                
            case let .textAlignment(textAlignment):
                self.textAlignment = textAlignment
                
            case let .defaultTextAttributes(defaultTextAttributes):
                self.defaultTextAttributes = defaultTextAttributes
                
            case let .placeholder(placeholder):
                self.placeholder = placeholder
                
            case let .attributedPlaceholder(attributedPlaceholder):
                self.attributedPlaceholder = attributedPlaceholder
                
            case let .clearsOnBeginEditing(clearsOnBeginEditing):
                self.clearsOnBeginEditing = clearsOnBeginEditing
                
            case let .adjustsFontSizeToFitWidth(adjustsFontSizeToFitWidth):
                self.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
                
            case let .minimumFontSize(minimumFontSize):
                self.minimumFontSize = minimumFontSize
                
            case let .delegate(delegate):
                self.delegate = delegate
                
            case let .background(background):
                self.background = background
                
            case let .disabledBackground(disabledBackground):
                self.disabledBackground = disabledBackground
                
            case let .allowsEditingTextAttributes(allowsEditingTextAttributes):
                self.allowsEditingTextAttributes = allowsEditingTextAttributes
                
            case let .typingAttributes(typingAttributes):
                self.typingAttributes = typingAttributes
                
            case let .clearButtonMode(clearButtonMode):
                self.clearButtonMode = clearButtonMode
                
            case let .leftView(leftView):
                self.leftView = leftView
                
            case let .leftViewMode(leftViewMode):
                self.leftViewMode = leftViewMode
                
            case let .rightView(rightView):
                self.rightView = rightView
                
            case let .rightViewMode(rightViewMode):
                self.rightViewMode = rightViewMode
                
            case let .inputView(inputView):
                self.inputView = inputView
                
            case let .inputAccessoryView(inputAccessoryView):
                self.inputAccessoryView = inputAccessoryView
                
            case let .clearsOnInsertion(clearsOnInsertion):
                self.clearsOnInsertion = clearsOnInsertion
                
            case let .borderStyle(borderStyle):
                self.borderStyle = borderStyle
                
            case let .viewOptions(viewOptions):
                apply(viewOptions: viewOptions)
            }
        }
    }
    
    typealias Options = [Option]
    
    enum Option {
        /// The text that the text field displays.
        case text(String?)
        
        /// The styled text that the text field displays.
        case attributedText(NSAttributedString?)
        
        /// he color of the text.
        case textColor(UIColor?)
        
        /// The font of the text.
        case font(UIFont?)
        
        /// The border style for the text field.
        case borderStyle(UITextField.BorderStyle)
        
        /// The technique for aligning the text.
        case textAlignment(NSTextAlignment)
        
        /// The default attributes to apply to the text.
        case defaultTextAttributes([NSAttributedString.Key : Any])
        
        /// The string that displays when there is no other text in the text field.
        case placeholder(String?)
        
        /// The styled string that displays when there is no other text in the text field.
        case attributedPlaceholder(NSAttributedString?)
        
        /// A Boolean value that determines whether the text field removes old text when editing begins.
        case clearsOnBeginEditing(Bool)
        
        /// A Boolean value that indicates whether to reduce the font size to fit the text string into the text field’s bounding rectangle.
        case adjustsFontSizeToFitWidth(Bool)
        
        /// The size of the smallest permissible font when drawing the text field’s text.
        case minimumFontSize(CGFloat)
        
        /// The text field’s delegate.
        case delegate(UITextFieldDelegate?)
        
        /// The image that represents the background appearance of the text field when it is in an enabled state.
        case background(UIImage?)
        
        /// The image that represents the background appearance of the text field when it is in a disabled state.
        case disabledBackground(UIImage?)
        
        /// A Boolean value that determines whether the user can edit the attributes of the text in the text field.
        case allowsEditingTextAttributes(Bool)
        
        /// The attributes to apply to new text that the user enters.
        case typingAttributes([NSAttributedString.Key : Any]?)
        
        /// A mode that controls when the standard Clear button appears in the text field.
        case clearButtonMode(UITextField.ViewMode)
        
        /// The overlay view that displays on the left (or leading) side of the text field.
        case leftView(UIView?)
        
        /// A mode that controls when the left overlay view appears in the text field.
        case leftViewMode(UITextField.ViewMode)
        
        /// The overlay view that displays on the right (or trailing) side of the text field.
        case rightView(UIView?)
        
        /// A mode that controls when the right overlay view appears in the text field.
        case rightViewMode(UITextField.ViewMode)
        
        /// The custom input view to display when the text field becomes the first responder.
        case inputView(UIView?)
        
        /// The custom accessory view to display when the text field becomes the first responder.
        case inputAccessoryView(UIView?)
        
        /// A Boolean value that determines whether inserting text replaces the previous contents.
        case clearsOnInsertion(Bool)
        
        /// The appearance options of the view.
        case viewOptions(UIView.Options)
        
        // MARK: - Convenience
        
        /// Constants that describe the preferred styles for fonts.
        public static func textStyle(_ style: UIFont.TextStyle, traits: UIFontDescriptor.SymbolicTraits = []) -> Self {
            .font(UIFont.preferredFont(forTextStyle: style, with: traits))
        }
        
        /// The base appearance options of the text view.
        public static func viewOptions(_ options: UIView.Option...) -> Self {
            .viewOptions(options)
        }
        
        /// The text view’s background color.
        public static func backgroundColor(_ color: UIColor?) -> Self {
            .viewOptions(.backgroundColor(color))
        }
        
        /// The text view’s tint color.
        public static func tintColor(_ color: UIColor) -> Self {
            .viewOptions(.tintColor(color))
        }
        
        /// Describes the text view layer's appearance.
        public static func layerOptions(_ options: CALayer.Option...) -> Self {
            .viewOptions(.layerOptions(options))
        }
        
        /// The priority with which a view resists being made smaller than its intrinsic width or height.
        public static func compressionResistance(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
            .viewOptions(.layoutCompression(.compressionResistance(priority, for: axis)))
        }
        
        /// The priority with which a view resists being made larger than its intrinsic width or height.
        public static func huggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) -> Self {
            .viewOptions(.layoutCompression(.huggingPriority(priority, for: axis)))
        }
    }
}

extension UITextField.BorderStyle: CaseIterable {
    public typealias AllCases = [UITextField.BorderStyle]

    public static let allCases: [UITextField.BorderStyle] = [
        .none,
        .line,
        .bezel,
        .roundedRect
    ]
}

extension UITextField.BorderStyle: CustomImageConvertible {
    var image: UIImage? {
        switch self {
        case .none:
            return IconKit.imageOfBorderStyleNone()

        case .line:
            return IconKit.imageOfBorderStyleLine()

        case .bezel:
            return IconKit.imageOfBorderStyleBezel()

        case .roundedRect:
            return IconKit.imageOfBorderStyleRoundedRect()

        @unknown default:
            return nil
        }
    }
}

extension UITextField.ViewMode: CaseIterable {
    public typealias AllCases = [UITextField.ViewMode]

    public static let allCases: [UITextField.ViewMode] = [
        .never,
        .whileEditing,
        .unlessEditing,
        .always
    ]
}

extension UITextField.ViewMode: CustomStringConvertible {
    var description: String {
        switch self {
        case .never:
            return "Never"

        case .whileEditing:
            return "While Editing"

        case .unlessEditing:
            return "Unless Editing"

        case .always:
            return "Always"

        @unknown default:
            return "Unknown"
        }
    }
}
