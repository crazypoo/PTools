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

// English: Typed Foundation attributes keep semantic identifiers separate from UIKit rendering attributes.
// Español: Los atributos tipados de Foundation separan los identificadores semánticos de los atributos de renderizado UIKit.
// 中文：Foundation 类型化属性将语义标识与 UIKit 渲染属性分离。
public struct PTTextActionAttribute: CodableAttributedStringKey {
    public typealias Value = String
    public static let name = "PTools.actionID"

    public init() {}
}

public struct PTTextAttachmentAttribute: CodableAttributedStringKey {
    public typealias Value = String
    public static let name = "PTools.attachmentID"

    public init() {}
}

public struct PTTextAttributes: AttributeScope {
    public let actionID: PTTextActionAttribute
    public let attachmentID: PTTextAttachmentAttribute

    public init() {
        actionID = PTTextActionAttribute()
        attachmentID = PTTextAttachmentAttribute()
    }
}

public extension AttributeScopes {
    var ptools: PTTextAttributes { PTTextAttributes() }
}

public enum PTTextInteractionMode: Sendable {
    case actionsOnly
    case selectionAndLinks
    case hybrid
}

// English: Describe a semantic font without forcing callers to resolve Dynamic Type too early.
// Español: Describe una fuente semántica sin obligar a resolver Dynamic Type demasiado pronto.
// 中文：描述语义字体，避免调用方过早解析 Dynamic Type。
public enum PTTextFont {
    case textStyle(UIFont.TextStyle)
    case system(size: CGFloat, weight: UIFont.Weight)
    case custom(name: String, size: CGFloat)
    case resolved(UIFont)

    public func resolve() -> UIFont {
        switch self {
        case .textStyle(let style):
            return UIFont.preferredFont(forTextStyle: style)
        case .system(let size, let weight):
            return UIFont.systemFont(ofSize: size, weight: weight)
        case .custom(let name, let size):
            return UIFont(name: name, size: size) ?? UIFont.systemFont(ofSize: size)
        case .resolved(let font):
            return font
        }
    }
}

public enum PTTextMergePolicy: Sendable {
    case keepExisting
    case keepNew
    case replaceAll
}

public enum PTTextInsertionStylePolicy: Sendable {
    case inheritLeading
    case inheritTrailing
    case replacementOnly
    case merge(PTTextMergePolicy)
}

// English: Describe the size policy for an inline UIKit image attachment.
// Español: Describe la política de tamaño para una imagen UIKit insertada en el texto.
// 中文：描述富文本内嵌 UIKit 图片附件的尺寸策略。
public enum PTTextAttachmentStyle: Sendable {
    case custom(size: CGSize)
}

public enum PTTextAttachmentFailurePolicy: Sendable {
    case keepOriginal
    case placeholder
    case remove
}

public enum PTTextParagraphAttribute {
    case alignment(NSTextAlignment)
    case lineSpacing(CGFloat)
    case paragraphSpacing(CGFloat)
    case firstLineHeadIndent(CGFloat)
    case headIndent(CGFloat)
    case tailIndent(CGFloat)
    case lineBreakMode(NSLineBreakMode)
    case lineBreakStrategy(NSParagraphStyle.LineBreakStrategy)
    case minimumLineHeight(CGFloat)
    case maximumLineHeight(CGFloat)
    case baseWritingDirection(NSWritingDirection)
    case hyphenationFactor(Float)
}

public struct PTTextAttribute {
    fileprivate let values: [NSAttributedString.Key: Any]

    fileprivate init(values: [NSAttributedString.Key: Any]) {
        self.values = values
    }

    public static func font(_ font: UIFont) -> Self {
        Self(values: [.font: font])
    }

    public static func font(_ font: PTTextFont) -> Self {
        Self.font(font.resolve())
    }

    public static func foreground(_ color: UIColor) -> Self {
        Self(values: [.foregroundColor: color])
    }

    public static func background(_ color: UIColor) -> Self {
        Self(values: [.backgroundColor: color])
    }

    public static func baselineOffset(_ offset: CGFloat) -> Self {
        Self(values: [.baselineOffset: offset])
    }

    public static func ligature(_ value: Int = 1) -> Self {
        Self(values: [.ligature: value])
    }

