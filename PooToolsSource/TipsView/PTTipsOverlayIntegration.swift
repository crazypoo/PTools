// English: Lightweight Tips presentation that reuses OverlayCore anchors and geometry.
// Español: Presentación ligera de Tips que reutiliza anclajes y geometría de OverlayCore.
// 中文：轻量 Tips 展示复用 OverlayCore 的锚点和几何计算。

import UIKit
#if canImport(PToolsOverlay)
import PToolsOverlay
#endif

@MainActor
public extension PTTipsView {
    @discardableResult
    static func show(_ text: String,
                     from anchorView: UIView,
                     duration: TimeInterval = 3,
                     screenEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)) -> PTOverlayHandle? {
        guard let window = anchorView.window,
              let host = PTOverlayHost(context: .window(window), mode: .attached, layer: .tips),
              let resolved = resolvedAnchor(anchorView) else {
            return nil
        }

        let available = PTScreenCollisionResolver.availableBounds(for: window, edgeInsets: screenEdgeInsets)
        let maxWidth = min(280, available.width - 24)
        let estimatedHeight = NSString(string: text).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize)],
            context: nil
        ).height + 28
        let geometry = PTPopoverPositioningEngine.resolve(anchorRect: resolved.rect,
                                                          contentSize: CGSize(width: maxWidth, height: estimatedHeight),
                                                          availableBounds: available,
                                                          preferredPlacement: .automatic,
                                                          arrow: PTArrowAppearance(fillColor: .red))
        let tip = PTTipsView(frame: .zero)
        tip.constrainInContainerView = true
        tip.edgeMargin = screenEdgeInsets.left
        tip.bubbleColor = .red
        tip.shouldDismissOnTapOutside = true
        let direction = popTipDirection(for: geometry.placement)
        let overlayHandle = PTOverlayHandle(id: PTOverlayID())
        overlayHandle.setActions(dismiss: { [weak host, weak tip] in
            tip?.hide()
            host?.detach()
        })
        overlayHandle.setState(.preparing)
        tip.dismissHandler = { [weak host, weak overlayHandle] _ in
            host?.detach()
            overlayHandle?.setState(.dismissed)
            overlayHandle?.invalidate()
        }
        host.containerView.hitTestPolicy = .custom
        host.containerView.customHitTest = { [weak host, weak tip, weak overlayHandle] point, _ in
            guard let host, let tip else { return nil }
            let tipPoint = tip.convert(point, from: host.containerView)
            if tip.bounds.contains(tipPoint) { return tip }
            tip.hide()
            overlayHandle?.setState(.dismissing)
            return nil
        }
        tip.show(text: text,
                 direction: direction,
                 maxWidth: maxWidth,
                 in: host.containerView,
                 from: resolved.rect,
                 duration: duration)
        overlayHandle.setState(.presenting)
        overlayHandle.setState(.visible)
        return overlayHandle
    }

    private static func resolvedAnchor(_ view: UIView) -> PTAnchorResolver.Resolved? {
        guard case let .success(resolved) = PTAnchorResolver.resolve(.view(view), context: .view(view)) else { return nil }
        return resolved
    }

    private static func popTipDirection(for placement: PTPopoverPlacement) -> PopTipDirection {
        switch placement {
        case .top, .topLeading, .topTrailing: return .up
        case .bottom, .bottomLeading, .bottomTrailing: return .down
        case .leading: return .left
        case .trailing: return .right
        case .automatic: return .auto
        }
    }
}
