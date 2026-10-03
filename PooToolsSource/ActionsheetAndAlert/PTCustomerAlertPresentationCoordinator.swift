// English: Owns trait and accessibility observation wiring for the alert presentation surface.
// Español: Gestiona las observaciones de traits y accesibilidad de la superficie de presentación.
// 中文：集中管理 Alert 展示表面的 Trait 和辅助功能观察。

import UIKit

@MainActor
extension PTCustomerAlertController {

    func installSurfaceAppearanceObservers() {
        traitChangeRegistration = registerForTraitChanges([
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self
        ]) { [weak self] (_: PTCustomerAlertController, _: UITraitCollection) in
            guard let self else { return }
            self.updateSurfaceAppearance()
            self.invalidateContentLayout()
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityAppearanceDidChange),
            name: UIAccessibility.reduceTransparencyStatusDidChangeNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(accessibilityAppearanceDidChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
    }

    @objc
    private func accessibilityAppearanceDidChange() {
        updateSurfaceAppearance()
        invalidateContentLayout()
    }
}
