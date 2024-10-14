//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension HierarchyInspectorViewModel {
    final class CommandGroupsViewModel: HierarchyInspectorSectionViewModelProtocol {
        let shouldAnimateKeyboard: Bool = true

        struct Details: HierarchyInspectorActionTableViewCellViewModelProtocol {
            let title: String
            var icon: UIImage?
            var isEnabled: Bool
            var isSelected: Bool
        }

        private(set) lazy var layerCommandGroups = CommandsGroups()

        let provider: CommandGroupsProvider

        init(commandGroupsProvider: @escaping CommandGroupsProvider) {
            provider = commandGroupsProvider
        }

        var isEmpty: Bool {
            var totalActionCount = 0

            for group in layerCommandGroups {
                totalActionCount += group.commands.count
            }

            return totalActionCount == 0
        }

        private struct ExpirableSnapshot<Value>: ExpirableProtocol {
            private let _value: Value
            let expirationDate: Date

            var value: Value? {
                isValid ? _value : .none
            }

            init(_ value: Value) {
                _value = value
                expirationDate = Date()
                    .addingTimeInterval(10)
            }
        }

        private var layerCommandGroupsSnapshot: ExpirableSnapshot<CommandsGroups>?

        func loadData() {
            if let cachedValue = layerCommandGroupsSnapshot?.value {
                layerCommandGroups = cachedValue
                return
            }

            guard let groups = provider() else {
                layerCommandGroups = layerCommandGroups
                return
            }

            let snapshot = ExpirableSnapshot(groups)
            layerCommandGroupsSnapshot = snapshot
            layerCommandGroups = groups
        }

        func selectRow(at indexPath: IndexPath) -> InspectorCommand? {
            guard let closure = action(at: indexPath).closure else {
                return nil
            }
            return .execute(closure)
        }

        func isRowEnabled(at indexPath: IndexPath) -> Bool {
            action(at: indexPath).isEnabled
        }

        var numberOfSections: Int {
            layerCommandGroups.count
        }

        func numberOfRows(in section: Int) -> Int {
            group(in: section).commands.count
        }

        func titleForHeader(in section: Int) -> String? {
            group(in: section).title
        }

        func cellViewModelForRow(at indexPath: IndexPath) -> HierarchyInspectorCellViewModel {
            let action = self.action(at: indexPath)

            return .action(
                Details(
                    title: action.title,
                    icon: action.icon?.resized(.actionIconSize),
                    isEnabled: action.isEnabled,
                    isSelected: action.isSelected
                )
            )
        }

        private func group(in section: Int) -> CommandsGroup {
            layerCommandGroups[section]
        }

        private func action(at indexPath: IndexPath) -> Command {
            group(in: indexPath.section).commands[indexPath.row]
        }
    }
}
