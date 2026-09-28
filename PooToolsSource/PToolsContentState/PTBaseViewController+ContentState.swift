// English: Explicit content-state hosting for the existing base view controller.
// Español: Hosting explícito de estados de contenido para el view controller base existente.
// 中文：为现有基类提供显式的内容状态宿主能力。

#if canImport(UIKit)
import UIKit
#if SWIFT_PACKAGE
import ptools
#endif

@MainActor
public extension PTBaseViewController {
    @discardableResult
    func installContentStateHost(_ host: PTContentStateView,
                                 in container: UIView? = nil,
                                 useSafeArea: Bool = true) -> PTContentStateView {
        let target = container ?? view
        guard host.superview !== target else { return host }
        host.removeFromSuperview()
        target.addSubview(host)
        host.translatesAutoresizingMaskIntoConstraints = false
        let guide = useSafeArea && container == nil ? target.safeAreaLayoutGuide : target
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            host.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            host.topAnchor.constraint(equalTo: guide.topAnchor),
            host.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
        ])
        return host
    }

    func uninstallContentStateHost(_ host: PTContentStateView) {
        guard host.superview != nil else { return }
        host.removeFromSuperview()
    }
}
#endif
