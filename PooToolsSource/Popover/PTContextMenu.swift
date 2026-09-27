// English: A scrollable, accessible context menu product built on PTPopover.
// Español: Un menú contextual desplazable y accesible construido sobre PTPopover.
// 中文：基于 PTPopover 的可滚动、可访问上下文菜单产品层。

import UIKit
#if canImport(PToolsSymbols)
import PToolsSymbols
#endif

@MainActor
public enum PTMenuImage {
    case symbol(PTSymbol)
    case image(UIImage)
}

@MainActor
public enum PTMenuItemState {
    case normal
    case selected
    case disabled
    case destructive
}

@MainActor
public struct PTContextMenuItem {
    public let id: AnyHashable
    public var title: String
    public var subtitle: String?
    public var image: PTMenuImage?
    public var state: PTMenuItemState
    public var action: @MainActor @Sendable () -> Void

    public init(id: AnyHashable,
                title: String,
                subtitle: String? = nil,
                image: PTMenuImage? = nil,
                state: PTMenuItemState = .normal,
                action: @escaping @MainActor @Sendable () -> Void) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.state = state
        self.action = action
    }
}

@MainActor
public struct PTContextMenuSection {
    public let id: AnyHashable
    public var title: String?
    public var items: [PTContextMenuItem]

    public init(id: AnyHashable,
                title: String? = nil,
                items: [PTContextMenuItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

@MainActor
public struct PTContextMenu {
    public var sections: [PTContextMenuSection]

    public init(sections: [PTContextMenuSection]) {
        self.sections = sections
    }

    public init(items: [PTContextMenuItem]) {
        self.sections = [PTContextMenuSection(id: "default", items: items)]
    }
}

@MainActor
public final class PTContextMenuView: UIView, UITableViewDataSource, UITableViewDelegate {
    enum Row {
        case item(PTContextMenuItem)
        case separator

        var isSeparator: Bool {
            if case .separator = self { return true }
            return false
        }
    }

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let rows: [Row]
    private let maxHeight: CGFloat
    public var onSelect: ((PTContextMenuItem) -> Void)?

    public init(menu: PTContextMenu, maxHeight: CGFloat) {
        self.maxHeight = max(44, maxHeight)
        self.rows = menu.sections.enumerated().flatMap { index, section in
            var result = section.items.map(Row.item)
            if index < menu.sections.count - 1 { result.append(.separator) }
            return result
        }
        super.init(frame: .zero)
        backgroundColor = .clear
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 52
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PTContextMenuCell")
        addSubview(tableView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        tableView.frame = bounds
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: 220, height: min(maxHeight, CGFloat(rows.reduce(0) { $0 + ($1.isSeparator ? 8 : 52) })))
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        switch row {
        case .separator:
            let cell = UITableViewCell()
            cell.backgroundColor = .clear
            cell.contentView.backgroundColor = UIColor.separator.withAlphaComponent(0.2)
            return cell
        case let .item(item):
            let cell = tableView.dequeueReusableCell(withIdentifier: "PTContextMenuCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = item.title
            content.secondaryText = item.subtitle
            switch item.image {
            case let .symbol(symbol):
                content.image = UIImage(systemName: symbol.rawValue)
            case let .image(image):
                content.image = image
            case nil:
                content.image = nil
            }
            cell.contentConfiguration = content
            cell.accessoryType = item.state == .selected ? .checkmark : .none
            cell.isUserInteractionEnabled = item.state != .disabled
            if item.state == .destructive {
                cell.tintColor = .systemRed
                cell.contentView.tintColor = .systemRed
            } else {
                cell.tintColor = nil
                cell.contentView.tintColor = nil
            }
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        rows[indexPath.row].isSeparator ? 8 : 52
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard case let .item(item) = rows[indexPath.row], item.state != .disabled else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect?(item)
    }
}