    public static func kern(_ value: CGFloat) -> Self {
        Self(values: [.kern: value])
    }

    public static func shadow(_ value: NSShadow) -> Self {
        Self(values: [.shadow: value])
    }

    public static func stroke(width: CGFloat, color: UIColor? = nil) -> Self {
        var values: [NSAttributedString.Key: Any] = [.strokeWidth: width]
        if let color {
            values[.strokeColor] = color
        }
        return Self(values: values)
    }

    public static func obliqueness(_ value: CGFloat) -> Self {
        Self(values: [.obliqueness: value])
    }

    public static func expansion(_ value: CGFloat) -> Self {
        Self(values: [.expansion: value])
    }

    public static func writingDirection(_ value: [Int]) -> Self {
        Self(values: [.writingDirection: value])
    }

    public static func verticalGlyphForm(_ value: Bool) -> Self {
        Self(values: [.verticalGlyphForm: value ? 1 : 0])
    }

    public static func underline(_ style: NSUnderlineStyle,
                                 color: UIColor? = nil) -> Self {
        var values: [NSAttributedString.Key: Any] = [.underlineStyle: style.rawValue]
        if let color {
            values[.underlineColor] = color
        }
        return Self(values: values)
    }

    public static func strikethrough(_ style: NSUnderlineStyle,
                                     color: UIColor? = nil) -> Self {
        var values: [NSAttributedString.Key: Any] = [.strikethroughStyle: style.rawValue]
        if let color {
            values[.strikethroughColor] = color
        }
        return Self(values: values)
    }

    public static func link(_ url: URL) -> Self {
        Self(values: [.link: url])
    }

    public static func link(_ urlString: String) -> Self? {
        guard let url = URL(string: urlString) else { return nil }
        return .link(url)
    }

    // English: Build a native text attachment without storing an action closure in the value.
    // Español: Crea un adjunto nativo sin almacenar un cierre de acción dentro del valor.
    // 中文：创建原生文本附件，不把动作闭包存入富文本值。
    public static func image(_ image: UIImage,
                             _ style: PTTextAttachmentStyle) -> Self {
        let attachment = NSTextAttachment()
        attachment.image = image
        switch style {
        case .custom(let size):
            let fallback = image.size
            let width = size.width.isFinite && size.width > 0 ? size.width : max(1, fallback.width)
            let height = size.height.isFinite && size.height > 0 ? size.height : max(1, fallback.height)
            attachment.bounds = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        }
        return Self(values: [.attachment: attachment])
    }

    public static func image(_ image: UIImage) -> Self {
        Self.image(image, .custom(size: image.size))
    }

    public static func action(_ id: PTTextActionID) -> Self {
        Self(values: [PTRichText.actionAttributeKey: id.rawValue])
    }

    public static func action(_ rawValue: String) -> Self {
        .action(PTTextActionID(rawValue))
    }

    public static func attachment(_ id: String) -> Self {
        Self(values: [PTRichText.attachmentAttributeKey: id])
    }

    public static func paragraph(_ attributes: PTTextParagraphAttribute...) -> Self {
        paragraph(attributes)
    }

    public static func paragraph(_ attributes: [PTTextParagraphAttribute]) -> Self {
        let paragraph = NSMutableParagraphStyle()
        for attribute in attributes {
            switch attribute {
            case .alignment(let value): paragraph.alignment = value
            case .lineSpacing(let value): paragraph.lineSpacing = value
            case .paragraphSpacing(let value): paragraph.paragraphSpacing = value
            case .firstLineHeadIndent(let value): paragraph.firstLineHeadIndent = value
            case .headIndent(let value): paragraph.headIndent = value
            case .tailIndent(let value): paragraph.tailIndent = value
            case .lineBreakMode(let value): paragraph.lineBreakMode = value
            case .lineBreakStrategy(let value): paragraph.lineBreakStrategy = value
            case .minimumLineHeight(let value): paragraph.minimumLineHeight = value
            case .maximumLineHeight(let value): paragraph.maximumLineHeight = value
            case .baseWritingDirection(let value): paragraph.baseWritingDirection = value
            case .hyphenationFactor(let value): paragraph.hyphenationFactor = value
            }
        }
        return Self(values: [.paragraphStyle: paragraph.copy()])
    }
}

