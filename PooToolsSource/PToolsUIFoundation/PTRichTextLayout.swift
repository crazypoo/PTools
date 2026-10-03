// English: UIKit rendering, interaction and host layout integration for PTRichText.
// Español: Renderizado UIKit, interacción e integración de layout del host para PTRichText.
// 中文：PTRichText 的 UIKit 渲染、交互和宿主布局集成。

import Foundation
import UIKit
import ObjectiveC

// English: Offer additive value builders while preserving the existing interpolation-first DSL.
// Español: Ofrece constructores de valor aditivos y conserva el DSL existente basado en interpolación.
// 中文：增加值类型构建入口，同时保留现有以插值为主的 DSL。
@MainActor
public extension PTRichText {
    static func image(source: Any,
                      configuration: PTRichTextImageConfiguration = .init()) -> Self {
        PTRichText(string: "\u{FFFC}", with: [.image(source: source, configuration: configuration)])
    }

    static func video(source: Any,
                      configuration: PTRichTextVideoConfiguration = .init()) -> Self {
        PTRichText(string: "\u{FFFC}", with: [.video(source: source, configuration: configuration)])
    }

    func appendingImage(source: Any,
                        configuration: PTRichTextImageConfiguration = .init()) -> Self {
        self + .image(source: source, configuration: configuration)
    }

