// English: Public UIMenu and selection-menu APIs for the PTools UIControl family.
// Español: APIs públicas de UIMenu y menús de selección para la familia UIControl de PTools.
// 中文：为 PTools UIControl 体系提供公开的 UIMenu 和选择菜单 API。

import UIKit

@MainActor
public struct PTControlMenuSelectionItem<ID: Hashable> {
    /// English: Stable business identity used to determine the selected item.
    /// Español: Identidad estable del negocio usada para determinar el elemento seleccionado.
    /// 中文：用于判断选中项的稳定业务标识。
    public let id: ID

    /// English: Text displayed by the native menu.
    /// Español: Texto mostrado por el menú nativo.
    /// 中文：原生菜单显示的文本。
    public let title: String

    /// English: Displayed only while this item is selected; unselected items always have no image.
    /// Español: Solo se muestra mientras este elemento está seleccionado; los no seleccionados siempre carecen de imagen.
    /// 中文：仅在当前项被选中时显示；未选项始终不显示图片。
    public let selectedImage: UIImage?

    /// English: Creates a selection item with an optional selected-state image.
    /// Español: Crea un elemento de selección con una imagen opcional para el estado seleccionado.
    /// 中文：创建带可选选中态图片的选择菜单项。
    public init(id: ID, title: String, selectedImage: UIImage? = nil) {
        self.id = id
        self.title = title
        self.selectedImage = selectedImage
    }
}

@MainActor
public extension UIControl {
    /// English: Installs a static native menu; nil removes the PTools menu.
    /// Español: Instala un menú nativo estático; nil elimina el menú de PTools.
    /// 中文：安装静态原生菜单；传入 nil 会移除 PTools 菜单。
    func pt_setMenu(_ menu: UIMenu?,
                    trigger: PTControlMenuTrigger = .longPress) {
        pt_removeMenu()
        guard let menu else { return }
        pt_installMenu(trigger: trigger, dynamicProvider: false) { menu }
    }

    /// English: Installs a provider that is evaluated every time UIKit presents the menu.
    /// Español: Instala un proveedor que se evalúa cada vez que UIKit presenta el menú.
    /// 中文：安装动态提供器，每次 UIKit 展示菜单前都会重新执行。
    func pt_setMenuProvider(trigger: PTControlMenuTrigger = .longPress,
                            _ provider: @escaping @MainActor () -> UIMenu?) {
        pt_removeMenu()
        pt_installMenu(trigger: trigger, dynamicProvider: true, provider)
    }

    /// English: Installs a selection menu whose selectedID is the single source of truth.
    /// Español: Instala un menú de selección cuyo selectedID es la única fuente de verdad.
    /// 中文：安装选择菜单，selectedID 是唯一真实状态源。
    func pt_setSelectionMenu<ID: Hashable>(
        items: [PTControlMenuSelectionItem<ID>],
        selectedID: ID,
        trigger: PTControlMenuTrigger = .primaryAction,
        selectionChanged: @escaping @MainActor (ID) -> Void
    ) {
        pt_setSelectionMenuProvider(
            trigger: trigger,
            items: { items },
            selectedID: { selectedID },
            selectionChanged: selectionChanged
        )
    }

    /// English: Builds the selection menu from current data every time it is opened.
    /// Español: Construye el menú de selección con los datos actuales cada vez que se abre.
    /// 中文：每次打开菜单时都从最新数据重新构建选择菜单。
    func pt_setSelectionMenuProvider<ID: Hashable>(
        trigger: PTControlMenuTrigger = .primaryAction,
        items: @escaping @MainActor () -> [PTControlMenuSelectionItem<ID>],
        selectedID: @escaping @MainActor () -> ID?,
        selectionChanged: @escaping @MainActor (ID) -> Void
    ) {
        pt_setMenuProvider(trigger: trigger) {
            PTControlMenuFactory.makeSelectionMenu(
                items: items(),
                selectedID: selectedID(),
                selectionChanged: selectionChanged
            )
        }
    }

    /// English: Removes only the menu installed by PTools and restores the previous native button state.
    /// Español: Elimina solo el menú instalado por PTools y restaura el estado nativo anterior del botón.
    /// 中文：只移除 PTools 安装的菜单，并恢复控件之前的原生状态。
    func pt_removeMenu() {
        guard let coordinator = pt_controlMenuCoordinator else { return }
        coordinator.remove()
        objc_setAssociatedObject(self,
                                 &PTControlMenuAssociatedKeys.coordinator,
                                 nil,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

@MainActor
internal extension UIControl {
    var pt_controlMenuCoordinator: PTControlMenuCoordinator? {
        objc_getAssociatedObject(self, &PTControlMenuAssociatedKeys.coordinator) as? PTControlMenuCoordinator
    }

    func pt_installMenu(trigger: PTControlMenuTrigger,
                         dynamicProvider: Bool,
                         _ provider: @escaping @MainActor () -> UIMenu?) {
        let coordinator = PTControlMenuCoordinator(control: self,
                                                    trigger: trigger,
                                                    dynamicProvider: dynamicProvider,
                                                    provider: provider)
        objc_setAssociatedObject(self,
                                 &PTControlMenuAssociatedKeys.coordinator,
                                 coordinator,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        coordinator.install()
    }
}
