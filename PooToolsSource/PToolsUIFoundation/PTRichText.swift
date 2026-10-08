//
//  PTRichText.swift
//  PToolsUIFoundation
//
// English: A Foundation.AttributedString-backed rich text value for UIKit clients.
// Español: Un valor de texto enriquecido respaldado por Foundation.AttributedString para clientes UIKit.
// 中文：为 UIKit 调用方提供基于 Foundation.AttributedString 的富文本值模型。
//

import Foundation
import UIKit
import AVFoundation
import ObjectiveC

public struct PTTextActionID: Hashable, Codable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String = UUID().uuidString) {
        self.rawValue = rawValue
    }
}

public enum PTTextInteractionKind: String, Sendable {
    case tap
    case longPress
    case link
    case custom
}

public struct PTTextActionEvent: Sendable {
    public let actionID: PTTextActionID
    public let range: NSRange
    public let text: String
    public let interaction: PTTextInteractionKind

    public init(actionID: PTTextActionID,
                range: NSRange,
                text: String,
                interaction: PTTextInteractionKind) {
        self.actionID = actionID
        self.range = range
        self.text = text
        self.interaction = interaction
    }
}

public struct PTTextActionToken: Hashable, Sendable {
    public let id: PTTextActionID

    public init(id: PTTextActionID) {
        self.id = id
    }
}

