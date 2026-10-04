//
//  PTSplitViewDemo.swift
//  PooTools_Example
//

import UIKit
import PooTools

// English: This model keeps Demo identifiers stable so state restoration never stores UIKit instances.
// Español: Este modelo mantiene identificadores estables para que la restauración nunca guarde instancias UIKit.
// 中文：这个模型保存稳定的 Demo 标识，状态恢复不会保存 UIKit 实例。
@MainActor
private enum PT5_61SplitDemoModel {
    struct Component: Hashable, Sendable {
        let id: String
        let title: String
        let summary: String
    }

    static let categories = [
        Component(id: "network", title: "Network", summary: "网络能力"),
        Component(id: "media", title: "Media", summary: "媒体能力"),
        Component(id: "debug", title: "Debug", summary: "调试能力")
    ]

    static let components: [String: [Component]] = [
        "network": [
            Component(id: "ping", title: "Ping", summary: "类型化 Ping 状态机"),
            Component(id: "speed", title: "Speed Test", summary: "显式 endpoint 测速")
        ],
        "media": [
            Component(id: "photo", title: "Photo Picker", summary: "相册和媒体请求"),
            Component(id: "video", title: "Video Export", summary: "原生视频导出")
        ],
        "debug": [
            Component(id: "network", title: "Debug Network", summary: "网络观测与脱敏"),
            Component(id: "instruments", title: "Instruments", summary: "运行时诊断")
        ]
    ]

    static func category(for id: String) -> Component {
        categories.first { $0.id == id } ?? categories[0]
    }

    static func components(for categoryID: String) -> [Component] {
        components[categoryID] ?? []
    }

    static func component(for id: String) -> Component {
        components.values.flatMap { $0 }.first { $0.id == id } ?? Component(id: id, title: id, summary: "")
    }

    static func identifier(for viewController: UIViewController) -> String? {
        if let navigationController = viewController as? UINavigationController {
            let identifiers = navigationController.viewControllers.compactMap { identifier(for: $0) }
            return identifiers.isEmpty ? nil : identifiers.joined(separator: "|")
        }
        if let sidebar = viewController as? PT5_61SplitDemoSidebarViewController {
            return "category:\(sidebar.selectedCategoryID)"
        }
        if let list = viewController as? PT5_61SplitDemoComponentListViewController {
            return "component-list:\(list.categoryID)"
        }
        if let detail = viewController as? PT5_61SplitDemoDetailViewController {
            return "detail:\(detail.componentID)"
        }
        return nil
    }

    static func resolve(identifier: String) -> UIViewController? {
        let identifiers = identifier.split(separator: "|").map(String.init)
        guard let first = identifiers.first,
              let firstController = resolveSingle(identifier: first) else {
            return nil
        }
        guard identifiers.count > 1 else { return firstController }

        let navigationController = PTBaseNavControl(rootViewController: firstController)
        for identifier in identifiers.dropFirst() {
            if let controller = resolveSingle(identifier: identifier) {
                navigationController.pushViewController(controller, animated: false)
            }
        }
        return navigationController
    }

    private static func resolveSingle(identifier: String) -> UIViewController? {
        let parts = identifier.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        switch parts[0] {
        case "category":
            return PT5_61SplitDemoSidebarViewController(compactMode: true, selectedCategoryID: parts[1])
        case "component-list":
            return PT5_61SplitDemoComponentListViewController(categoryID: parts[1])
        case "detail":
            let component = component(for: parts[1])
            return PT5_61SplitDemoDetailViewController(component: component)
        default:
            return nil
        }
    }
}

// English: A reusable table host keeps the Example UI small while preserving PTBaseViewController lifecycle behavior.
// Español: Un host de tabla reutilizable mantiene pequeña la UI de Example y conserva el ciclo de vida de PTBaseViewController.
// 中文：复用表格宿主减少 Example UI 代码，同时保留 PTBaseViewController 生命周期行为。
@MainActor
private class PT5_61SplitDemoTableViewController: PTBaseViewController, UITableViewDataSource, UITableViewDelegate {
    let tableView = UITableView(frame: .zero, style: .insetGrouped)
    var rows: [(title: String, subtitle: String)] = []
    var didSelectRow: ((Int) -> Void)?

    init(title: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .systemGroupedBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "pt-5-61-split-demo-cell")
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "pt-5-61-split-demo-cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = rows[indexPath.row].title
        content.secondaryText = rows[indexPath.row].subtitle
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        didSelectRow?(indexPath.row)
    }
}

// English: The primary and compact roots expose the same category flow on iPhone and iPad.
// Español: Las raíces primaria y compacta exponen el mismo flujo de categorías en iPhone y iPad.
// 中文：Primary 和 Compact 根页面在 iPhone、iPad 上提供一致的分类流程。
@MainActor
private final class PT5_61SplitDemoSidebarViewController: PT5_61SplitDemoTableViewController {
    let compactMode: Bool
    private(set) var selectedCategoryID: String
    var didSelectCategory: ((String) -> Void)?
    var didRequestRouter: (() -> Void)?
    var didRequestClose: (() -> Void)?