public struct PTTextStyle {
    public let attributes: [PTTextAttribute]

    public init(_ attributes: PTTextAttribute...) {
        self.attributes = attributes
    }

    public init(attributes: [PTTextAttribute]) {
        self.attributes = attributes
    }
}

public struct PTTextRange: Equatable {
    fileprivate let value: Range<Foundation.AttributedString.Index>

    public init(_ value: Range<Foundation.AttributedString.Index>) {
        self.value = value
    }
}

// English: A small value fragment keeps complex interpolation and result-builder composition readable.
// Español: Un fragmento de valor pequeño mantiene legibles la interpolación compleja y el builder.
// 中文：轻量值片段让复杂插值和 Result Builder 组合保持可读。
public struct PTTextFragment: Sendable {
    public let richText: PTRichText

    public init(_ richText: PTRichText) {
        self.richText = richText
    }
}

// English: Lock-protected matcher storage isolates Foundation's reference matchers from Swift 6 shared-state diagnostics.
// Español: El almacenamiento de matchers protegido por bloqueo aísla las referencias de Foundation de los diagnósticos de estado compartido de Swift 6.
// 中文：加锁的匹配器存储隔离 Foundation 引用对象，避免 Swift 6 共享状态诊断。
// English: This compatibility boundary is only for immutable matcher reuse; every cache access is serialized by the lock.
// Español: Este límite de compatibilidad solo reutiliza matchers inmutables; cada acceso a la caché se serializa con el bloqueo.
// 中文：这个兼容边界仅用于复用不可变匹配器；所有缓存访问都通过锁串行化。
private final class PTTextMatcherCache: @unchecked Sendable {
    private let lock = NSLock()
    private let regexCache = NSCache<NSString, NSRegularExpression>()
    private let detectorCache = NSCache<NSNumber, NSDataDetector>()

    init() {
        regexCache.countLimit = 64
        detectorCache.countLimit = 16
    }

    func regex(pattern: String, options: UInt32) -> NSRegularExpression? {
        let key = "\(options):\(pattern)" as NSString
        lock.lock()
        defer { lock.unlock() }

        if let cached = regexCache.object(forKey: key) {
            return cached
        }
        guard let compiled = try? NSRegularExpression(pattern: pattern,
                                                       options: NSRegularExpression.Options(rawValue: UInt(options))) else {
            return nil
        }
        regexCache.setObject(compiled, forKey: key)
        return compiled
    }

    func detector(for types: NSTextCheckingResult.CheckingType) -> NSDataDetector? {
        let key = NSNumber(value: types.rawValue)
        lock.lock()
        defer { lock.unlock() }

        if let cached = detectorCache.object(forKey: key) {
            return cached
        }
        guard let created = try? NSDataDetector(types: types.rawValue) else {
            return nil
        }
        detectorCache.setObject(created, forKey: key)
        return created
    }
}

@resultBuilder
public enum PTRichTextBuilder {
    public static func buildBlock(_ components: PTRichText...) -> PTRichText {
        components.reduce(into: PTRichText(""), +=)
    }

    public static func buildExpression(_ expression: String) -> PTRichText {
        PTRichText(expression)
    }

    public static func buildExpression(_ expression: PTRichText) -> PTRichText {
        expression
    }

    public static func buildExpression(_ expression: PTTextFragment) -> PTRichText {
        expression.richText
    }

    public static func buildOptional(_ component: PTRichText?) -> PTRichText {
        component ?? PTRichText("")
    }

    public static func buildEither(first component: PTRichText) -> PTRichText {
        component
    }

    public static func buildEither(second component: PTRichText) -> PTRichText {
        component
    }

    public static func buildArray(_ components: [PTRichText]) -> PTRichText {
        components.reduce(into: PTRichText(""), +=)
    }
}

public enum PTTextWrapMode {
    case embedding(PTRichText)
    case override(PTRichText)
}

public enum PTTextMatchRule: Sendable, Hashable {
    case range(NSRange)
    case regex(pattern: String, options: UInt32 = 0)
    case custom(String)
    case link
    case date
    case phoneNumber
    case address
    case transitInformation
}

public enum PTTextMatchKind: String, Sendable {
    case range
    case regex
    case custom
    case link
    case date
    case phoneNumber
    case address
    case transitInformation
}

