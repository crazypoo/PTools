//
//  NSObject+InspectorEX.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import Foundation

extension NSObjectProtocol where Self: NSObject {
    func debounce(_ aSelector: Selector, after delay: TimeInterval, object: Any? = nil) {
        Self.cancelPreviousPerformRequests(
            withTarget: self,
            selector: aSelector,
            object: object
        )
        
        perform(aSelector, with: object, afterDelay: delay)
    }
    
    var _classesForCoder: [AnyClass] {
        var array = [classForCoder]

        var objectClass: AnyClass = classForCoder

        while objectClass.superclass() != nil {
            guard let superclass = objectClass.superclass() else {
                break
            }

            array.append(superclass)
            objectClass = superclass
        }

        return array
    }
}

extension NSObject: Create {}

extension NSObject {
    static let propertyNamesDenyList = [
        "UINavigationBar._contentViewHidden",
        "UITextView.PINEntrySeparatorIndexes",
        "UITextView.acceptsDictationSearchResults",
        "UITextView.acceptsEmoji",
        "UITextView.acceptsFloatingKeyboard",
        "UITextView.acceptsInitialEmojiKeyboard",
        "UITextView.acceptsPayloads",
        "UITextView.acceptsSplitKeyboard",
        "UITextView.autocapitalizationType",
        "UITextView.autocorrectionContext",
        "UITextView.autocorrectionType",
        "UITextView.contentsIsSingleValue",
        "UITextView.deferBecomingResponder",
        "UITextView.disableHandwritingKeyboard",
        "UITextView.disableInputBars",
        "UITextView.disablePrediction",
        "UITextView.displaySecureEditsUsingPlainText",
        "UITextView.displaySecureTextUsingPlainText",
        "UITextView.emptyContentReturnKeyType",
        "UITextView.enablesReturnKeyAutomatically",
        "UITextView.enablesReturnKeyOnNonWhiteSpaceContent",
        "UITextView.floatingKeyboardEdgeInsets",
        "UITextView.forceDefaultDictationInfo",
        "UITextView.forceDictationKeyboardType",
        "UITextView.forceFloatingKeyboard",
        "UITextView.hasDefaultContents",
        "UITextView.hidePrediction",
        "UITextView.inputContextHistory",
        "UITextView.insertionPointColor",
        "UITextView.insertionPointWidth",
        "UITextView.isCarPlayIdiom",
        "UITextView.isSingleLineDocument",
        "UITextView.keyboardAppearance",
        "UITextView.keyboardType",
        "UITextView.learnsCorrections",
        "UITextView.loadKeyboardsForSiriLanguage",
        "UITextView.passwordRules",
        "UITextView.preferOnlineDictation",
        "UITextView.preferredKeyboardStyle",
        "UITextView.recentInputIdentifier",
        "UITextView.responseContext",
        "UITextView.returnKeyGoesToNextResponder",
        "UITextView.returnKeyType",
        "UITextView.selectionBarColor",
        "UITextView.selectionBorderColor",
        "UITextView.selectionBorderWidth",
        "UITextView.selectionCornerRadius",
        "UITextView.selectionDragDotImage",
        "UITextView.selectionEdgeInsets",
        "UITextView.selectionHighlightColor",
        "UITextView.shortcutConversionType",
        "UITextView.showDictationButton",
        "UITextView.smartDashesType",
        "UITextView.smartInsertDeleteType",
        "UITextView.smartQuotesType",
        "UITextView.spellCheckingType",
        "UITextView.supplementalLexicon",
        "UITextView.supplementalLexiconAmbiguousItemIcon",
        "UITextView.suppressReturnKeyStyling",
        "UITextView.textContentType",
        "UITextView.textLoupeVisibility",
        "UITextView.textScriptType",
        "UITextView.textSelectionBehavior",
        "UITextView.textSuggestionDelegate",
        "UITextView.textTrimmingSet",
        "UITextView.underlineColorForSpelling",
        "UITextView.underlineColorForTextAlternatives",
        "UITextView.useAutomaticEndpointing",
        "UITextView.useInterfaceLanguageForLocalization",
        "UITextView.validTextRange",
        "UITextField.textTrimmingSet",
        "WKContentView._wk_printedDocument",
        "WKWebView._wk_printedDocument"
    ]

    func propertyNames() -> [String] {
        var propertyCount: UInt32 = 0
        var propertyNames: [String] = []

        guard
            let propertyListPointer = class_copyPropertyList(type(of: self), &propertyCount),
            propertyCount > .zero
        else {
            return []
        }

        for index in 0 ..< Int(propertyCount) {
            let pointer = propertyListPointer[index]

            guard let propertyName = NSString(utf8String: property_getName(pointer)) as String?
            else { continue }

            propertyNames.append(propertyName)
        }

        free(propertyListPointer)
        return propertyNames.uniqueValues()
    }

    func safeValue(forKey key: String) -> Any? {
        let fullName = "\(_classNameWithoutQualifiers).\(key)"

        if Self.propertyNamesDenyList.contains(fullName) {
            return nil
        }
        return value(forKey: key)
    }
}

