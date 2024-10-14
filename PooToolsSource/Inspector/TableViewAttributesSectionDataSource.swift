//  PooTools_Example
//
//  Created by 邓杰豪 on 10/13/24.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit

extension DefaultElementAttributesLibrary {
    final class TableViewAttributesSectionDataSource: InspectorElementSectionDataSource {
        let title: String = "Table View"

        var state: InspectorElementSectionState = .collapsed

        private weak var tableView: UITableView?

        init?(with object: NSObject) {
            guard let tableView = object as? UITableView else { return nil }
            self.tableView = tableView
        }

        private enum Properties: String, Swift.CaseIterable {
            case style = "Style"
            case separatorStyle = "Separator"
            case separatorColor = "Color"
            case divider
            case separatorInset = "Separator Inset"
            case selection = "Selection"
            case editingSelection = "Editing"
            case isSpringLoaded = "Spring loaded drag n' drop"
        }

        var properties: [InspectorElementProperty] {
            guard let tableView = tableView else { return [] }

            return Properties.allCases.map { property in
                switch property {
                case .style:
                    return .optionsList(
                        title: property.rawValue,
                        options: UITableView.Style.allCases.map(\.description),
                        selectedIndex: { UITableView.Style.allCases.firstIndex(of: tableView.style) },
                        handler: nil
                    )
                case .separatorStyle:
                    return .optionsList(
                        title: property.rawValue,
                        options: UITableViewCell.SeparatorStyle.allCases.map(\.description),
                        selectedIndex: { UITableViewCell.SeparatorStyle.allCases.firstIndex(of: tableView.separatorStyle) },
                        handler: {
                            guard let newIndex = $0 else { return }

                            let style = UITableViewCell.SeparatorStyle.allCases[newIndex]
                            tableView.separatorStyle = style
                        }
                    )
                case .separatorColor:
                    return .colorPicker(
                        title: property.rawValue,
                        emptyTitle: "Default",
                        color: { tableView.separatorColor },
                        handler: { newColor in
                            tableView.separatorColor = newColor
                        }
                    )
                case .divider:
                    return .separator

                case .separatorInset:
                    return .edgeInsets(
                        title: property.rawValue,
                        insets: { tableView.separatorInset },
                        handler: { separatorInset in
                            tableView.separatorInset = separatorInset
                        }
                    )
                case .selection:
                    return .optionsList(
                        title: property.rawValue,
                        emptyTitle: property.rawValue,
                        axis: .vertical,
                        options: ["None", "Single Selection", "Multiple Selection"],
                        selectedIndex: {
                            if tableView.allowsMultipleSelection { return 1 }
                            if tableView.allowsSelection { return 0 }
                            return 0
                        }
                    ) {
                        switch $0 {
                        case 0:
                            tableView.allowsSelection = false
                            tableView.allowsMultipleSelection = false
                        case 1:
                            tableView.allowsSelection = true
                            tableView.allowsMultipleSelection = false
                        case 2:
                            tableView.allowsSelection = true
                            tableView.allowsMultipleSelection = true
                        default:
                            break
                        }
                    }
                case .editingSelection:
                    return .optionsList(
                        title: property.rawValue,
                        emptyTitle: property.rawValue,
                        axis: .vertical,
                        options: ["None", "Single Selection", "Multiple Selection"],
                        selectedIndex: {
                            if tableView.allowsMultipleSelectionDuringEditing { return 1 }
                            if tableView.allowsSelectionDuringEditing { return 0 }
                            return 0
                        }
                    ) {
                        switch $0 {
                        case 0:
                            tableView.allowsSelectionDuringEditing = false
                            tableView.allowsMultipleSelectionDuringEditing = false
                        case 1:
                            tableView.allowsSelectionDuringEditing = true
                            tableView.allowsMultipleSelectionDuringEditing = false
                        case 2:
                            tableView.allowsSelectionDuringEditing = true
                            tableView.allowsMultipleSelectionDuringEditing = true
                        default:
                            break
                        }
                    }
                case .isSpringLoaded:
                    return .switch(
                        title: property.rawValue,
                        isOn: { tableView.isSpringLoaded },
                        handler: { isSpringLoaded in
                            tableView.isSpringLoaded = isSpringLoaded
                        }
                    )
                }
            }
        }
    }
}

extension UITableViewCell.SeparatorStyle: CaseIterable {
    public typealias AllCases = [UITableViewCell.SeparatorStyle]

    public static var allCases: [UITableViewCell.SeparatorStyle] {
        [.none, .singleLine]
    }
}

extension UITableViewCell.SeparatorStyle: CustomStringConvertible {
    var description: String {
        switch self {
        case .none:
            return "None"
        case .singleLine:
            return "Single Line"
        case .singleLineEtched:
            return "Etched Single Line"
        @unknown default:
            return "Unknown"
        }
    }
}

extension UITableView.Style: CaseIterable {
    public typealias AllCases = [UITableView.Style]

    public static let allCases: [UITableView.Style] = [.plain, .grouped, .insetGrouped]
}

extension UITableView.Style: CustomStringConvertible {
    var description: String {
        switch self {
        case .plain:
            return "Plain"
        case .grouped:
            return "Grouped"
        case .insetGrouped:
            return "Inset Grouped"
        @unknown default:
            return "Unknown"
        }
    }
}
