// English: Native UIKit menu coordination for PTools controls.
// Español: Coordinación de menús UIKit nativos para los controles de PTools.
// 中文：为 PTools 控件提供原生 UIKit 菜单协调能力。

import UIKit

/// English: Chooses how a control presents its native menu.
/// Español: Elige cómo un control presenta su menú nativo.
/// 中文：选择控件展示原生菜单的方式。
public enum PTControlMenuTrigger: Sendable {
    /// English: Keep the normal tap action and open the menu with a long press.
    /// Español: Conserva la acción de toque normal y abre el menú con una pulsación larga.
    /// 中文：保留普通点击事件，通过长按打开菜单。
    case longPress

    /// English: Use the control's primary action to open the menu.
    /// Español: Usa la acción primaria del control para abrir el menú。
    /// 中文：使用控件的主操作打开菜单。
    case primaryAction
}

/// English: Controls that implement UIKit's UIControl menu delegate callbacks can opt into the native path.
/// Español: Los controles que implementan los callbacks de menú de UIControl pueden usar la ruta nativa.
/// 中文：实现 UIControl 菜单代理回调的控件可以加入原生路径。
@MainActor
internal protocol PTNativeControlMenuHost: AnyObject {}

@MainActor
internal enum PTControlMenuAssociatedKeys {
    static var coordinator: UInt8 = 0
}

/// English: Builds and owns one menu provider for one control without keeping a second selection state.
/// Español: Construye y posee un proveedor de menú por control sin mantener un segundo estado de selección.
/// 中文：为每个控件维护一个菜单提供器，不额外保存第二份选择状态。
@MainActor
internal final class PTControlMenuCoordinator: NSObject, UIContextMenuInteractionDelegate {
    typealias Provider = @MainActor () -> UIMenu?

    weak var control: UIControl?

    private let trigger: PTControlMenuTrigger
    private let dynamicProvider: Bool
    private var provider: Provider?
    private var interaction: UIContextMenuInteraction?

    private var originalButtonMenu: UIMenu?
    private var originalButtonShowsPrimaryAction = false
    private var installedButtonMenu: UIMenu?

    private var originalContextMenuEnabled = false
    private var originalShowsPrimaryAction = false
    private var installedContextMenuEnabled = false
    private var installedShowsPrimaryAction = false

    init(control: UIControl,
         trigger: PTControlMenuTrigger,
         dynamicProvider: Bool,
         provider: @escaping Provider) {
        self.control = control
        self.trigger = trigger
        self.dynamicProvider = dynamicProvider
        self.provider = provider
        super.init()

        if let button = control as? UIButton {
            originalButtonMenu = button.menu
            originalButtonShowsPrimaryAction = button.showsMenuAsPrimaryAction
        } else if control is PTNativeControlMenuHost {
            originalContextMenuEnabled = control.isContextMenuInteractionEnabled
            originalShowsPrimaryAction = control.showsMenuAsPrimaryAction
        }
    }

    func install() {
        guard let control, control.isUserInteractionEnabled else { return }

        if let button = control as? UIButton {
            let menu = dynamicProvider ? makeDeferredButtonMenu() : provider?()
            button.menu = menu
            button.showsMenuAsPrimaryAction = trigger == .primaryAction
            installedButtonMenu = menu
            return
        }

        if control is PTNativeControlMenuHost {
            control.isContextMenuInteractionEnabled = true
            control.showsMenuAsPrimaryAction = trigger == .primaryAction
            installedContextMenuEnabled = true
            installedShowsPrimaryAction = trigger == .primaryAction
            return
        }

        // English: A plain UIControl cannot expose a public primary-action menu hook; do not silently change it to long press.
        // Español: Un UIControl común no expone un hook público para la acción primaria; no lo cambiamos silenciosamente a pulsación larga.
        // 中文：普通 UIControl 没有公开的主点击菜单入口，不能把主点击请求静默改成长按。
        guard trigger == .longPress else {
            provider = nil
            return
        }

        // English: A raw UIControl has no public primary-action presentation hook, so use UIKit's interaction for long press.
        // Español: Un UIControl sin adaptación no tiene un hook público de acción primaria; usamos la interacción UIKit para pulsación larga.
        // 中文：普通 UIControl 没有公开的主点击展示入口，因此通过 UIKit interaction 提供可靠的长按菜单。
        guard !control.interactions.contains(where: { $0 is UIContextMenuInteraction }) else { return }
        let interaction = UIContextMenuInteraction(delegate: self)
        control.addInteraction(interaction)
        self.interaction = interaction
    }

    func remove() {
        guard let control else {
            provider = nil
            return
        }

        if let button = control as? UIButton {
            if let installedButtonMenu, button.menu === installedButtonMenu {
                button.menu = originalButtonMenu
            } else if installedButtonMenu == nil, button.menu == nil {
                button.menu = originalButtonMenu
            }
            if button.showsMenuAsPrimaryAction == (trigger == .primaryAction) {
                button.showsMenuAsPrimaryAction = originalButtonShowsPrimaryAction
            }
        } else if control is PTNativeControlMenuHost {
            if control.isContextMenuInteractionEnabled == installedContextMenuEnabled {
                control.isContextMenuInteractionEnabled = originalContextMenuEnabled
            }
            if control.showsMenuAsPrimaryAction == installedShowsPrimaryAction {
                control.showsMenuAsPrimaryAction = originalShowsPrimaryAction
            }
        }

        if let interaction {
            control.removeInteraction(interaction)
        }
        self.interaction = nil
        provider = nil
    }

    static func configuration(for control: UIControl,
                              location: CGPoint) -> UIContextMenuConfiguration? {
        guard let coordinator = control.pt_controlMenuCoordinator else { return nil }
        return coordinator.configuration(for: location)
    }

    private func configuration(for location: CGPoint) -> UIContextMenuConfiguration? {
        guard canPresent else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            self?.makeMenu()
        }
    }

    private var canPresent: Bool {
        guard let control else { return false }
        return control.isEnabled && control.isUserInteractionEnabled
    }

    private func makeMenu() -> UIMenu? {
        guard canPresent else { return nil }
        return provider?()
    }

    private func makeDeferredButtonMenu() -> UIMenu {
        let deferred = UIDeferredMenuElement.uncached { [weak self] completion in
            let children = self?.makeMenu()?.children ?? []
            completion(children)
        }
        return UIMenu(title: "", children: [deferred])
    }

    // English: Forward the context-menu delegate callback to the installed provider.
    // Español: Reenvía el callback del delegado de menú al proveedor instalado.
    // 中文：将 context-menu 代理回调转发给已安装的菜单提供器。
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        configuration(for: location)
    }
}

/// English: Keeps selection rendering in one place so the selected image never leaks to unselected items.
/// Español: Centraliza el renderizado de selección para que la imagen seleccionada nunca aparezca en otros elementos.
/// 中文：集中处理选中态渲染，避免选中图标泄漏到未选项。
@MainActor
internal enum PTControlMenuFactory {
    static func makeSelectionMenu<ID: Hashable>(
        items: [PTControlMenuSelectionItem<ID>],
        selectedID: ID?,
        selectionChanged: @escaping @MainActor (ID) -> Void
    ) -> UIMenu? {
        guard !items.isEmpty else { return nil }

        let actions = items.map { item in
            let image = item.id == selectedID
                ? (item.selectedImage ?? UIImage(systemName: "checkmark"))
                : nil
            return UIAction(title: item.title, image: image) { _ in
                selectionChanged(item.id)
            }
        }
        return UIMenu(title: "", children: actions)
    }
}