public enum PTTextMatchConflictPolicy: Sendable {
    case firstWins
    case lastWins
    case longestWins
    case priority
    case allowOverlap
}

public struct PTTextMatch: Sendable, Equatable {
    public let range: NSRange
    public let kind: PTTextMatchKind
    public let text: String

    public init(range: NSRange, kind: PTTextMatchKind, text: String) {
        self.range = range
        self.kind = kind
        self.text = text
    }
}

public struct PTTextAttachmentDescriptor: Codable, Hashable, Sendable {
    public enum Kind: Codable, Hashable, Sendable {
        case imageData(Data)
        case file(URL)
        case remote(URL)
        case viewProvider(String)
    }

    public let id: String
    public let kind: Kind
    public let size: CGSize
    public let accessibilityDescription: String?

    public init(id: String = UUID().uuidString,
                kind: Kind,
                size: CGSize,
                accessibilityDescription: String? = nil) {
        self.id = id
        self.kind = kind
        self.size = ptNormalizedAttachmentSize(size)
        self.accessibilityDescription = accessibilityDescription
    }
}

// English: Keep every attachment dimension finite and positive before it reaches TextKit.
// Español: Mantiene cada dimensión del adjunto finita y positiva antes de llegar a TextKit.
// 中文：在进入 TextKit 前确保附件尺寸始终有限且为正数。
private func ptNormalizedAttachmentSize(_ size: CGSize) -> CGSize {
    CGSize(width: size.width.isFinite && size.width > 0 ? size.width : 1,
           height: size.height.isFinite && size.height > 0 ? size.height : 1)
}

// English: The descriptor is a Sendable value; only its view factory executes on MainActor.
// Español: El descriptor es un valor Sendable; solo su fábrica de vistas se ejecuta en MainActor.
// 中文：描述符是 Sendable 值类型，只有 View 工厂在 MainActor 上执行。
public struct PTTextViewAttachmentDescriptor: Sendable {
    public let id: String
    public let size: CGSize
    public let accessibilityDescription: String?
    public let makeView: @MainActor @Sendable () -> UIView

    public init(id: String,
                size: CGSize,
                accessibilityDescription: String? = nil,
                makeView: @escaping @MainActor @Sendable () -> UIView) {
        self.id = id
        self.size = ptNormalizedAttachmentSize(size)
        self.accessibilityDescription = accessibilityDescription
        self.makeView = makeView
    }

    // English: Create a TextKit view provider only when the layout manager requests the attachment view.
    // Español: Crea el proveedor de vista TextKit solo cuando el gestor de layout solicita la vista del adjunto.
    // 中文：仅在 TextKit 布局管理器请求附件视图时创建 View Provider。
    @available(iOS 15.0, *)
    public func makeViewProvider(textAttachment: NSTextAttachment,
                                 parentView: UIView?,
                                 textLayoutManager: NSTextLayoutManager?,
                                 location: NSTextLocation) -> PTTextAttachmentViewProvider {
        PTTextAttachmentViewProvider(descriptor: self,
                                     textAttachment: textAttachment,
                                     parentView: parentView,
                                     textLayoutManager: textLayoutManager,
                                     location: location)
    }
}

// English: Keep custom attachment views lazy and sized by the immutable descriptor.
// Español: Mantiene las vistas de adjuntos personalizadas perezosas y dimensionadas por el descriptor inmutable.
// 中文：让自定义附件视图按需创建，并使用不可变描述符确定尺寸。
@available(iOS 15.0, *)
public final class PTTextAttachmentViewProvider: NSTextAttachmentViewProvider {
    private let descriptor: PTTextViewAttachmentDescriptor

    public init(descriptor: PTTextViewAttachmentDescriptor,
                textAttachment: NSTextAttachment,
                parentView: UIView?,
                textLayoutManager: NSTextLayoutManager?,
                location: NSTextLocation) {
        self.descriptor = descriptor
        super.init(textAttachment: textAttachment,
                   parentView: parentView,
                   textLayoutManager: textLayoutManager,
                   location: location)
        tracksTextAttachmentViewBounds = true
    }

