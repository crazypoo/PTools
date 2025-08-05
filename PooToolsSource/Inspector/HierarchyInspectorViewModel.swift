//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

enum HierarchyInspectorCellViewModel {
    case action(HierarchyInspectorActionTableViewCellViewModelProtocol)
    case element(HierarchyInspectorReferenceSummaryCellViewModelProtocol)
}

protocol HierarchyInspectorViewModelProtocol: HierarchyInspectorSectionViewModelProtocol {
    var isSearching: Bool { get }
    var searchQuery: String? { get }
    func search(_ searchQuery: String?, completion: PTActionTask)
}

protocol HierarchyInspectorSectionViewModelProtocol {
    var numberOfSections: Int { get }

    var isEmpty: Bool { get }

    var shouldAnimateKeyboard: Bool { get }

    func numberOfRows(in section: Int) -> Int

    func titleForHeader(in section: Int) -> String?

    func cellViewModelForRow(at indexPath: IndexPath) -> HierarchyInspectorCellViewModel

    func selectRow(at indexPath: IndexPath) -> InspectorCommand?

    func isRowEnabled(at indexPath: IndexPath) -> Bool

    func loadData()
}

final class HierarchyInspectorViewModel {
    let commandGroupsViewModel: CommandGroupsViewModel

    let snapshotViewModel: SnapshotViewModel

    let shouldAnimateKeyboard: Bool

    var isSearching: Bool {
        searchQuery.isNilOrEmpty == false
    }

    private(set) var searchQuery: String? {
        didSet {
            let trimmedQuery = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines)
            snapshotViewModel.searchQuery = trimmedQuery?.isEmpty == false ? trimmedQuery : nil
        }
    }

    init(
        commandGroupsProvider: @escaping CommandGroupsProvider,
        snapshot: ViewHierarchySnapshot,
        shouldAnimateKeyboard: Bool
    ) {
        commandGroupsViewModel = CommandGroupsViewModel(commandGroupsProvider: commandGroupsProvider)
        snapshotViewModel = SnapshotViewModel(snapshot: snapshot)
        self.shouldAnimateKeyboard = shouldAnimateKeyboard
    }
}

// MARK: - HierarchyInspectorViewModelProtocol

extension HierarchyInspectorViewModel: @MainActor HierarchyInspectorViewModelProtocol {
    @MainActor func search(_ searchQuery: String?, completion: PTActionTask) {
        self.searchQuery = searchQuery
        completion()
    }

    func isRowEnabled(at indexPath: IndexPath) -> Bool {
        switch isSearching {
        case true:
            return snapshotViewModel.isRowEnabled(at: indexPath)

        case false:
            return commandGroupsViewModel.isRowEnabled(at: indexPath)
        }
    }

    var isEmpty: Bool {
        switch isSearching {
        case true:
            return snapshotViewModel.isEmpty

        case false:
            return commandGroupsViewModel.isEmpty
        }
    }

    func loadData() {
        switch isSearching {
        case true:
            return snapshotViewModel.loadData()

        case false:
            return commandGroupsViewModel.loadData()
        }
    }

    func selectRow(at indexPath: IndexPath) -> InspectorCommand? {
        switch isSearching {
        case true:
            return snapshotViewModel.selectRow(at: indexPath)

        case false:
            return commandGroupsViewModel.selectRow(at: indexPath)
        }
    }

    var numberOfSections: Int {
        switch isSearching {
        case true:
            return snapshotViewModel.numberOfSections

        case false:
            return commandGroupsViewModel.numberOfSections
        }
    }

    func numberOfRows(in section: Int) -> Int {
        switch isSearching {
        case true:
            return snapshotViewModel.numberOfRows(in: section)

        case false:
            return commandGroupsViewModel.numberOfRows(in: section)
        }
    }

    func titleForHeader(in section: Int) -> String? {
        switch isSearching {
        case true:
            return snapshotViewModel.titleForHeader(in: section)

        case false:
            return commandGroupsViewModel.titleForHeader(in: section)
        }
    }

    func cellViewModelForRow(at indexPath: IndexPath) -> HierarchyInspectorCellViewModel {
        switch isSearching {
        case true:
            return snapshotViewModel.cellViewModelForRow(at: indexPath)

        case false:
            return commandGroupsViewModel.cellViewModelForRow(at: indexPath)
        }
    }
}
