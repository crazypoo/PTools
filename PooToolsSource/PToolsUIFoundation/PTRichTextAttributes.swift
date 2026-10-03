// English: Typed rich-text styles, attributes and ranges live outside the facade.
// Español: Los estilos, atributos y rangos tipados viven fuera de la fachada.
// 中文：将富文本类型化样式、属性和范围从门面类型中拆出。

import Foundation
import UIKit

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
    let values: [NSAttributedString.Key: Any]

    init(values: [NSAttributedString.Key: Any]) {
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

    // English: Accept the same dynamic image sources as the canonical Core loader at the UI boundary.
    // Español: Acepta las mismas fuentes dinámicas que el cargador canónico de Core en el límite de UI.
    // 中文：在 UI 边界接受与 Core 统一加载器相同的动态图片来源。
    @MainActor
    public static func image(source: Any,
                             configuration: PTRichTextImageConfiguration = .init()) -> Self {
        let media = PTRichTextMediaAttachment(kind: .image,
                                               source: source,
                                               displayConfiguration: configuration.display,
                                               failureImage: configuration.failureImage,
                                               accessibilityLabel: configuration.accessibilityLabel)
        let attachment = PTRichTextMediaTextAttachment(media: media,
                                                        image: configuration.placeholder ?? PTRichTextMediaPlaceholder.image(video: false),
                                                        size: configuration.display.placeholderSize())
        return Self(values: [.attachment: attachment])
    }

    // English: Keep the convenient URL syntax while rendering the placeholder synchronously.
    // Español: Conserva la sintaxis cómoda con URL y muestra el marcador de posición de forma síncrona.
    // 中文：保留便捷的 URL 写法，并同步显示占位图。
    public static func image(_ url: URL,
                             _ style: PTTextAttachmentStyle,
                             placeholder: UIImage? = nil,
                             id: String? = nil) -> Self {
        remoteImage(url, style, placeholder: placeholder, id: id)
    }

    // English: Describe a remote image without starting network work while building the value.
    // Español: Describe una imagen remota sin iniciar trabajo de red al construir el valor.
    // 中文：描述远程图片，但在创建富文本值时不启动网络任务。
    public static func remoteImage(_ url: URL,
                                   _ style: PTTextAttachmentStyle,
                                   placeholder: UIImage? = nil,
                                   id: String? = nil) -> Self {
        let size: CGSize
        switch style {
        case .custom(let value):
            size = ptNormalizedAttachmentSize(value)
        }
        let identifier = id ?? "remote:\(url.absoluteString):\(size.width):\(size.height)"
        let attachment = PTRemoteImageTextAttachment(identifier: identifier,
                                                      url: url,
                                                      size: size,
                                                      placeholder: placeholder)
        return Self(values: [.attachment: attachment])
    }

    // English: Describe a video poster without creating AVPlayer or downloading media during value construction.
    // Español: Describe un póster de vídeo sin crear AVPlayer ni descargar medios al construir el valor.
    // 中文：描述视频封面，创建富文本值时不创建 AVPlayer，也不下载媒体。
    @MainActor
    public static func video(source: Any,
                             configuration: PTRichTextVideoConfiguration = .init()) -> Self {
        let media = PTRichTextMediaAttachment(kind: .video,
                                               source: source,
                                               posterSource: configuration.posterSource,
                                               displayConfiguration: configuration.display,
                                               failureImage: configuration.failureImage,
                                               videoConfiguration: configuration,
                                               accessibilityLabel: configuration.accessibilityLabel)
        let placeholder = configuration.placeholder ?? PTRichTextMediaPlaceholder.image(video: true)
        let attachment = PTRichTextMediaTextAttachment(media: media,
                                                        image: placeholder,
                                                        size: configuration.display.placeholderSize(fallback: CGSize(width: 160, height: 90)))
        return Self(values: [.attachment: attachment])
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
    let value: Range<Foundation.AttributedString.Index>

    public init(_ value: Range<Foundation.AttributedString.Index>) {
        self.value = value
    }
}