    // English: UIKit invokes this callback on the main thread, but the SDK declaration is nonisolated.
    // Español: UIKit invoca este callback en el hilo principal, aunque la declaración del SDK no está aislada.
    // 中文：UIKit 会在主线程调用此回调，但 SDK 声明本身没有 MainActor 隔离。
    public override func loadView() {
        let descriptor = self.descriptor
        let attachmentView: UIView = MainActor.assumeIsolated {
            let attachmentView = descriptor.makeView()
            attachmentView.frame = CGRect(origin: .zero, size: descriptor.size)
            return attachmentView
        }
        view = attachmentView
    }

    public override func attachmentBounds(for attributes: [NSAttributedString.Key: Any],
                                          location: NSTextLocation,
                                          textContainer: NSTextContainer?,
                                          proposedLineFragment lineFrag: CGRect,
                                          position: CGPoint) -> CGRect {
        CGRect(origin: .zero, size: descriptor.size)
    }
}

public protocol PTTextImageLoader: Sendable {
    func image(for url: URL) async throws -> UIImage
}

public struct PTURLSessionTextImageLoader: PTTextImageLoader, Sendable {
    public init() {}

    public func image(for url: URL) async throws -> UIImage {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        return image
    }
}

// English: Own remote attachment tasks by identifier and discard stale generations on reuse.
// Español: Posee las tareas de adjuntos remotos por identificador y descarta generaciones obsoletas al reutilizar.
// 中文：按标识符管理远程附件任务，并在复用时丢弃过期 generation 的结果。
@MainActor
public final class PTTextAttachmentCoordinator {
    private let loader: any PTTextImageLoader
    private var tasks: [String: Task<Void, Never>] = [:]
    private var generations: [String: UInt64] = [:]

    public init(loader: any PTTextImageLoader = PTURLSessionTextImageLoader()) {
        self.loader = loader
    }

    @discardableResult
    public func loadRemote(_ descriptor: PTTextAttachmentDescriptor,
                           completion: @escaping @MainActor @Sendable (Result<UIImage, Error>) -> Void) -> UInt64 {
        guard case .remote(let url) = descriptor.kind else { return 0 }
        cancel(id: descriptor.id)
        let generation = (generations[descriptor.id] ?? 0) &+ 1
        generations[descriptor.id] = generation
        let identifier = descriptor.id
        let task = Task { @MainActor [weak self, loader, url, identifier, generation] in
            do {
                let image = try await loader.image(for: url)
                guard !Task.isCancelled,
                      let self,
                      self.generations[identifier] == generation else { return }
                self.tasks[identifier] = nil
                completion(.success(image))
            } catch {
                guard !Task.isCancelled,
                      let self,
                      self.generations[identifier] == generation else { return }
                self.tasks[identifier] = nil
                completion(.failure(error))
            }
        }
        tasks[descriptor.id] = task
        return generation
    }

    public func cancel(id: String) {
        tasks[id]?.cancel()
        tasks[id] = nil
        generations[id, default: 0] &+= 1
    }

    public func cancelAll() {
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll(keepingCapacity: false)
        generations.removeAll(keepingCapacity: false)
    }

    deinit {
        tasks.values.forEach { $0.cancel() }
    }
}

