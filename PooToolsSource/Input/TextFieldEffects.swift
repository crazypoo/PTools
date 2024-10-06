//
//  TextFieldEffects.swift
//  TextFieldEffects
//
//  Created by Raúl Riera on 24/01/2015.
//  Copyright (c) 2015 Raul Riera. All rights reserved.
//

import UIKit

extension String {
    /**
     Returns true if the string contains characters, false if it's empty.
     */
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

/**
 A custom UITextField that handles unique text entry and display animations.
 */
open class TextFieldEffects: UITextField {
    /**
     The type of animation that can be performed by the text field.
     
     - textEntry: Animation triggered when the text field is focused.
     - textDisplay: Animation triggered when the text field loses focus.
     */
    public enum AnimationType: Int {
        case textEntry
        case textDisplay
    }
    
    /**
     A closure executed when an animation has been completed.
     */
    public typealias AnimationCompletionHandler = (_ type: AnimationType) -> Void
    
    /// A UILabel to display the placeholder text
    public let placeholderLabel = UILabel()
    
    /**
     Creates animations to display when text entry begins.
     This method should be overridden in subclasses.
     */
    open func animateViewsForTextEntry() {
        fatalError("\(#function) must be overridden")
    }
    
    /**
     Creates animations to display when text entry ends.
     This method should be overridden in subclasses.
     */
    open func animateViewsForTextDisplay() {
        fatalError("\(#function) must be overridden")
    }
    
    /// A completion handler that is triggered when animations finish.
    open var animationCompletionHandler: AnimationCompletionHandler?
    
    /**
     Custom drawing of the text field's components.
     
     - parameter rect: The area within the view to be redrawn.
     */
    open func drawViewsForRect(_ rect: CGRect) {
        fatalError("\(#function) must be overridden")
    }
    
    open func updateViewsForBoundsChange(_ bounds: CGRect) {
        fatalError("\(#function) must be overridden")
    }
    
    // MARK: - Overrides
    
    override open func draw(_ rect: CGRect) {
        // Avoid redundant redrawing if the text field is already selected
        guard !isFirstResponder else { return }
        drawViewsForRect(rect)
    }
    
    override open func drawPlaceholder(in rect: CGRect) {
        // Override to prevent the system from drawing placeholders
    }
    
    override open var text: String? {
        didSet {
            // Trigger appropriate animation based on text presence and responder state
            let shouldAnimateEntry = (text?.isNotEmpty ?? false) || isFirstResponder
            shouldAnimateEntry ? animateViewsForTextEntry() : animateViewsForTextDisplay()
        }
    }
    
    // MARK: - UITextField Observing
    
    override open func willMove(toSuperview newSuperview: UIView!) {
        if newSuperview != nil {
            NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidBeginEditing), name: UITextField.textDidBeginEditingNotification, object: self)
            NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidEndEditing), name: UITextField.textDidEndEditingNotification, object: self)
        } else {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    /**
     Triggered when text field starts editing.
     */
    @objc open func textFieldDidBeginEditing() {
        animateViewsForTextEntry()
    }
    
    /**
     Triggered when text field ends editing.
     */
    @objc open func textFieldDidEndEditing() {
        animateViewsForTextDisplay()
    }
    
    // MARK: - Interface Builder
    
    override open func prepareForInterfaceBuilder() {
        drawViewsForRect(frame)
    }
}
