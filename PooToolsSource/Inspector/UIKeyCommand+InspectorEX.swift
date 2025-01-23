//
//  UIKeyCommand+PTEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

public extension UIKeyCommand {
    
    static let inputTab = "\t"
    
    static let inputReturn = "\r"
    
    static let inputBackspace = "\u{8}"
    
    static let inputDelete = "\u{7F}"
    
    static let inputSpace = " "

}

public extension UIKeyCommand {
    
    /// Creates and returns a new key command object that matches the specified input and has a title.
    /// - Parameters:
    ///   - options: Options that describe the input keys, modifier flags, and discoverability title.
    ///   - action: The action method to execute on the responder object.
    convenience init(_ options: Options, title: String, action: Selector) {
        self.init(
            title: title,
            image: options.image,
            action: action,
            input: options.input,
            modifierFlags: options.modifierFlags,
            discoverabilityTitle: options.discoverabilityTitle,
            attributes: options.menuAttributes,
            state: options.menuState
        )
    }
    
    /// Creates and returns a new key command object that matches the specified input and has a title.
    /// - Parameters:
    ///   - options: Options that describe the input keys, modifier flags, and discoverability title.
    ///   - action: The action method to execute on the responder object.
    convenience init(_ options: Options, action: Selector) {
        guard let discoverabilityTitle = options.discoverabilityTitle else {
            self.init(
                input: options.input,
                modifierFlags: options.modifierFlags,
                action: action
            )
            return
        }
        
        self.init(
            title: discoverabilityTitle,
            image: options.image,
            action: action,
            input: options.input,
            modifierFlags: options.modifierFlags,
            discoverabilityTitle: discoverabilityTitle,
            attributes: options.menuAttributes,
            state: options.menuState
        )
    }
}

public extension UIKeyCommand {
    
    /// Options that specify how to create a `UIKeyCommand` object.
    indirect enum Options: Hashable {
        
        // MARK: Alphanumeric Keys
        
        /// Receives a combination of keys that must be pressed.
        case key(String)
        
        /// Receives a key that must be pressed.
        public static func key(_ character: Character) -> Options { .key(String(character)) }
        
        // MARK: Special Keys
        
        /// A string representing the return key.
        case `return`
        /// A string representing the up arrow key.
        case arrowDown
        /// A string representing the left arrow key.
        case arrowLeft
        /// A string representing the right arrow key.
        case arrowRight
        /// A string representing the up arrow key.
        case arrowUp
        /// A string representing the escape key.
        case escape
        /// A string representing the delete key.
        case delete
        /// A string representing the tab key.
        case tab
        /// A string representing the space bar key.
        case spaceBar
        /// A string representing the backspace key.
        case backspace
        
        // MARK: Modifier Keys
        
        /// A modifier flag that indicates the user pressed the `Option` key.
        case alternate(Options)
        /// A modifier flag that indicates the user pressed the `Caps Lock` key.
        case capsLock(Options)
        /// A modifier flag that indicates the user pressed the `Command` key.
        case command(Options)
        /// A modifier flag that indicates the user pressed the `Control` key.
        case control(Options)
        /// A modifier flag that indicates the user pressed the `Shift` key.
        case shift(Options)
        /// A modifier flag that indicates the user pressed a key located on the numeric keypad.
        case numericPad(Options)
        
        // MARK: Discoverability Title
        
        /// Only Key Commands with a discoverabilityTitle _will_ be discoverable in the UI.
        case discoverabilityTitle(title: String, key: Options)
        
        // MARK: Menu
        
        public enum MenuElementAttributes {
            case disabled, destructive, hidden
        }
        case menuAttributes(MenuElementAttributes, key: Options)

        public enum MenuElementState {
            case off, on, mixed
        }
        case menuState(MenuElementState, key: Options)

        // MARK: Image
        
        case image(UIImage, key: Options)

    }
}

// MARK: - Computed Properties

public extension UIKeyCommand.Options {
        
