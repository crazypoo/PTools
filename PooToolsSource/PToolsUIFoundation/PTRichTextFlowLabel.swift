// English: UILabel-compatible opt-in host for fragment-level rich-text layout.
// Español: Host compatible con UILabel para el layout opt-in de fragmentos de texto enriquecido.
// 中文：兼容 UILabel 的显式片段级富文本布局宿主。

import Foundation
import UIKit

@MainActor
public final class PTRichTextFlowLabel: UILabel {
    public private(set) var richText: PTRichText?
    public private(set) var flowLayoutResult: PTTextFlowLayoutResult?

    var flowInteractionController: PTRichTextFlowInteractionController?

    public override var numberOfLines: Int {
        didSet { invalidateFlowLayout() }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateFlowLayoutIfNeeded()
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let richText, richText.containsFragmentLayout else {
            return super.sizeThatFits(size)
        }
        let width = max(0, size.width.isFinite ? size.width : 0)
        guard width > 0 else { return super.sizeThatFits(size) }
        let result = PTRichTextFlowLayoutEngine.layout(richText,
                                                       width: width,
                                                       hostNumberOfLines: numberOfLines)
        return CGSize(width: width,
                      height: max(0, result.renderedText.boundingRect(with: CGSize(width: width,
                                                                                     height: .greatestFiniteMagnitude),
                                                                       options: [.usesLineFragmentOrigin,
                                                                                 .usesFontLeading],
                                                                       context: nil).height))
    }

    public override var intrinsicContentSize: CGSize {
        guard let richText, richText.containsFragmentLayout else {
            return super.intrinsicContentSize
        }
        let width = bounds.width > 0 ? bounds.width : preferredMaxLayoutWidth
        guard width > 0 else { return super.intrinsicContentSize }
        let fitted = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: fitted.height)
    }

    func apply(richText: PTRichText,
               actionRegistry: PTTextActionRegistry?,
               interactionMode: PTTextInteractionMode,
               onInteraction: PTRichTextInteractionHandler?) {
        self.richText = richText
        flowLayoutResult = nil
        if richText.containsFragmentLayout {
            updateFlowLayoutIfNeeded(force: true)
            flowInteractionController?.detach()
            if actionRegistry != nil || onInteraction != nil {
                flowInteractionController = PTRichTextFlowInteractionController(richText: richText,
                                                                                  label: self,
                                                                                  registry: actionRegistry,
                                                                                  interactionMode: interactionMode,
                                                                                  onInteraction: onInteraction)
            } else {
                flowInteractionController = nil
            }
        } else {
            super.attributedText = PTRichTextLabelRendering.prepare(richText.value)
            flowInteractionController?.detach()
            flowInteractionController = nil
        }
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    func applyResolvedAttributedText(_ attributedText: NSAttributedString) {
        apply(richText: PTRichText(attributedText),
              actionRegistry: flowInteractionController?.registry,
              interactionMode: flowInteractionController?.interactionMode ?? .hybrid,
              onInteraction: flowInteractionController?.onInteraction)
    }

    func flowHit(at point: CGPoint) -> (id: PTTextActionID,
                                         displayedRange: NSRange,
                                         sourceRange: NSRange,
                                         text: String)? {
        guard let richText,
              let displayed = attributedText,
              displayed.length > 0,
              let index = characterIndex(at: point, attributedText: displayed),
              let rawID = displayed.attribute(PTRichText.actionAttributeKey,
                                              at: index,
                                              effectiveRange: nil) as? String else {
            return nil
        }
        var displayedRange = NSRange(location: 0, length: 0)
        _ = displayed.attribute(PTRichText.actionAttributeKey,
                                at: index,
                                effectiveRange: &displayedRange)
        guard displayedRange.length > 0,
              let sourceRange = flowLayoutResult?.sourceRange(for: displayedRange) else {
            return nil
        }
        var fullActionRange = sourceRange
        if let sourceIndex = richText.value.attribute(PTRichText.actionAttributeKey,
                                                      at: sourceRange.location,
                                                      effectiveRange: &fullActionRange) as? String,
           sourceIndex != rawID {
            fullActionRange = sourceRange
        }
        let text = richText.value.attributedSubstring(from: fullActionRange).string
        return (PTTextActionID(rawID), displayedRange, fullActionRange, text)
    }

    func flowInteraction(at point: CGPoint) -> PTRichTextInteraction? {
        guard let richText,
              let displayed = attributedText,
              let index = characterIndex(at: point, attributedText: displayed),
              let sourceRange = flowLayoutResult?.sourceRange(for: NSRange(location: index, length: 1)) else {
            return nil
        }
        if let attachment = richText.value.attribute(.attachment,
                                                      at: sourceRange.location,
                                                      effectiveRange: nil) as? PTRichTextMediaTextAttachment {
            return .media(attachment.media.kind == .image
                          ? .image(id: attachment.media.id)
                          : .video(id: attachment.media.id))
        }
        if let attachment = richText.value.attribute(.attachment,
                                                      at: sourceRange.location,
                                                      effectiveRange: nil) as? PTRemoteImageTextAttachment {
            return .media(.image(id: attachment.mediaID))
        }
        if let url = richText.value.attribute(.link,
                                              at: sourceRange.location,
                                              effectiveRange: nil) as? URL {
            return .link(url)
        }
        return nil
    }

    #if DEBUG
    public func pt_richTextFlowDiagnosticReport() -> String {
        guard let richText, let flowLayoutResult else {
            return "fragmentFlow=fallback"
        }
        return flowLayoutResult.diagnosticReport(for: richText)
    }
    #endif

    private var lastFlowWidth: CGFloat = -1
    private var lastFlowText: PTRichText?

    private func invalidateFlowLayout() {
        lastFlowWidth = -1
        setNeedsLayout()
        invalidateIntrinsicContentSize()
    }

    private func updateFlowLayoutIfNeeded(force: Bool = false) {
        guard let richText, richText.containsFragmentLayout else { return }
        let width = bounds.width
        guard width > 0 else { return }
        guard force || width != lastFlowWidth || lastFlowText != richText else { return }
        let result = PTRichTextFlowLayoutEngine.layout(richText,
                                                       width: width,
                                                       hostNumberOfLines: numberOfLines)
        flowLayoutResult = result
        super.attributedText = PTRichTextLabelRendering.prepare(result.renderedText)
        lastFlowWidth = width
        lastFlowText = richText
    }

    private func characterIndex(at point: CGPoint,
                                attributedText: NSAttributedString) -> Int? {
        let textRect = textRect(forBounds: bounds,
                                limitedToNumberOfLines: numberOfLines)
        let storage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let container = NSTextContainer(size: textRect.size)
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = numberOfLines
        container.lineBreakMode = lineBreakMode
        layoutManager.addTextContainer(container)
        storage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: container)
        var fraction: CGFloat = 0
        let textPoint = CGPoint(x: point.x - textRect.minX, y: point.y - textRect.minY)
        let index = layoutManager.characterIndex(for: textPoint,
                                                 in: container,
                                                 fractionOfDistanceBetweenInsertionPoints: &fraction)
        return index < attributedText.length ? index : nil
    }
}