    init(compactMode: Bool, selectedCategoryID: String = "network") {
        self.compactMode = compactMode
        self.selectedCategoryID = selectedCategoryID
        super.init(title: compactMode ? "Categories" : "Categories / 主栏")
        rows = PT5_61SplitDemoModel.categories.map { ($0.title, $0.summary) }
    }

    required init?(coder: NSCoder) {
        compactMode = true
        selectedCategoryID = "network"
        super.init(coder: coder)
        rows = PT5_61SplitDemoModel.categories.map { ($0.title, $0.summary) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Router", style: .plain, target: self, action: #selector(routerTapped))
        didSelectRow = { [weak self] index in
            guard let self, PT5_61SplitDemoModel.categories.indices.contains(index) else { return }
            self.selectedCategoryID = PT5_61SplitDemoModel.categories[index].id
            self.didSelectCategory?(self.selectedCategoryID)
        }
    }

    @objc private func closeTapped() {
        didRequestClose?()
    }

    @objc private func routerTapped() {
        didRequestRouter?()
    }
}

// English: The supplementary list demonstrates the regular-width master/detail transition.
// Español: La lista suplementaria demuestra la transición master/detail en ancho regular.
// 中文：Supplementary 列表演示 regular 宽度下的主从页面切换。
@MainActor
private final class PT5_61SplitDemoComponentListViewController: PT5_61SplitDemoTableViewController {
    let categoryID: String
    var didSelectComponent: ((String) -> Void)?

    init(categoryID: String) {
        self.categoryID = categoryID
        super.init(title: "Components / 组件")
        rows = PT5_61SplitDemoModel.components(for: categoryID).map { ($0.title, $0.summary) }
    }

    required init?(coder: NSCoder) {
        categoryID = "network"
        super.init(coder: coder)
        rows = PT5_61SplitDemoModel.components(for: categoryID).map { ($0.title, $0.summary) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        didSelectRow = { [weak self] index in
            guard let self else { return }
            let components = PT5_61SplitDemoModel.components(for: self.categoryID)
            guard components.indices.contains(index) else { return }
            self.didSelectComponent?(components[index].id)
        }
    }
}

// English: Detail is intentionally a real page so both direct and Router-driven navigation are observable.
// Español: El detalle es una página real para que se observen la navegación directa y la del router.
// 中文：Detail 使用真实页面，便于观察直接导航和 Router 导航结果。
@MainActor
private final class PT5_61SplitDemoDetailViewController: PTBaseViewController {
    let componentID: String
    private let summary: String

    init(component: PT5_61SplitDemoModel.Component) {
        componentID = component.id
        summary = component.summary
        super.init(nibName: nil, bundle: nil)
        title = component.title
    }

