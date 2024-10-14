//
//  UITextView+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UITextView {
    convenience init(_ options: Option...) {
        self.init(options)
    }
    
    convenience init(_ options: Options) {
        self.init()
        apply(textViewOptions: options)
    }
}

public extension UITextView {
    /// Applies the appeareance options to the text view instance.
    /// - Parameter textViewOptions: The text view appearance options.
    func apply(textViewOptions: Option...) {
        apply(textViewOptions: textViewOptions)
    }
        
    /// Applies the appeareance options to the text view instance.
    /// - Parameter textViewOptions: The text view appearance options.
    func apply(textViewOptions: Options) {
        textViewOptions.forEach { option in
            switch option {
            case let .font(font):
                self.font = font
                
            case let .textColor(textColor):
                self.textColor = textColor
                
            case let .alignment(alignment):
                self.textAlignment = alignment
                
            case let .isEditable(isEditable):
                self.isEditable = isEditable
                
            case let .textContainerInset(textContainerInset):
                self.textContainerInset = textContainerInset
                
            case let .clearsOnInsertion(clearsOnInsertion):
                self.clearsOnInsertion = clearsOnInsertion
                
            case let .dataDetectorTypes(dataDetectorTypes):
                self.dataDetectorTypes = dataDetectorTypes
                
            case let .text(text):
                self.text = text
                
            case let .attributedText(attributedText):
                self.attributedText = attributedText
                
            case let .delegate(delegate):
                self.delegate = delegate
                                
            case let .viewOptions(viewOptions):
                apply(viewOptions: viewOptions)
                
            case let .scrollViewOptions(scrollViewOptions):
                apply(scrollViewOptions: scrollViewOptions)
            }
        }
    }
    
    typealias Options = [Option]
    
    /// An object that defines the appearance of a text view.
    enum Option {
        /// The text that the text view displays.
        case text(String?)
        
        case delegate(UITextViewDelegate)
        
        /// The styled text that the text view displays.
        case attributedText(NSAttributedString?)
        
        /// The font of the text.
        case font(UIFont?)
        
        /// The color of the text.
        case textColor(UIColor)
        
        /// The technique for aligning the text.
        case alignment(NSTextAlignment)
        
        /// A Boolean value that indicates whether the text view is editable.
        case isEditable(Bool)
        
        /// The inset of the text container's layout area within the text view's content area.
        case textContainerInset(UIEdgeInsets)
        
        /// A Boolean value that indicates whether inserting text replaces the previous contents.
        case clearsOnInsertion(Bool)
        
        /// The types of data that convert to tappable URLs in the text view.
        case dataDetectorTypes(UIDataDetectorTypes)
        
        /// The appearance options of the view.
        case viewOptions(UIView.Options)
        
        /// The options of the scroll view.
        case scrollViewOptions(UIScrollView.Options)
        
        // MARK: - Convenience
        
        /// A Boolean value that determines whether scrolling is enabled.
        public static func isScrollEnabled(_ isScrollEnabled: Bool) -> Self {
            .scrollViewOptions(.isScrollEnabled(isScrollEnabled))
        }
        
        /// The text view’s background color.
        public static func backgroundColor(_ color: UIColor?) -> Self {
            .viewOptions(.backgroundColor(color))
        }
        
        /// The text view’s tint color.
        public static func tintColor(_ color: UIColor) -> Self {
            .viewOptions(.tintColor(color))
        }
        
        /// The custom distance that the content view is inset from the safe area or scroll view edges.
        public static func contentInset(_ contentInset: UIEdgeInsets) -> Self {
            .scrollViewOptions(.contentInset(contentInset))
        }
        
        /// The custom distance that the content view is inset from the safe area or scroll view edges.
        public static func contentInset(top: CGFloat = .zero, left: CGFloat = .zero, bottom: CGFloat = .zero, right: CGFloat = .zero) -> Self {
            .contentInset(UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
        }
        
        /// The custom distance that the content view is inset from the safe area or scroll view edges.
        public static func contentInset<T: RawRepresentable>(top: T? = nil, left: T? = nil, bottom: T? = nil, right: T? = nil) -> Self where T.RawValue == CGFloat {
            .contentInset(UIEdgeInsets(top: top, left: left, bottom: bottom, right: right))
        }
        
        /// Constants that describe the preferred styles for fonts.
        public static func textStyle(_ style: UIFont.TextStyle, traits: UIFontDescriptor.SymbolicTraits = []) -> Self {
            .font(UIFont.preferredFont(forTextStyle: style, with: traits))
        }
        
        /// The options of the scroll view.
        public static func scrollViewOptions(_ scrollViewOptions: UIScrollView.Option...) -> Self {
            .scrollViewOptions(scrollViewOptions)
        }
        
        /// The base appearance options of the text view.
        public static func viewOptions(_ options: UIView.Option...) -> Self {
            .viewOptions(options)
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

extension UITextView {
    convenience init(
        _ fontStyle: UIFont.TextStyle,
        _ text: String? = nil,
        textAlignment: NSTextAlignment = .natural,
        textColor: UIColor? = nil,
        isScrollEnabled: Bool = false,
        isSelectable: Bool = true,
        isEditable: Bool = false
    ) {
        self.init()

        self.text = text
        font = .preferredFont(forTextStyle: fontStyle)
        self.textAlignment = textAlignment
        self.isScrollEnabled = isScrollEnabled
        self.isSelectable = isSelectable
        self.isEditable = isEditable
        backgroundColor = nil

        if let textColor = textColor {
            self.textColor = textColor
        }

        textContainerInset = UIEdgeInsets(
            left: -textContainer.lineFragmentPadding,
            right: -textContainer.lineFragmentPadding
        )
    }
}
