// English: Reuse the existing action registry while mapping FlowLabel glyphs back to full source ranges.
// Español: Reutiliza el registro de acciones y mapea los glyphs del FlowLabel a rangos completos de origen.
// 中文：复用现有 Action Registry，并将 FlowLabel 字形映射回完整原文范围。

import Foundation
import UIKit

@MainActor
final class PTRichTextFlowInteractionController: NSObject, UIGestureRecognizerDelegate {
    weak var label: PTRichTextFlowLabel?
    let registry: PTTextActionRegistry?
    let interactionMode: PTTextInteractionMode
    let onInteraction: PTRichTextInteractionHandler?
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    private lazy var longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    private var highlightedRange: NSRange?
    private var savedHighlightBackgrounds: [(range: NSRange, value: Any)] = []

    init(richText _: PTRichText,
         label: PTRichTextFlowLabel,
         registry: PTTextActionRegistry?,
         interactionMode: PTTextInteractionMode,
         onInteraction: PTRichTextInteractionHandler?) {
        self.label = label
        self.registry = registry
        self.interactionMode = interactionMode
        self.onInteraction = onInteraction
        super.init()
        tapGesture.cancelsTouchesInView = false
        longPressGesture.cancelsTouchesInView = false
        longPressGesture.minimumPressDuration = 0.35
        tapGesture.delegate = self
        longPressGesture.delegate = self
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(tapGesture)
        label.addGestureRecognizer(longPressGesture)
    }

    func detach() {
        label?.removeGestureRecognizer(tapGesture)
        label?.removeGestureRecognizer(longPressGesture)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard interactionMode != .selectionAndLinks,
              gesture.state == .ended,
              let label,
              let point = gesture.view.map({ gesture.location(in: $0) }) else { return }
        if let interaction = label.flowInteraction(at: point) {
            onInteraction?(interaction)
            if case .media = interaction { return }
        }
        guard let hit = label.flowHit(at: point), let registry else { return }
        registry.perform(PTTextActionEvent(actionID: hit.id,
                                           range: hit.sourceRange,
                                           text: hit.text,
                                           interaction: .tap))
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let label else { return }
        switch gesture.state {
        case .began:
            guard interactionMode != .selectionAndLinks,
                  let point = gesture.view.map({ gesture.location(in: $0) }),
                  let hit = label.flowHit(at: point) else { return }
            highlightedRange = hit.displayedRange
            let value = NSMutableAttributedString(attributedString: label.attributedText ?? NSAttributedString())
            value.enumerateAttribute(.backgroundColor,
                                     in: hit.displayedRange,
                                     options: []) { background, range, _ in
                if let background {
                    savedHighlightBackgrounds.append((range, background))
                }
            }
            value.addAttribute(.backgroundColor,
                               value: UIColor.systemYellow.withAlphaComponent(0.25),
                               range: hit.displayedRange)
            label.applyResolvedAttributedText(value)
            registry?.perform(PTTextActionEvent(actionID: hit.id,
                                                range: hit.sourceRange,
                                                text: hit.text,
                                                interaction: .longPress))
        case .ended, .cancelled, .failed:
            guard let highlightedRange,
                  let current = label.attributedText else {
                savedHighlightBackgrounds.removeAll(keepingCapacity: false)
                self.highlightedRange = nil
                return
            }
            let value = NSMutableAttributedString(attributedString: current)
            value.removeAttribute(.backgroundColor, range: highlightedRange)
            for saved in savedHighlightBackgrounds {
                value.addAttribute(.backgroundColor, value: saved.value, range: saved.range)
            }
            label.applyResolvedAttributedText(value)
            savedHighlightBackgrounds.removeAll(keepingCapacity: false)
            self.highlightedRange = nil
        default:
            break
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }
}
