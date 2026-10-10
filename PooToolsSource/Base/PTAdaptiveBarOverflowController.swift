//
//  PTAdaptiveBarOverflowController.swift
//  PooTools
//
//  English: Preserve navigation and selected-tab actions when a rail is too short.
//  Español: Conserva las acciones de navegación y la pestaña seleccionada cuando la rail es demasiado corta.
//  中文：当 Rail 空间不足时，保留导航操作与当前选中 Tab。
//

import UIKit

@MainActor
open class PTAdaptiveBarOverflowController: UITableViewController {
    public private(set) var itemIdentifiers: [String] = []
    public var onSelect: ((String) -> Void)?

    public func configure(itemIdentifiers: [String]) {
        self.itemIdentifiers = itemIdentifiers
        tableView.reloadData()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        itemIdentifiers.count
    }

    public override func tableView(_ tableView: UITableView,
                                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        guard itemIdentifiers.indices.contains(indexPath.row) else { return cell }
        cell.textLabel?.text = itemIdentifiers[indexPath.row]
        return cell
    }

    public override func tableView(_ tableView: UITableView,
                                   didSelectRowAt indexPath: IndexPath) {
        guard itemIdentifiers.indices.contains(indexPath.row) else { return }
        onSelect?(itemIdentifiers[indexPath.row])
    }
}