    func appendingVideo(source: Any,
                        configuration: PTRichTextVideoConfiguration = .init()) -> Self {
        self + .video(source: source, configuration: configuration)
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
    private let registry: PTTextActionRegistry?
    private let interactionMode: PTTextInteractionMode
    private let onInteraction: PTRichTextInteractionHandler?
    private var richText: PTRichText
    private lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    private lazy var longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
    private var highlightedRange: NSRange?

    public init(richText: PTRichText,
                label: UILabel,
                registry: PTTextActionRegistry,
                interactionMode: PTTextInteractionMode = .hybrid,
                onInteraction: PTRichTextInteractionHandler? = nil) {
        self.richText = richText
        self.label = label
        self.registry = registry
        self.interactionMode = interactionMode
        self.onInteraction = onInteraction
        super.init()
        install(on: label)
    }

    public init(richText: PTRichText,
                label: UILabel,
                interactionMode: PTTextInteractionMode = .hybrid,
                onInteraction: PTRichTextInteractionHandler? = nil) {
        self.richText = richText
        self.label = label
        self.registry = nil
        self.interactionMode = interactionMode
        self.onInteraction = onInteraction
        super.init()
        install(on: label)
    }

    public init(richText: PTRichText,
                textView: UITextView,
                registry: PTTextActionRegistry,
                interactionMode: PTTextInteractionMode = .hybrid,
                onInteraction: PTRichTextInteractionHandler? = nil) {
        self.richText = richText
        self.textView = textView
        self.registry = registry
        self.interactionMode = interactionMode
        self.onInteraction = onInteraction
        super.init()
        install(on: textView)
    }

    public init(richText: PTRichText,
                textView: UITextView,
                interactionMode: PTTextInteractionMode = .hybrid,
                onInteraction: PTRichTextInteractionHandler? = nil) {
        self.richText = richText
        self.textView = textView
        self.registry = nil
        self.interactionMode = interactionMode
        self.onInteraction = onInteraction
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
              let point = gesture.view.map({ gesture.location(in: $0) }) else { return }
        if let interaction = interaction(at: point) {
            onInteraction?(interaction)
            if case .media = interaction { return }
        }
        guard let hit = hit(at: point),
              let registry else { return }
        registry.perform(PTTextActionEvent(actionID: hit.id,
                                           range: hit.range,
                                           text: hit.text,
                                           interaction: .tap))
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard interactionMode != .selectionAndLinks,
                  let point = gesture.view.map({ gesture.location(in: $0) }),
                  let hit = hit(at: point),
                  let registry else { return }
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

    private func interaction(at point: CGPoint) -> PTRichTextInteraction? {
        let attributedText = richText.value
        guard attributedText.length > 0,
              let index = characterIndex(at: point, attributedText: attributedText) else {
            return nil
        }
        if let attachment = attributedText.attribute(.attachment,
                                                      at: index,
                                                      effectiveRange: nil) as? PTRichTextMediaTextAttachment {
            return .media(attachment.media.kind == .image
                          ? .image(id: attachment.media.id)
                          : .video(id: attachment.media.id))
        }
        if let attachment = attributedText.attribute(.attachment,
                                                      at: index,
                                                      effectiveRange: nil) as? PTRemoteImageTextAttachment {
            return .media(.image(id: attachment.mediaID))
        }
        if let url = attributedText.attribute(.link, at: index, effectiveRange: nil) as? URL {
            return .link(url)
        }
        return nil
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
@MainActor var ptRichTextInteractionAssociationKey: UInt8 = 0
@MainActor var ptRichTextRemoteImageAssociationKey: UInt8 = 0
@MainActor var ptRichTextMediaAssociationKey: UInt8 = 0

// English: Resolve remote attachments after the placeholder has been rendered, with reuse-safe cancellation.
// Español: Resuelve los adjuntos remotos después de mostrar el marcador y cancela de forma segura al reutilizar.
// 中文：先渲染占位图，再异步解析远程附件，并在复用时安全取消任务。
@MainActor
private final class PTRichTextRemoteImageController: NSObject {
    private weak var label: UILabel?
    private weak var textView: UITextView?
    private let richText: PTRichText
    private let coordinator: PTTextAttachmentCoordinator

    init(richText: PTRichText,
         label: UILabel? = nil,
         textView: UITextView? = nil,
         coordinator: PTTextAttachmentCoordinator) {
        self.richText = richText
        self.label = label
        self.textView = textView
        self.coordinator = coordinator
        super.init()
    }

    func start() {
        var identifiers = Set<String>()
        richText.value.enumerateAttribute(.attachment,
                                          in: NSRange(location: 0, length: richText.value.length),
                                          options: []) { value, _, _ in
            guard let attachment = value as? PTRemoteImageTextAttachment,
                  identifiers.insert(attachment.identifier).inserted else {
                return
            }

            let descriptor = PTTextAttachmentDescriptor(id: attachment.identifier,
                                                        kind: .remote(attachment.remoteURL),
                                                        size: attachment.attachmentSize)
            coordinator.loadRemote(descriptor) { [weak self] result in
                guard let self else { return }
                guard case .success(let image) = result else { return }
                self.apply(image, for: attachment.identifier)
            }
        }
    }

    func cancel() {
        coordinator.cancelAll()
    }

    private func apply(_ image: UIImage, for identifier: String) {
        let updated = NSMutableAttributedString(attributedString: richText.value)
        let range = NSRange(location: 0, length: updated.length)
        updated.enumerateAttribute(.attachment, in: range, options: []) { value, subrange, _ in
            guard let attachment = value as? PTRemoteImageTextAttachment,
                  attachment.identifier == identifier else {
                return
            }
            updated.addAttribute(.attachment,
                                 value: attachment.resolvedAttachment(with: image),
                                 range: subrange)
        }

        label?.attributedText = updated
        textView?.attributedText = updated
    }
}


@MainActor
public enum PTRichTextRenderer {
    public static func apply(_ richText: PTRichText,
                             to label: UILabel,
                             actionRegistry: PTTextActionRegistry? = nil,
                             interactionMode: PTTextInteractionMode = .hybrid,
                             attachmentCoordinator: PTTextAttachmentCoordinator? = nil,
                             mediaLoader: PTRichTextMediaLoader? = nil,
                             onInteraction: PTRichTextInteractionHandler? = nil) {
        label.attributedText = richText.value
        (objc_getAssociatedObject(label, &ptRichTextRemoteImageAssociationKey) as? PTRichTextRemoteImageController)?.cancel()
        objc_setAssociatedObject(label,
                                 &ptRichTextRemoteImageAssociationKey,
                                 nil,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        (objc_getAssociatedObject(label, &ptRichTextMediaAssociationKey) as? PTRichTextMediaController)?.cancel()
        objc_setAssociatedObject(label,
                                 &ptRichTextMediaAssociationKey,
                                 nil,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if let attachmentCoordinator {
            let controller = PTRichTextRemoteImageController(richText: richText,
                                                              label: label,
                                                              coordinator: attachmentCoordinator)
            objc_setAssociatedObject(label,
                                     &ptRichTextRemoteImageAssociationKey,
                                     controller,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            controller.start()
        }
        if let mediaLoader {
            let controller = PTRichTextMediaController(richText: richText,
                                                        label: label,
                                                        loader: mediaLoader)
            objc_setAssociatedObject(label,
                                     &ptRichTextMediaAssociationKey,
                                     controller,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            controller.start()
        }
        (objc_getAssociatedObject(label, &ptRichTextInteractionAssociationKey) as? PTRichTextInteractionController)?.detach()
        guard actionRegistry != nil || onInteraction != nil else {
            objc_setAssociatedObject(label, &ptRichTextInteractionAssociationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        let controller: PTRichTextInteractionController
        if let actionRegistry {
            controller = PTRichTextInteractionController(richText: richText,
                                                         label: label,
                                                         registry: actionRegistry,
                                                         interactionMode: interactionMode,
                                                         onInteraction: onInteraction)
        } else {
            controller = PTRichTextInteractionController(richText: richText,
                                                         label: label,
                                                         interactionMode: interactionMode,
                                                         onInteraction: onInteraction)
        }
        objc_setAssociatedObject(label, &ptRichTextInteractionAssociationKey, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    public static func apply(_ richText: PTRichText,
                             to textView: UITextView,
                             interactionMode: PTTextInteractionMode = .hybrid,
                             actionRegistry: PTTextActionRegistry? = nil,
                             attachmentCoordinator: PTTextAttachmentCoordinator? = nil,
                             mediaLoader: PTRichTextMediaLoader? = nil,
                             onInteraction: PTRichTextInteractionHandler? = nil) {
        textView.attributedText = richText.value
        textView.isEditable = false
        textView.isSelectable = interactionMode != .actionsOnly
        textView.isScrollEnabled = true
        (objc_getAssociatedObject(textView, &ptRichTextRemoteImageAssociationKey) as? PTRichTextRemoteImageController)?.cancel()
        objc_setAssociatedObject(textView,
                                 &ptRichTextRemoteImageAssociationKey,
                                 nil,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        (objc_getAssociatedObject(textView, &ptRichTextMediaAssociationKey) as? PTRichTextMediaController)?.cancel()
        objc_setAssociatedObject(textView,
                                 &ptRichTextMediaAssociationKey,
                                 nil,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if let attachmentCoordinator {
            let controller = PTRichTextRemoteImageController(richText: richText,
                                                              textView: textView,
                                                              coordinator: attachmentCoordinator)
            objc_setAssociatedObject(textView,
                                     &ptRichTextRemoteImageAssociationKey,
                                     controller,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            controller.start()
        }
        if let mediaLoader {
            let controller = PTRichTextMediaController(richText: richText,
                                                        textView: textView,
                                                        loader: mediaLoader)
            objc_setAssociatedObject(textView,
                                     &ptRichTextMediaAssociationKey,
                                     controller,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            controller.start()
        }
        (objc_getAssociatedObject(textView, &ptRichTextInteractionAssociationKey) as? PTRichTextInteractionController)?.detach()
        guard actionRegistry != nil || onInteraction != nil else {
            objc_setAssociatedObject(textView, &ptRichTextInteractionAssociationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        let controller: PTRichTextInteractionController
        if let actionRegistry {
            controller = PTRichTextInteractionController(richText: richText,
                                                         textView: textView,
                                                         registry: actionRegistry,
                                                         interactionMode: interactionMode,
                                                         onInteraction: onInteraction)
        } else {
            controller = PTRichTextInteractionController(richText: richText,
                                                         textView: textView,
                                                         interactionMode: interactionMode,
                                                         onInteraction: onInteraction)
        }
        objc_setAssociatedObject(textView, &ptRichTextInteractionAssociationKey, controller, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

@MainActor
public extension UILabel {
    func pt_apply(richText: PTRichText,
                  actionRegistry: PTTextActionRegistry? = nil,
                  interactionMode: PTTextInteractionMode = .hybrid,
                  attachmentCoordinator: PTTextAttachmentCoordinator? = nil,
                  mediaLoader: PTRichTextMediaLoader? = nil,
                  onInteraction: PTRichTextInteractionHandler? = nil) {
        PTRichTextRenderer.apply(richText,
                                 to: self,
                                 actionRegistry: actionRegistry,
                                 interactionMode: interactionMode,
                                 attachmentCoordinator: attachmentCoordinator,
                                 mediaLoader: mediaLoader,
                                 onInteraction: onInteraction)
    }
}

@MainActor
public extension UITextView {
    func pt_apply(richText: PTRichText,
                  interactionMode: PTTextInteractionMode = .hybrid,
                  actionRegistry: PTTextActionRegistry? = nil,
                  attachmentCoordinator: PTTextAttachmentCoordinator? = nil,
                  mediaLoader: PTRichTextMediaLoader? = nil,
                  onInteraction: PTRichTextInteractionHandler? = nil) {
        PTRichTextRenderer.apply(richText,
                                 to: self,
                                 interactionMode: interactionMode,
                                 actionRegistry: actionRegistry,
                                 attachmentCoordinator: attachmentCoordinator,
                                 mediaLoader: mediaLoader,
                                 onInteraction: onInteraction)
    }
}