    required init?(coder: NSCoder) {
        componentID = "detail"
        summary = ""
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.text = "\(title ?? "Detail")\n\n\(summary)\n\nAutomatic: compact → push / regular → secondary"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .label
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// English: Inspector exposes runtime state plus save/reset/restore controls for the Demo.
// Español: Inspector expone el estado de runtime y controles de guardar/restablecer/restaurar para el Demo.
// 中文：Inspector 展示运行时状态，并提供保存、重置、恢复操作。
@MainActor
private final class PT5_61SplitDemoInspectorViewController: PTBaseViewController {
    var stateProvider: (() -> String)?
    var saveStateAction: (() -> Void)?
    var resetStateAction: (() -> Void)?
    var restoreStateAction: (() -> Void)?
    var routerAction: (() -> Void)?
    private let stateLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inspector / 运行状态"
        stateLabel.numberOfLines = 0
        stateLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        stateLabel.textColor = .label

        let stack = UIStackView(arrangedSubviews: [
            makeButton(title: "Save State", action: #selector(saveTapped)),
            makeButton(title: "Reset", action: #selector(resetTapped)),
            makeButton(title: "Restore State", action: #selector(restoreTapped)),
            makeButton(title: "Router .push", action: #selector(routerTapped)),
            stateLabel
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        refreshState()
    }

    func refreshState() {
        guard isViewLoaded else { return }
        stateLabel.text = stateProvider?() ?? "等待容器状态"
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .primaryActionTriggered)
        return button
    }

    @objc private func saveTapped() { saveStateAction?(); refreshState() }
    @objc private func resetTapped() { resetStateAction?(); refreshState() }
    @objc private func restoreTapped() { restoreStateAction?(); refreshState() }
    @objc private func routerTapped() { routerAction?(); refreshState() }
}

// English: The single adaptive Demo is presented as a root container and works in compact and regular windows.
// Español: El único Demo adaptativo se presenta como contenedor raíz y funciona en ventanas compactas y regulares.
// 中文：唯一的自适应 Demo 作为根容器展示，兼容 compact 和 regular 窗口。
@MainActor
final class PT5_61SplitViewDemoViewController: PTSplitViewController {
    private var savedState: PTSplitState?
    private let inspector = PT5_61SplitDemoInspectorViewController()

    init() {
        super.init(configuration: PTSplitConfiguration(style: .tripleColumn,
                                                        displayMode: .oneBesideSecondary,
                                                        splitBehavior: .tile,
                                                        primaryWidthFraction: 0.25,
                                                        supplementaryWidthFraction: 0.25,
                                                        navigationPolicy: .wrapAll,
                                                        inspectorMode: .automatic))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        installDemoColumns()
        configureInspector()
    }

    private func installDemoColumns() {
        setPrimary(makeSidebar(compactMode: false))
        setSupplementary(makeComponentList(categoryID: "network", compactMode: false))
        setSecondary(PT5_61SplitDemoDetailViewController(component: PT5_61SplitDemoModel.component(for: "ping")))
        setCompact(PTBaseNavControl(rootViewController: makeSidebar(compactMode: true)))
        setInspector(inspector)
    }

    private func makeSidebar(compactMode: Bool) -> PT5_61SplitDemoSidebarViewController {
        let sidebar = PT5_61SplitDemoSidebarViewController(compactMode: compactMode)
        sidebar.didSelectCategory = { [weak self] categoryID in
            self?.showCategory(categoryID, compactMode: compactMode)
        }
        sidebar.didRequestRouter = { [weak self] in
            self?.openRouterDetail()
        }
        sidebar.didRequestClose = { [weak self] in
            self?.dismiss(animated: true)
        }
        return sidebar
    }

    private func makeComponentList(categoryID: String, compactMode: Bool) -> PT5_61SplitDemoComponentListViewController {
        let list = PT5_61SplitDemoComponentListViewController(categoryID: categoryID)
        list.didSelectComponent = { [weak self] componentID in
            self?.showComponent(componentID, compactMode: compactMode)
        }
        return list
    }

    private func showCategory(_ categoryID: String, compactMode: Bool) {
        let list = makeComponentList(categoryID: categoryID, compactMode: compactMode)
        if compactMode || isCompactPresentation {
            show(list, target: .automatic)
        } else {
            setSupplementary(list)
        }
        inspector.refreshState()
    }

    private func showComponent(_ componentID: String, compactMode: Bool) {
        let detail = PT5_61SplitDemoDetailViewController(component: PT5_61SplitDemoModel.component(for: componentID))
        if compactMode || isCompactPresentation {
            show(detail, target: .automatic)
        } else {
            setSecondary(detail)
        }
        inspector.refreshState()
    }

    private func openRouterDetail() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            // English: The registered Example route uses the same .push path as an application Router call.
            // Español: La ruta registrada de Example usa el mismo camino .push que una llamada Router real.
            // 中文：Example 已注册路由，使用与业务 Router 相同的 .push 路径。
            let route = PTRouter.generate("ptools://routerTest", jumpType: .push)
            _ = await PTRouter.openURL(route)
            inspector.refreshState()
        }
    }

    private func configureInspector() {
        inspector.stateProvider = { [weak self] in
            self?.runtimeSummary() ?? "容器已释放"
        }
        inspector.saveStateAction = { [weak self] in
            self?.savedState = self?.makeState(identifierFor: PT5_61SplitDemoModel.identifier(for:))
        }
        inspector.resetStateAction = { [weak self] in
            self?.savedState = nil
            self?.installDemoColumns()
        }
        inspector.restoreStateAction = { [weak self] in
            guard let self, let savedState = self.savedState else { return }
            self.restore(state: savedState, resolve: PT5_61SplitDemoModel.resolve(identifier:))
        }
        inspector.routerAction = { [weak self] in
            self?.openRouterDetail()
        }
        inspector.refreshState()
    }

    private func runtimeSummary() -> String {
        let state = makeState(identifierFor: PT5_61SplitDemoModel.identifier(for:))
        let inspectorMode: String
        switch configuration.inspectorMode {
        case .sheet:
            inspectorMode = "Compatibility Inspector Sheet"
        case .automatic, .nativeWhenAvailable:
            if #available(iOS 26.0, *) {
                inspectorMode = "Native Inspector"
            } else {
                inspectorMode = "Compatibility Inspector Sheet"
            }
        }
        return [
            "horizontalSizeClass: \(traitCollection.horizontalSizeClass.rawValue)",
            "isCollapsed: \(isCollapsed)",
            "isCompactPresentation: \(isCompactPresentation)",
            "displayMode: \(String(describing: displayMode))",
            "splitBehavior: \(String(describing: splitBehavior))",
            "visibleControllers: \(viewControllers.count)",
            "primary: \(state.selectedPrimaryIdentifier ?? "-")",
            "supplementary: \(state.selectedSupplementaryIdentifier ?? "-")",
            "secondary: \(state.selectedSecondaryIdentifier ?? "-")",
            "compact: \(state.selectedCompactIdentifier ?? "-")",
            "navigationDepth: \(activeNavigationController?.viewControllers.count ?? 0)",
            "inspector: \(inspectorMode) / visible=\(state.inspectorVisible)"
        ].joined(separator: "\n")
    }
}
