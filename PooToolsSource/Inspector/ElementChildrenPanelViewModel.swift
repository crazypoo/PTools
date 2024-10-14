//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

protocol ElementChildrenPanelViewModelProtocol {
    var title: String? { get }

    var rootElement: ViewHierarchyElementReference { get }

    var numberOfRows: Int { get }

    func shouldHighlightItem(at indexPath: IndexPath) -> Bool

    func cellViewModel(at indexPath: IndexPath) -> ElementChildrenPanelTableViewCellViewModelProtocol?

    /// Toggle if a container displays its subviews or hides them.
    /// - Parameter indexPath: index path
    /// - Returns: Actions related to affected index paths
    func toggleContainer(at indexPath: IndexPath) -> [ElementChildrenPanelAction]

    func indexPath(for item: ElementChildrenPanelItemViewModelProtocol?) -> IndexPath?
}

final class ElementChildrenPanelViewModel: NSObject {
    let rootElement: ViewHierarchyElementReference

    private(set) var children: [CellViewModel] {
        didSet {
            updateVisibleChildren()
        }
    }

    private static func makeChildViewModels(
        element: ViewHierarchyElementReference,
        parent: CellViewModel? = .none,
        rootDepth: Int
    ) -> [CellViewModel] {
        let viewModel = CellViewModel(
            element: element,
            parent: parent,
            rootDepth: rootDepth,
            thumbnailImage: element.cachedIconImage,
            isCollapsed: element.depth > rootDepth
        )

        let childrenViewModels: [CellViewModel] = element.children.flatMap { childElement in
            makeChildViewModels(
                element: childElement,
                parent: viewModel,
                rootDepth: rootDepth
            )
        }

        return [viewModel] + childrenViewModels
    }

    private lazy var visibleChildren: [CellViewModel] = []

    let snapshot: ViewHierarchySnapshot

    init(element: ViewHierarchyElementReference, snapshot: ViewHierarchySnapshot) {
        rootElement = element
        self.snapshot = snapshot

        children = Self.makeChildViewModels(
            element: rootElement,
            rootDepth: rootElement.depth
        )

        super.init()

        updateVisibleChildren()
    }
}

extension ElementChildrenPanelViewModel: ElementChildrenPanelViewModelProtocol {
    func shouldHighlightItem(at indexPath: IndexPath) -> Bool { !indexPath.isFirst }

    var title: String? { "More info" }

    var numberOfRows: Int { visibleChildren.count }

    func cellViewModel(at indexPath: IndexPath) -> ElementChildrenPanelTableViewCellViewModelProtocol? {
        guard indexPath.row < visibleChildren.count else { return nil }

        return visibleChildren[indexPath.row]
    }

    func indexPath(for item: ElementChildrenPanelItemViewModelProtocol?) -> IndexPath? {
        guard
            let item = item as? CellViewModel,
            let row = visibleChildren.firstIndex(of: item)
        else {
            return nil
        }

        return IndexPath(row: row, section: .zero)
    }

    func toggleContainer(at indexPath: IndexPath) -> [ElementChildrenPanelAction] {
        guard indexPath.row < visibleChildren.count else { return [] }

        let container = visibleChildren[indexPath.row]

        guard container.isContainer else { return [] }

        container.isCollapsed.toggle()

        let oldVisibleChildren = visibleChildren

        updateVisibleChildren()

        let addedChildren = Set(visibleChildren).subtracting(oldVisibleChildren)

        let deletedChildren = Set(oldVisibleChildren).subtracting(visibleChildren)

        var deletedIndexPaths = [IndexPath]()

        var insertedIndexPaths = [IndexPath]()

        for child in deletedChildren {
            guard let row = oldVisibleChildren.firstIndex(of: child) else { continue }

            deletedIndexPaths.append(IndexPath(row: row, section: .zero))
        }

        for child in addedChildren {
            guard let row = visibleChildren.firstIndex(of: child) else { continue }

            insertedIndexPaths.append(IndexPath(row: row, section: .zero))
        }

        var actions = [ElementChildrenPanelAction]()

        if insertedIndexPaths.isEmpty == false {
            actions.append(.inserted(insertedIndexPaths))
        }

        if deletedIndexPaths.isEmpty == false {
            actions.append(.deleted(deletedIndexPaths))
        }

        return actions
    }

    private func updateVisibleChildren() {
        visibleChildren = children.filter { $0.isHidden == false }
    }
}
