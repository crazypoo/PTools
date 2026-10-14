//
//  PTRichTextLabelRendering.swift
//  PToolsUIFoundation
//
// English: Prepare rich-text attachments for stable UILabel and UITextView layout.
// Español: Prepara los adjuntos de texto enriquecido para un layout estable en UILabel y UITextView.
// 中文：为 UILabel 和 UITextView 准备稳定的富文本附件布局。
//

import Foundation
import UIKit

// English: Keep attachment-only baseline normalization at the UIKit boundary so the value model keeps its semantics.
// Español: Mantiene la normalización de línea base solo en el límite UIKit para conservar la semántica del modelo.
// 中文：只在 UIKit 边界规整附件基线，保留值模型中的语义属性。
@MainActor
internal enum PTRichTextLabelRendering {
    private static let preparedAttachmentKey = NSAttributedString.Key("PTools.richTextPreparedAttachment")

    static func prepare(_ attributedText: NSAttributedString) -> NSAttributedString {
        guard attributedText.length > 0 else { return attributedText }

        var replacements: [(range: NSRange, attachment: NSTextAttachment, offset: CGFloat)] = []
        let fullRange = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.attachment, in: fullRange, options: []) { value, range, _ in
            guard let attachment = value as? NSTextAttachment,
                  attributedText.attribute(preparedAttachmentKey,
                                           at: range.location,
                                           effectiveRange: nil) == nil,
                  let offset = baselineOffset(in: attributedText, at: range.location),
                  offset != 0 else {
                return
            }
            replacements.append((range, copy(of: attachment), offset))
        }

        guard !replacements.isEmpty else { return attributedText }
        let prepared = NSMutableAttributedString(attributedString: attributedText)
        for replacement in replacements {
            var bounds = replacement.attachment.bounds
            bounds.origin.y += replacement.offset
            replacement.attachment.bounds = bounds
            prepared.addAttribute(.attachment,
                                  value: replacement.attachment,
                                  range: replacement.range)
            prepared.removeAttribute(.baselineOffset, range: replacement.range)
            prepared.addAttribute(preparedAttachmentKey, value: true, range: replacement.range)
        }
        return prepared
    }

    static func apply(_ attributedText: NSAttributedString, to label: UILabel) {
        label.attributedText = prepare(attributedText)
    }

    static func apply(_ attributedText: NSAttributedString, to textView: UITextView) {
        textView.attributedText = prepare(attributedText)
    }

    #if DEBUG
    // English: Keep diagnostics opt-in so normal rendering does not enumerate every text run.
    // Español: Mantiene los diagnósticos opcionales para no recorrer cada run durante el render normal.
    // 中文：诊断功能只在 DEBUG 显式调用，正常渲染不遍历所有文本 run。
    static func diagnosticReport(for label: UILabel) -> String {
        let displayed = label.attributedText ?? NSAttributedString(string: label.text ?? "")
        var lines = [
            "bounds=\(NSCoder.string(for: label.bounds))",
            "numberOfLines=\(label.numberOfLines)",
            "lineBreakMode=\(label.lineBreakMode.rawValue)",
            "preferredMaxLayoutWidth=\(label.preferredMaxLayoutWidth)",
            "intrinsicContentSize=\(NSCoder.string(for: label.intrinsicContentSize))",
            "sizeThatFits=\(NSCoder.string(for: label.sizeThatFits(label.bounds.size)))",
            "adjustsFontSizeToFitWidth=\(label.adjustsFontSizeToFitWidth)",
            "textLength=\(displayed.length)"
        ]
        displayed.enumerateAttributes(in: NSRange(location: 0, length: displayed.length), options: []) { attributes, range, _ in
            let font = attributes[.font] as? UIFont
            let paragraph = attributes[.paragraphStyle] as? NSParagraphStyle
            let attachment = attributes[.attachment] as? NSTextAttachment
            let action = attributes[PTRichText.actionAttributeKey] as? String ?? "nil"
            let baseline = (attributes[.baselineOffset] as? NSNumber)?.doubleValue ?? 0
            lines.append("run=\(NSStringFromRange(range)) font=\(font?.fontName ?? "nil")/\(font?.pointSize ?? 0) paragraph=\(paragraph?.lineBreakMode.rawValue ?? -1)/\(paragraph?.lineSpacing ?? 0) baseline=\(baseline) attachment=\(attachment.map { NSCoder.string(for: $0.bounds) } ?? "nil") action=\(action)")
        }
        return lines.joined(separator: "\n")
    }
    #endif

    private static func baselineOffset(in attributedText: NSAttributedString, at index: Int) -> CGFloat? {
        if let value = attributedText.attribute(.baselineOffset, at: index, effectiveRange: nil) as? CGFloat {
            return value.isFinite ? value : nil
        }
        if let value = attributedText.attribute(.baselineOffset, at: index, effectiveRange: nil) as? NSNumber {
            let offset = CGFloat(value.doubleValue)
            return offset.isFinite ? offset : nil
        }
        return nil
    }

    private static func copy(of attachment: NSTextAttachment) -> NSTextAttachment {
        if let attachment = attachment as? PTRichTextMediaTextAttachment {
            return attachment.renderingCopy()
        }
        if let attachment = attachment as? PTRemoteImageTextAttachment {
            return attachment.renderingCopy()
        }
        let copy = NSTextAttachment(data: attachment.contents, ofType: attachment.fileType)
        copy.image = attachment.image
        copy.bounds = attachment.bounds
        return copy
    }
}

#if DEBUG
// English: Expose the audit report only to debug consumers without adding release overhead.
// Español: Expone el informe solo a consumidores de depuración sin añadir coste en Release.
// 中文：仅向 Debug 使用方暴露审计报告，不增加 Release 性能开销。
@MainActor
public extension UILabel {
    func pt_richTextLayoutDiagnosticReport() -> String {
        PTRichTextLabelRendering.diagnosticReport(for: self)
    }
}
#endif
