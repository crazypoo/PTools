//
//  PTListViewController.swift
//  PooTools
//
//  English: Hosts one PTCollectionView while preserving its delegate ownership.
//  Español: Aloja un PTCollectionView y conserva la propiedad de su delegate.
//  中文：承载一个 PTCollectionView，并保留其 delegate 的所有权。
//

import UIKit

@MainActor
@objcMembers
open class PTListViewController: PTBaseViewController {
    public private(set) lazy var listView: PTCollectionView = {
        PTCollectionView(viewConfig: makeListViewConfiguration())
    }()

    // English: Override this hook to choose the table-like or collection-like layout before creation.
    // Español: Sobrescribe este hook para elegir el diseño tipo tabla o tipo colección antes de crear la lista.
    // 中文：在列表创建前通过此方法选择类表格或类集合布局。
    open func makeListViewConfiguration() -> PTCollectionViewConfig {
        let configuration = PTCollectionViewConfig()
        configuration.viewType = .Normal
        return configuration
    }

    // English: Configure the existing list without creating another collection view.
    // Español: Configura la lista existente sin crear otra collection view.
    // 中文：配置已有列表，不再创建第二个 collection view。
    open func configureListView(_ listView: PTCollectionView) { }

    // English: Add auxiliary views before the default constraints are installed.
    // Español: Añade vistas auxiliares antes de instalar las restricciones predeterminadas.
    // 中文：在安装默认约束前添加搜索栏、关闭按钮等辅助视图。
    open func prepareListViewLayout(_ listView: PTCollectionView) { }

    // English: The default layout fills the safe area and can be replaced by a subclass.
    // Español: El diseño predeterminado ocupa el área segura y puede reemplazarse en una subclase.
    // 中文：默认布局铺满安全区，子类可以替换为全屏或自定义布局。
    open func installListViewConstraints(_ listView: PTCollectionView) {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            listView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            listView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            listView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            listView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    // English: Called after the base large-title transition has been updated.
    // Español: Se llama después de actualizar la transición del título grande de la base.
    // 中文：基类完成大标题过渡更新后调用。
    open func listViewDidScroll(_ collectionView: UICollectionView) { }

    // English: Called after the wrapped collection view finishes a drag.
    // Español: Se llama cuando la collection view envuelta termina un arrastre.
    // 中文：包装的 collection view 结束拖拽后调用。
    open func listViewDidEndDragging(_ collectionView: UICollectionView, willDecelerate: Bool) { }

    open override func viewDidLoad() {
        super.viewDidLoad()

        let listView = self.listView
        listView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(listView)
        configureListView(listView)
        prepareListViewLayout(listView)
        installListViewConstraints(listView)

        view.layoutIfNeeded()
        pt_prepareScrollViewForLargeTitle(listView.contentCollectionView, assignsDelegate: false)
        listView.listControllerDidScroll = { [weak self] collectionView in
            guard let self else { return }
            self.pt_updateLargeTitleTransition(for: collectionView)
            self.listViewDidScroll(collectionView)
        }
        listView.listControllerDidEndDragging = { [weak self] collectionView, willDecelerate in
            guard let self else { return }
            self.pt_finishLargeTitleDrag(for: collectionView)
            self.listViewDidEndDragging(collectionView, willDecelerate: willDecelerate)
        }
    }
}