    /// The string of characters corresponding to the keys that must be pressed to match this key command.
    var input: String {
        switch self {
        case let .key(input):
            return input
        
        case .return:
            return UIKeyCommand.inputReturn
            
        case .arrowDown:
            return UIKeyCommand.inputDownArrow
            
        case .arrowLeft:
            return UIKeyCommand.inputLeftArrow
            
        case .arrowRight:
            return UIKeyCommand.inputRightArrow
            
        case .arrowUp:
            return UIKeyCommand.inputUpArrow
            
        case .escape:
            return UIKeyCommand.inputEscape
            
        case .tab:
            return UIKeyCommand.inputTab
            
        case .delete:
            return UIKeyCommand.inputDelete
        
        case .backspace:
            return UIKeyCommand.inputBackspace
            
        case .spaceBar:
            return UIKeyCommand.inputSpace
            
        case let .alternate(key),
             let .command(key),
             let .control(key),
             let .shift(key),
             let .capsLock(key),
             let .numericPad(key),
             let .discoverabilityTitle(_, key):
            return key.input
            
        case let .menuAttributes(_, key),
             let .menuState(_, key),
             let .image(_, key):
            return key.input
        }
    }
    
    /// The bit mask of modifier flags that must be pressed to match this key command.
    var modifierFlags: UIKeyModifierFlags {
        switch self {
        case let .alternate(key):
            return [.alternate, key.modifierFlags]
            
        case let .command(key):
            return [.command, key.modifierFlags]
            
        case let .control(key):
            return [.control, key.modifierFlags]
            
        case let .shift(key):
            return [.shift, key.modifierFlags]
            
        case let .capsLock(key):
            return [.alphaShift, key.modifierFlags]
            
        case let .numericPad(key):
            return [.numericPad, key.modifierFlags]
            
        case let .discoverabilityTitle(_, key):
            return key.modifierFlags
            
        case let .menuAttributes(_, key),
             let .menuState(_, key),
             let .image(_, key):
            return key.modifierFlags
        
        case .key,
             .return,
             .arrowDown,
             .arrowLeft,
             .arrowRight,
             .arrowUp,
             .escape,
             .delete,
             .tab,
             .spaceBar,
             .backspace:
            return []
        }
    }
    
    /// An elaborated title that explains the purpose of the key command.
    var discoverabilityTitle: String? {
        switch self {
        case let .discoverabilityTitle(title, _):
            return title
        
        case let .alternate(key),
             let .capsLock(key),
             let .command(key),
             let .control(key),
             let .shift(key),
             let .numericPad(key):
            return key.discoverabilityTitle
        
        case let .menuAttributes(_, key),
             let .menuState(_, key),
             let .image(_, key):
            return key.discoverabilityTitle
        
        case .key,
             .return,
             .arrowDown,
             .arrowLeft,
             .arrowRight,
             .arrowUp,
             .escape,
             .delete,
             .tab,
             .spaceBar,
             .backspace:
            return nil
        }
    }
    
    var menuState: UIMenuElement.State {
        guard case let .menuState(state, _) = self else {
            return .off
        }
        switch state {
        case .mixed:
            return .mixed
        case .on:
            return .on
        case .off:
            return .off
        }
    }
    
    var menuAttributes: UIMenuElement.Attributes {
        guard case let .menuAttributes(attributes, _) = self else {
            return []
        }
        switch attributes {
        case .disabled:
            return .disabled
        case .destructive:
            return .destructive
        case .hidden:
            return .hidden
        }
    }
    
    var image: UIImage? {
        guard case let .image(image, _) = self else {
            return nil
        }
        return image
    }
}

extension UIKeyCommand.Options {
    init(input: String, modifierFlags: UIKeyModifierFlags) {
        var options = UIKeyCommand.Options.key(input)

        let allModifiers: [UIKeyModifierFlags] = [
            .control,
            .command,
            .alphaShift,
            .shift,
            .alternate,
            .numericPad
        ]

        for modifier in allModifiers where modifierFlags.contains(modifier) {
            switch modifier {
            case .control:
                options = .control(options)

            case .command:
                options = .command(options)

            case .alphaShift:
                options = .capsLock(options)

            case .shift:
                options = .shift(options)

            case .alternate:
                options = .alternate(options)

            case .numericPad:
                options = .numericPad(options)

            default:
                continue
            }
        }

        self = options
    }
}