public struct PTRichText: Sendable, Equatable, CustomStringConvertible,
                          ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    fileprivate var storage: Foundation.AttributedString

    private static let matcherCache = PTTextMatcherCache()

    static let actionAttributeKey = NSAttributedString.Key("PTools.actionID")
    static let attachmentAttributeKey = NSAttributedString.Key("PTools.attachmentID")

    public init(_ text: String) {
        storage = Foundation.AttributedString(text)
    }

    public init(_ attributedString: Foundation.AttributedString) {
        storage = attributedString
    }

    public init(_ attributedString: NSAttributedString) {
        storage = Self.makeStorage(from: attributedString)
    }

    public init(string text: String, _ attributes: PTTextAttribute...) {
        self.init(string: text, with: attributes)
    }

    public init(string text: String, with attributes: [PTTextAttribute] = []) {
        let value = NSMutableAttributedString(string: text)
        Self.apply(attributes,
                   to: value,
                   range: NSRange(location: 0, length: value.length),
                   policy: .keepNew)
        storage = Self.makeStorage(from: value)
    }

    public init(_ text: String, _ attributes: PTTextAttribute...) {
        self.init(string: text, with: attributes)
    }

    public init(_ text: String, with attributes: [PTTextAttribute] = []) {
        self.init(string: text, with: attributes)
    }

    public init(@PTRichTextBuilder _ content: () -> PTRichText) {
        self = content()
    }

    public init(_ text: PTRichText, _ attributes: PTTextAttribute...) {
        self.init(text, with: attributes)
    }

    public init(_ text: PTRichText, with attributes: [PTTextAttribute] = []) {
        let value = NSMutableAttributedString(attributedString: text.value)
        Self.apply(attributes,
                   to: value,
                   range: NSRange(location: 0, length: value.length),
                   policy: .keepNew)
        storage = Self.makeStorage(from: value)
    }

    public init(wrap mode: PTTextWrapMode, _ attributes: PTTextAttribute...) {
        self.init(wrap: mode, with: attributes)
    }

    public init(wrap mode: PTTextWrapMode, with attributes: [PTTextAttribute]) {
        let source: PTRichText
        let policy: PTTextMergePolicy
        switch mode {
        case .embedding(let value):
            source = value
            policy = .keepExisting
        case .override(let value):
            source = value
            policy = .keepNew
        }

        let value = NSMutableAttributedString(attributedString: source.value)
        Self.apply(attributes,
                   to: value,
                   range: NSRange(location: 0, length: value.length),
                   policy: policy)
        storage = Self.makeStorage(from: value)
    }

    public init(markdown: String) throws {
        storage = try Foundation.AttributedString(markdown: markdown)
    }

    public init(localized resource: LocalizedStringResource) {
        storage = Foundation.AttributedString(localized: resource)
    }

    public var attributedString: Foundation.AttributedString {
        storage
    }

    public var value: NSAttributedString {
        Self.makeUIKitValue(from: storage)
    }

    public var nsAttributedString: NSAttributedString {
        value
    }

    public var plainText: String {
        String(storage.characters)
    }

    public var characters: Foundation.AttributedString.CharacterView {
        storage.characters
    }

    public var length: Int {
        value.length
    }

    public var isEmpty: Bool {
        storage.characters.isEmpty
    }

    public var description: String {
        plainText
    }

    public func validatedNSRange(_ range: NSRange) -> NSRange? {
        guard range.location >= 0,
              range.length >= 0,
              range.location <= value.length,
              range.length <= value.length - range.location else {
            return nil
        }

        guard let attributedRange = attributedRange(from: range),
              NSRange(attributedRange, in: storage) == range else {
            return nil
        }
        return range
    }

    public func attributedRange(from range: NSRange) -> Range<Foundation.AttributedString.Index>? {
        guard range.location >= 0,
              range.length >= 0,
              range.location <= value.length,
              range.length <= value.length - range.location else {
            return nil
        }

        let string = plainText
        let startStringIndex = String.Index(utf16Offset: range.location, in: string)
        let endStringIndex = String.Index(utf16Offset: range.location + range.length, in: string)
        guard startStringIndex.utf16Offset(in: string) == range.location,
              endStringIndex.utf16Offset(in: string) == range.location + range.length,
              let start = Foundation.AttributedString.Index(startStringIndex, within: storage),
              let end = Foundation.AttributedString.Index(endStringIndex, within: storage) else {
            return nil
        }
        return start..<end
    }

    public func validatedRange(_ range: NSRange) -> PTTextRange? {
        guard let value = attributedRange(from: range) else { return nil }
        return PTTextRange(value)
    }

    public func nsRange(for range: PTTextRange) -> NSRange {
        NSRange(range.value, in: storage)
    }

    public func nsRange(from range: Range<Foundation.AttributedString.Index>) -> NSRange {
        NSRange(range, in: storage)
    }

    public func range(of text: String,
                      options: String.CompareOptions = [],
                      locale: Locale? = nil) -> Range<Foundation.AttributedString.Index>? {
        storage.range(of: text, options: options, locale: locale)
    }

    public mutating func mergeAttributes(_ attributes: [PTTextAttribute],
                                         in range: Range<Foundation.AttributedString.Index>,
                                         policy: PTTextMergePolicy = .keepNew) {
        let nsRange = nsRange(from: range)
        mergeAttributes(attributes, in: nsRange, policy: policy)
    }

    public mutating func mergeAttributes(_ style: PTTextStyle,
                                         in range: Range<Foundation.AttributedString.Index>,
                                         policy: PTTextMergePolicy = .keepNew) {
        mergeAttributes(style.attributes, in: range, policy: policy)
    }

    public mutating func mergeAttributes(_ attributes: [PTTextAttribute],
                                         in ranges: [Range<Foundation.AttributedString.Index>],
                                         policy: PTTextMergePolicy = .keepNew) {
        for range in ranges {
            mergeAttributes(attributes, in: range, policy: policy)
        }
    }

    public mutating func mergeAttributes(_ attributes: [PTTextAttribute],
                                         in range: NSRange,
                                         policy: PTTextMergePolicy = .keepNew) {
        guard let safeRange = validatedNSRange(range) else { return }
        let value = NSMutableAttributedString(attributedString: self.value)
        Self.apply(attributes, to: value, range: safeRange, policy: policy)
        storage = Self.makeStorage(from: value)
    }

    // English: Keep semantic action metadata typed at the API boundary and mirror it to the UIKit bridge.
    // Español: Mantiene los metadatos semánticos tipados en la API y los refleja en el puente UIKit.
    // 中文：在 API 边界保留类型化语义元数据，并同步到 UIKit 桥接属性。
    public mutating func applyAction(_ actionID: PTTextActionID,
                                     in range: Range<Foundation.AttributedString.Index>) {
        guard !range.isEmpty else { return }
        var typedSlice = storage[range]
        typedSlice[PTTextActionAttribute.self] = actionID.rawValue
        storage.replaceSubrange(range, with: typedSlice)
        let value = NSMutableAttributedString(attributedString: self.value)
        let nsRange = NSRange(range, in: storage)
        guard nsRange.length > 0 else { return }
        value.addAttribute(Self.actionAttributeKey, value: actionID.rawValue, range: nsRange)
        storage = Self.makeStorage(from: value)
    }

    // English: Keep attachment identifiers typed at the API boundary and retain the UIKit compatibility attribute.
    // Español: Mantiene los identificadores tipados en la API y conserva el atributo compatible con UIKit.
    // 中文：在 API 边界保留类型化附件标识，同时保留 UIKit 兼容属性。
    public mutating func applyAttachment(_ identifier: String,
                                         in range: Range<Foundation.AttributedString.Index>) {
        guard !range.isEmpty else { return }
        var typedSlice = storage[range]
        typedSlice[PTTextAttachmentAttribute.self] = identifier
        storage.replaceSubrange(range, with: typedSlice)
        let value = NSMutableAttributedString(attributedString: self.value)
        let nsRange = NSRange(range, in: storage)
        guard nsRange.length > 0 else { return }
        value.addAttribute(Self.attachmentAttributeKey, value: identifier, range: nsRange)
        storage = Self.makeStorage(from: value)
    }

    public mutating func replaceAttributes(_ attributes: [PTTextAttribute],
                                           in range: Range<Foundation.AttributedString.Index>) {
        mergeAttributes(attributes, in: range, policy: .replaceAll)
    }

    public mutating func replaceSubrange(_ range: Range<Foundation.AttributedString.Index>,
                                         with replacement: PTRichText,
                                         stylePolicy: PTTextInsertionStylePolicy = .replacementOnly) {
        var replacementValue = replacement
        switch stylePolicy {
        case .replacementOnly:
            break
        case .inheritLeading, .inheritTrailing:
            let sourceRange = nsRange(from: range)
            guard let inheritedIndex = inheritedAttributeIndex(for: sourceRange, policy: stylePolicy),
                  replacement.value.length > 0 else {
                break
            }

            let inheritedAttributes = value.attributes(at: inheritedIndex, effectiveRange: nil)
            let replacementAttributes = NSMutableAttributedString(attributedString: replacement.value)
            let replacementRange = NSRange(location: 0, length: replacementAttributes.length)
            let missing = inheritedAttributes.filter {
                replacementAttributes.attribute($0.key, at: 0, effectiveRange: nil) == nil
            }
            replacementAttributes.addAttributes(missing, range: replacementRange)
            replacementValue = PTRichText(replacementAttributes)
        case .merge(let policy):
            let sourceRange = nsRange(from: range)
            guard let inheritedIndex = inheritedAttributeIndex(for: sourceRange, policy: stylePolicy),
                  replacement.value.length > 0 else {
                break
            }

            let inheritedAttributes = value.attributes(at: inheritedIndex, effectiveRange: nil)
            let replacementAttributes = NSMutableAttributedString(attributedString: replacement.value)
            let replacementRange = NSRange(location: 0, length: replacementAttributes.length)
            let inherited = inheritedAttributes.map { PTTextAttribute(values: [$0.key: $0.value]) }
            Self.apply(inherited, to: replacementAttributes, range: replacementRange, policy: policy)
            replacementValue = PTRichText(replacementAttributes)
        }
        storage.replaceSubrange(range, with: replacementValue.storage)
    }

    private func inheritedAttributeIndex(for range: NSRange,
                                         policy: PTTextInsertionStylePolicy) -> Int? {
        guard value.length > 0 else { return nil }
        switch policy {
        case .inheritLeading, .merge:
            return range.location > 0 ? range.location - 1 : (NSMaxRange(range) < value.length ? NSMaxRange(range) : nil)
        case .inheritTrailing:
            return NSMaxRange(range) < value.length ? NSMaxRange(range) : (range.location > 0 ? range.location - 1 : nil)
        case .replacementOnly:
            return nil
        }
    }

    public mutating func insert(_ content: PTRichText,
                                at index: Foundation.AttributedString.Index) {
        storage.insert(content.storage, at: index)
    }

    public mutating func removeSubrange(_ range: Range<Foundation.AttributedString.Index>) {
        storage.removeSubrange(range)
    }

    public func matches(for rule: PTTextMatchRule,
                        conflictPolicy: PTTextMatchConflictPolicy = .priority) -> [PTTextMatch] {
        let fullRange = NSRange(location: 0, length: value.length)
        let matches: [PTTextMatch]
        switch rule {
        case .range(let range):
            guard let safeRange = validatedNSRange(range) else { return [] }
            matches = [PTTextMatch(range: safeRange, kind: .range, text: value.attributedSubstring(from: safeRange).string)]
        case .regex(let pattern, let rawOptions):
            guard let regex = Self.matcherCache.regex(pattern: pattern, options: rawOptions) else { return [] }
            matches = regex.matches(in: plainText, range: fullRange).compactMap { result in
                guard let safeRange = validatedNSRange(result.range), safeRange.length > 0 else { return nil }
                return PTTextMatch(range: safeRange,
                                   kind: .regex,
                                   text: value.attributedSubstring(from: safeRange).string)
            }
        case .custom:
            matches = []
        case .link, .date, .phoneNumber, .address, .transitInformation:
            let checkingType: NSTextCheckingResult.CheckingType
            let kind: PTTextMatchKind
            switch rule {
            case .link:
                checkingType = .link
                kind = .link
            case .date:
                checkingType = .date
                kind = .date
            case .phoneNumber:
                checkingType = .phoneNumber
                kind = .phoneNumber
            case .address:
                checkingType = .address
                kind = .address
            case .transitInformation:
                checkingType = .transitInformation
                kind = .transitInformation
            default:
                return []
            }
            guard let detector = Self.matcherCache.detector(for: checkingType) else { return [] }
            matches = detector.matches(in: plainText, options: [], range: fullRange).compactMap { result in
                guard let safeRange = validatedNSRange(result.range), safeRange.length > 0 else { return nil }
                return PTTextMatch(range: safeRange,
                                   kind: kind,
                                   text: value.attributedSubstring(from: safeRange).string)
            }
        }
        return Self.resolve(matches: matches, policy: conflictPolicy)
    }

    public mutating func mergeAttributes(_ attributes: [PTTextAttribute],
                                         matching rule: PTTextMatchRule,
                                         policy: PTTextMergePolicy = .keepNew,
                                         conflictPolicy: PTTextMatchConflictPolicy = .priority) {
        for match in matches(for: rule, conflictPolicy: conflictPolicy) {
            mergeAttributes(attributes, in: match.range, policy: policy)
        }
    }

    public mutating func replaceMatches(of rule: PTTextMatchRule,
                                        conflictPolicy: PTTextMatchConflictPolicy = .priority,
                                        with replacement: (PTTextMatch) -> PTRichText) {
        let matches = matches(for: rule, conflictPolicy: conflictPolicy)
        for match in matches.sorted(by: { $0.range.location > $1.range.location }) {
            guard let range = attributedRange(from: match.range) else { continue }
            replaceSubrange(range, with: replacement(match))
        }
    }

    public static func + (lhs: PTRichText, rhs: PTRichText) -> PTRichText {
        var result = lhs
        result.storage.append(rhs.storage)
        return result
    }

    public static func + (lhs: PTRichText, rhs: String) -> PTRichText {
        lhs + PTRichText(rhs)
    }

    public static func += (lhs: inout PTRichText, rhs: PTRichText) {
        lhs.storage.append(rhs.storage)
    }

    public static func += (lhs: inout PTRichText, rhs: String) {
        lhs += PTRichText(rhs)
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        private var result = PTRichText("")

        public init(literalCapacity: Int, interpolationCount: Int) {
            result.storage = Foundation.AttributedString("")
        }

        public mutating func appendLiteral(_ literal: String) {
            result += literal
        }

        public mutating func appendInterpolation(_ value: String) {
            result += value
        }

        public mutating func appendInterpolation(_ value: String,
                                                 _ attributes: PTTextAttribute...) {
            result += PTRichText(string: value, with: attributes)
        }

        public mutating func appendInterpolation(_ value: String,
                                                 _ attribute: PTTextAttribute?) {
            guard let attribute else {
                result += value
                return
            }
            result += PTRichText(string: value, with: [attribute])
        }

        public mutating func appendInterpolation(_ value: PTRichText,
                                                 _ attributes: PTTextAttribute...) {
            result += PTRichText(value, with: attributes)
        }

        // English: Insert an inline attachment using the object-replacement character.
        // Español: Inserta un adjunto en línea usando el carácter de reemplazo de objeto.
        // 中文：使用对象替换字符插入内嵌附件。
        public mutating func appendInterpolation(_ value: PTTextAttribute) {
            result += PTRichText(string: "\u{FFFC}", with: [value])
        }

        public mutating func appendInterpolation(wrap value: PTTextWrapMode,
                                                 _ attributes: PTTextAttribute...) {
            result += PTRichText(wrap: value, with: attributes)
        }

        public mutating func appendInterpolation<T>(_ value: T) {
            result += String(describing: value)
        }

        fileprivate func build() -> PTRichText {
            result
        }
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public init(stringInterpolation: StringInterpolation) {
        self = stringInterpolation.build()
    }

    // English: Construct an iOS 18+ adaptive glyph without flattening its system attributes.
    // Español: Construye un glyph adaptativo de iOS 18+ sin aplanar sus atributos del sistema.
    // 中文：在 iOS 18+ 创建自适应图像字形，不扁平化系统属性。
    @available(iOS 18.0, *)
    public init(adaptiveImageGlyph glyph: NSAdaptiveImageGlyph) {
        var value = Foundation.AttributedString("\u{FFFC}")
        value.uiKit.adaptiveImageGlyph = Foundation.AttributedString.AdaptiveImageGlyph(glyph)
        self.init(value)
    }

    @available(iOS 18.0, *)
    public var containsAdaptiveImageGlyph: Bool {
        guard value.length > 0 else { return false }
        var found = false
        value.enumerateAttribute(.adaptiveImageGlyph,
                                 in: NSRange(location: 0, length: value.length),
                                 options: []) { attribute, _, stop in
            guard attribute != nil else { return }
            found = true
            stop.pointee = true
        }
        return found
    }

    private static func apply(_ attributes: [PTTextAttribute],
                              to value: NSMutableAttributedString,
                              range: NSRange,
                              policy: PTTextMergePolicy) {
        guard range.location >= 0,
              range.length > 0,
              range.location + range.length <= value.length,
              !attributes.isEmpty else { return }

        let requested = attributes.reduce(into: [NSAttributedString.Key: Any]()) { result, attribute in
            result.merge(attribute.values, uniquingKeysWith: { _, new in new })
        }

        switch policy {
        case .keepNew:
            value.addAttributes(requested, range: range)
        case .replaceAll:
            value.setAttributes(requested, range: range)
        case .keepExisting:
            value.enumerateAttributes(in: range, options: []) { existing, subrange, _ in
                let missing = requested.filter { existing[$0.key] == nil }
                guard !missing.isEmpty else { return }
                value.addAttributes(missing, range: subrange)
            }
        }
    }

    // English: Preserve semantic identifiers across the Foundation/UIKit attributed-string bridge.
    // Español: Conserva los identificadores semánticos al cruzar el puente de texto atribuido Foundation/UIKit.
    // 中文：跨越 Foundation/UIKit 富文本桥接时保留语义标识。
    private static func makeStorage(from value: NSAttributedString) -> Foundation.AttributedString {
        var storage = Foundation.AttributedString(value)
        let fullRange = NSRange(location: 0, length: value.length)

        value.enumerateAttribute(actionAttributeKey,
                                  in: fullRange,
                                  options: []) { rawValue, range, _ in
            guard let actionID = rawValue as? String,
                  let storageRange = Range(range, in: storage) else {
                return
            }
            var slice = storage[storageRange]
            slice[PTTextActionAttribute.self] = actionID
            storage.replaceSubrange(storageRange, with: slice)
        }

        value.enumerateAttribute(attachmentAttributeKey,
                                  in: fullRange,
                                  options: []) { rawValue, range, _ in
            guard let attachmentID = rawValue as? String,
                  let storageRange = Range(range, in: storage) else {
                return
            }
            var slice = storage[storageRange]
            slice[PTTextAttachmentAttribute.self] = attachmentID
            storage.replaceSubrange(storageRange, with: slice)
        }

        return storage
    }

    // English: Rehydrate semantic identifiers only at the UIKit rendering boundary.
    // Español: Rehidrata los identificadores semánticos únicamente en el límite de renderizado UIKit.
    // 中文：仅在 UIKit 渲染边界恢复语义标识。
    private static func makeUIKitValue(from storage: Foundation.AttributedString) -> NSAttributedString {
        let value = NSMutableAttributedString(storage)

        for run in storage.runs {
            let range = NSRange(run.range, in: storage)
            if let actionID = run[PTTextActionAttribute.self] {
                value.addAttribute(actionAttributeKey, value: actionID, range: range)
            }
            if let attachmentID = run[PTTextAttachmentAttribute.self] {
                value.addAttribute(attachmentAttributeKey, value: attachmentID, range: range)
            }
        }

        return value
    }

    private static func resolve(matches: [PTTextMatch],
                                policy: PTTextMatchConflictPolicy) -> [PTTextMatch] {
        guard policy != .allowOverlap else {
            return matches.sorted { lhs, rhs in
                lhs.range.location == rhs.range.location ? lhs.range.length > rhs.range.length : lhs.range.location < rhs.range.location
            }
        }

        let ordered: [PTTextMatch]
        switch policy {
        case .lastWins:
            ordered = matches.sorted { lhs, rhs in
                lhs.range.location == rhs.range.location ? lhs.range.length < rhs.range.length : lhs.range.location < rhs.range.location
            }
        case .longestWins:
            ordered = matches.sorted { lhs, rhs in
                lhs.range.length == rhs.range.length ? lhs.range.location < rhs.range.location : lhs.range.length > rhs.range.length
            }
        case .priority, .firstWins:
            ordered = matches.sorted { lhs, rhs in
                lhs.range.location == rhs.range.location ? lhs.range.length > rhs.range.length : lhs.range.location < rhs.range.location
            }
        case .allowOverlap:
            ordered = matches
        }

        var accepted: [PTTextMatch] = []
        for match in ordered {
            let overlaps = accepted.contains { existing in
                NSIntersectionRange(existing.range, match.range).length > 0
            }
            if !overlaps {
                accepted.append(match)
            }
        }
        return accepted.sorted { $0.range.location < $1.range.location }
    }
}
