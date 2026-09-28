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
        guard let target = container ?? view else { return host }
        guard host.superview !== target else { return host }
        host.removeFromSuperview()
        target.addSubview(host)
        host.translatesAutoresizingMaskIntoConstraints = false
        if useSafeArea && container == nil {
            let guide = target.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                host.topAnchor.constraint(equalTo: guide.topAnchor),
                host.bottomAnchor.constraint(equalTo: guide.bottomAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                host.leadingAnchor.constraint(equalTo: target.leadingAnchor),
                host.trailingAnchor.constraint(equalTo: target.trailingAnchor),
                host.topAnchor.constraint(equalTo: target.topAnchor),
                host.bottomAnchor.constraint(equalTo: target.bottomAnchor)
            ])
        }
        return host
    }

    func uninstallContentStateHost(_ host: PTContentStateView) {
        guard host.superview != nil else { return }
        host.removeFromSuperview()
    }
}
#endif