public struct PTRichText: Sendable, Equatable, CustomStringConvertible,
                          ExpressibleByStringLiteral, ExpressibleByStringInterpolation {
    fileprivate var storage: Foundation.AttributedString

    private static let matcherCache = PTTextMatcherCache()

    fileprivate static let actionAttributeKey = NSAttributedString.Key("PTools.actionID")
    fileprivate static let attachmentAttributeKey = NSAttributedString.Key("PTools.attachmentID")

    public init(_ text: String) {
        storage = Foundation.AttributedString(text)
    }

    public init(_ attributedString: Foundation.AttributedString) {
        storage = attributedString
    }

    public init(_ attributedString: NSAttributedString) {
        storage = Foundation.AttributedString(attributedString)
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
        storage = Foundation.AttributedString(value)
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
        storage = Foundation.AttributedString(value)
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
        storage = Foundation.AttributedString(value)
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
        NSAttributedString(storage)
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
        storage = Foundation.AttributedString(value)
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
        storage = Foundation.AttributedString(value)
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
        storage = Foundation.AttributedString(value)
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

@MainActor
public final class PTTextActionRegistry {
    private var handlers: [PTTextActionID: (PTTextActionEvent) -> Void] = [:]

    public init() {}

    @discardableResult
    public func register(_ id: PTTextActionID,
                         handler: @escaping (PTTextActionEvent) -> Void) -> PTTextActionToken {
        handlers[id] = handler
        return PTTextActionToken(id: id)
    }

    @discardableResult
    public func register<Owner: AnyObject>(_ id: PTTextActionID,
                                           owner: Owner,
                                           handler: @escaping (Owner, PTTextActionEvent) -> Void) -> PTTextActionToken {
        handlers[id] = { [weak owner] event in
            guard let owner else { return }
            handler(owner, event)
        }
        return PTTextActionToken(id: id)
    }

    public func remove(_ token: PTTextActionToken) {
        handlers.removeValue(forKey: token.id)
    }

    public func removeAll() {
        handlers.removeAll(keepingCapacity: false)
    }

    public func perform(_ event: PTTextActionEvent) {
        handlers[event.actionID]?(event)
    }
}

@MainActor
public final class PTRichTextInteractionController: NSObject, UIGestureRecognizerDelegate {
    private weak var label: UILabel?
    private weak var textView: UITextView?
    private let registry: PTTextActionRegistry
    private let interactionMode: PTTextInteractionMode
    private var richText: PTRichText
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    private lazy var longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    private var highlightedRange: NSRange?

    public init(richText: PTRichText,
                label: UILabel,
                registry: PTTextActionRegistry,
                interactionMode: PTTextInteractionMode = .hybrid) {
        self.richText = richText
        self.label = label
        self.registry = registry
        self.interactionMode = interactionMode
        super.init()
        install(on: label)
    }

    public init(richText: PTRichText,
                textView: UITextView,
                registry: PTTextActionRegistry,
                interactionMode: PTTextInteractionMode = .hybrid) {
        self.richText = richText
        self.textView = textView
        self.registry = registry
        self.interactionMode = interactionMode
        super.init()
        install(on: textView)
    }

    public func update(richText: PTRichText) {
        self.richText = richText
        highlightedRange = nil
    }

    fileprivate func install(on view: UIView) {
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        longPressGesture.cancelsTouchesInView = false
        longPressGesture.delegate = self
        longPressGesture.minimumPressDuration = 0.35
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
        view.addGestureRecognizer(longPressGesture)
    }

    fileprivate func detach() {
        if let label {
            label.removeGestureRecognizer(tapGesture)
            label.removeGestureRecognizer(longPressGesture)
        }
        if let textView {
            textView.removeGestureRecognizer(tapGesture)
            textView.removeGestureRecognizer(longPressGesture)
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard interactionMode != .selectionAndLinks,
              gesture.state == .ended,
              let hit = hit(at: gesture.location(in: gesture.view)) else { return }
        registry.perform(PTTextActionEvent(actionID: hit.id,
                                           range: hit.range,
                                           text: hit.text,
                                           interaction: .tap))
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard interactionMode != .selectionAndLinks,
                  let hit = hit(at: gesture.location(in: gesture.view)) else { return }
            highlightedRange = hit.range
            applyTemporaryHighlight(hit.range)
            registry.perform(PTTextActionEvent(actionID: hit.id,
                                               range: hit.range,
                                               text: hit.text,
                                               interaction: .longPress))
        case .ended, .cancelled, .failed:
            highlightedRange = nil
            clearTemporaryHighlight()
        default:
            break
        }
    }

    private func hit(at point: CGPoint) -> (id: PTTextActionID, range: NSRange, text: String)? {
        let attributedText = richText.value
        guard attributedText.length > 0,
              let index = characterIndex(at: point, attributedText: attributedText),
              let rawID = attributedText.attribute(PTRichText.actionAttributeKey,
                                                    at: index,
                                                    effectiveRange: nil) as? String else {
            return nil
        }
        let id = PTTextActionID(rawID)
        var range = NSRange(location: 0, length: 0)
        _ = attributedText.attribute(PTRichText.actionAttributeKey, at: index, effectiveRange: &range)
        guard range.length > 0 else { return nil }
        return (id, range, attributedText.attributedSubstring(from: range).string)
    }

    private func characterIndex(at point: CGPoint,
                                attributedText: NSAttributedString) -> Int? {
        let storage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let container: NSTextContainer
        let textPoint: CGPoint

        if let label {
            let textRect = label.textRect(forBounds: label.bounds,
                                          limitedToNumberOfLines: label.numberOfLines)
            container = NSTextContainer(size: textRect.size)
            container.maximumNumberOfLines = label.numberOfLines
            container.lineBreakMode = label.lineBreakMode
            textPoint = CGPoint(x: point.x - textRect.minX, y: point.y - textRect.minY)
        } else if let textView {
            container = textView.textContainer
            textPoint = CGPoint(x: point.x - textView.textContainerInset.left,
                                y: point.y - textView.textContainerInset.top)
        } else {
            return nil
        }

        container.lineFragmentPadding = 0
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: container)
        var fraction: CGFloat = 0
        let index = layoutManager.characterIndex(for: textPoint,
                                                 in: container,
                                                 fractionOfDistanceBetweenInsertionPoints: &fraction)
        guard index < attributedText.length else { return nil }
        return index
    }

    private func applyTemporaryHighlight(_ range: NSRange) {
        let value = NSMutableAttributedString(attributedString: richText.value)
        guard range.location >= 0,
              range.length > 0,
              NSMaxRange(range) <= value.length else { return }
        value.addAttribute(.backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.25), range: range)
        label?.attributedText = value
        textView?.attributedText = value
    }

    private func clearTemporaryHighlight() {
        label?.attributedText = richText.value
        textView?.attributedText = richText.value
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        textView != nil
    }
}

// English: Keep the single controller associated with the UIKit host, not in PTRichText storage.
// Español: Mantiene un solo controlador asociado al host UIKit, no dentro del almacenamiento PTRichText.
// 中文：交互控制器只关联在 UIKit 宿主上，不写入 PTRichText 存储。
@MainActor private var ptRichTextInteractionAssociationKey: UInt8 = 0

@MainActor
public enum PTRichTextRenderer {
    public static func apply(_ richText: PTRichText,
                             to label: UILabel,
                             actionRegistry: PTTextActionRegistry? = nil,
                             interactionMode: PTTextInteractionMode = .hybrid) {
        label.attributedText = richText.value
        (objc_getAssociatedObject(label, &ptRichTextInteractionAssociationKey) as? PTRichTextInteractionController)?.detach()
        guard let actionRegistry else {
            objc_setAssociatedObject(label, &ptRichTextInteractionAssociationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        let controller = PTRichTextInteractionController(richText: richText,
                                                         label: label,
                                                         registry: actionRegistry,
                                                         interactionMode: interactionMode)
        objc_setAssociatedObject(label, &ptRichTextInteractionAssociationKey, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public static func apply(_ richText: PTRichText,
                             to textView: UITextView,
                             interactionMode: PTTextInteractionMode = .hybrid,
                             actionRegistry: PTTextActionRegistry? = nil) {
        textView.attributedText = richText.value
        textView.isEditable = false
        textView.isSelectable = interactionMode != .actionsOnly
        textView.isScrollEnabled = true
        (objc_getAssociatedObject(textView, &ptRichTextInteractionAssociationKey) as? PTRichTextInteractionController)?.detach()
        guard let actionRegistry else {
            objc_setAssociatedObject(textView, &ptRichTextInteractionAssociationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        let controller = PTRichTextInteractionController(richText: richText,
                                                         textView: textView,
                                                         registry: actionRegistry,
                                                         interactionMode: interactionMode)
        objc_setAssociatedObject(textView, &ptRichTextInteractionAssociationKey, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

@MainActor
public extension UILabel {
    func pt_apply(richText: PTRichText,
                  actionRegistry: PTTextActionRegistry? = nil,
                  interactionMode: PTTextInteractionMode = .hybrid) {
        PTRichTextRenderer.apply(richText,
                                 to: self,
                                 actionRegistry: actionRegistry,
                                 interactionMode: interactionMode)
    }
}

@MainActor
public extension UITextView {
    func pt_apply(richText: PTRichText,
                  interactionMode: PTTextInteractionMode = .hybrid,
                  actionRegistry: PTTextActionRegistry? = nil) {
        PTRichTextRenderer.apply(richText,
                                 to: self,
                                 interactionMode: interactionMode,
                                 actionRegistry: actionRegistry)
    }
}
