//
//  PTLoadedLibsViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/4/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
#if SWIFT_PACKAGE
import PToolsSymbols
#endif

enum FileSharingManager {
    static func generateFileAndShare(text: String, fileName: String) {
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(fileName).txt")

        do {
            try text.write(to: tempURL, atomically: true, encoding: .utf8)
            Task { @MainActor in
                share(tempURL)
            }
        } catch {
            PTNSLogConsole("Error: \(error.localizedDescription)")
        }
    }

    @MainActor
    static func share(_ tempURL: URL) {
        let activity = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        guard let controller = PTUtils.getTopViewController() else { return }

        if let popover = activity.popoverPresentationController {
            popover.sourceView = controller.view
            popover.permittedArrowDirections = .up
        }

        controller.present(activity, animated: true, completion: nil)
    }
}

class PTLoadedLibsViewController: PTBaseViewController {
    
    lazy var newCollectionView: PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.registerHeaderIdsNClasss(ids: [PTloadedLibHeader.ID], viewClass: PTloadedLibHeader.self, kind: UICollectionView.elementKindSectionHeader)
        view.headerInCollection = { [weak self] kind, collectionView, model, index in
            guard let self = self else { return nil }
            if let headerID = model.headerReuseID, !headerID.stringIsEmpty(),
               let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerID, for: index) as? PTloadedLibHeader {
                
                guard self.viewModel.filteredLibraries.indices.contains(index.section) else { return nil }
                let headerModel = self.viewModel.filteredLibraries[index.section]
                header.configure(with: headerModel)
                let headerID = headerModel.id
                header.onToggle = { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.viewModel.toggleLibraryExpansion(id: headerID)
                    }
                }
                return header
            }
            return nil
        }
        view.customerLayout = { sectionIndex, sectionModel in
            return UICollectionView.waterFallLayout(data: sectionModel.rows, rowCount: 1, itemSpace: 8) { index, obj in
                return 44
            }
        }
        view.cellInCollection = { collection, itemSection, indexPath in
            if let itemRow = itemSection.rows?[indexPath.row],
               let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.reuseID, for: indexPath) as? PTFusionCell,
               let cellModel = itemRow.dataModel as? PTFusionCellModel {
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { [weak self] collection, itemSection, indexPath in
            guard let self = self else { return }
            guard self.viewModel.filteredLibraries.indices.contains(indexPath.section) else { return }
            let library = self.viewModel.filteredLibraries[indexPath.section]
            guard library.classes.indices.contains(indexPath.row) else { return }
            let className = library.classes[indexPath.row]
            
            let classExplorer = PTClassExplorerViewController(libraryName: library.name, className: className)
            self.navigationController?.pushViewController(classExplorer, animated: true)
        }
        return view
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All", "Public", "Private"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var titleViewContailer: PTNavTitleContainer = {
        let view = PTNavTitleContainer()
        view.addSubviews([searchBar])
        view.bounds = .init(origin: .zero, size: .init(width: (CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 4 - 88), height: 32))
        searchBar.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()
    
    private lazy var searchBar: PTSearchBar = {
        let view = PTSearchBar()
        view.delegate = self
        return view
    }()
    
    lazy var exportButton: UIButton = {
        let view = baseButtonCreate(image: UIImage(.square.andArrowUp))
        view.addActionHandlers(handler: { [weak self] sender in
            self?.exportLibraries()
        })
        return view
    }()

    lazy var backButton: UIButton = {
        let button = baseButtonCreate(image: UIImage(.arrow.uturnLeftCircle))
        button.addActionHandlers { [weak self] sender in
            self?.dismissAnimated()
        }
        return button
    }()

    private let viewModel = PTLoadedLibrariesViewModel()
    private var hasAppeared = false
    
    open override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if hasAppeared {
            viewModel.refreshLibraries()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
        setCustomBackButtonView(backButton)
        setCustomTitleView(titleViewContailer)
        setCustomRightButtons(buttons: [exportButton])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([segmentedControl, newCollectionView])
        segmentedControl.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(44)
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
        }
        newCollectionView.snp.makeConstraints { make in
            make.top.equalTo(self.segmentedControl.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
        
        bindViewModel()
        
        viewModel.loadLibraries()
        setDataList()
    }
    
    private func bindViewModel() {
        viewModel.onLoadingStateChanged = { [weak self] index in
            guard let self = self else { return }
            self.setDataList()
        }
    }
    
    @objc private func filterChanged() {
        let filter: PTLoadedLibrariesViewModel.LibraryFilter
        switch segmentedControl.selectedSegmentIndex {
        case 0: filter = .all
        case 1: filter = .public
        case 2: filter = .private
        default: filter = .all
        }
        viewModel.filterLibraries(by: filter)
        newCollectionView.clearAllData { [weak self] cView in
            self?.setDataList()
        }
    }
    
    @objc private func exportLibraries() {
        let report = viewModel.generateReport()
        FileSharingManager.generateFileAndShare(
            text: report,
            fileName: "loaded_libraries_\(Date().timeIntervalSince1970)"
        )
    }
    
    func setDataList() {
        var sections = [PTSection]()
        
        let screenWidth = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2 - 24 - 4.5
        sections = viewModel.filteredLibraries.map { value in
            var rows = [PTRows]()
            if value.isExpanded {
                rows = value.classes.map {
                    let model = PTFusionCellModel()
                    model.name = $0
                    let row = PTRows(dataModel: model)
                    row.cellClass = PTFusionCell.self
                    return row
                }
            }
            
            let nameHeight = UIView.sizeFor(string: value.name, font: .appfont(size: 18), width: screenWidth).height
            let descString = value.summaryDescription
            let descHeight = UIView.sizeFor(string: descString, font: .appfont(size: 14), width: screenWidth).height
            let totalHeight = nameHeight + descHeight + 17

            let section = PTSection(headerID: PTloadedLibHeader.ID,headerHeight: totalHeight, rows: rows)
            section.headerClass = PTloadedLibHeader.self
            return section
        }
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
}

extension PTLoadedLibsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.searchTextField.resignFirstResponder()
        self.viewModel.searchLibraries(with: searchBar.searchTextField.text ?? "")
        newCollectionView.clearAllData { [weak self] cView in
            self?.setDataList()
        }
    }
    
    // English: Apply the filter while the user is typing for immediate feedback.
    // Español: Aplica el filtro mientras el usuario escribe para ofrecer respuesta inmediata.
    // 中文：输入过程中实时应用筛选，及时反馈搜索结果。
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.viewModel.searchLibraries(with: searchText)
        newCollectionView.clearAllData { [weak self] cView in
            self?.setDataList()
        }
    }
}

class PTClassExplorerViewController: PTBaseViewController {
    
    // MARK: - Properties
    
    var libraryName: String = ""
    var classNames: String = ""
    var viewModel: PTClassExplorerViewModel
    
    // English: Keep one stable reuse identifier for every class detail row.
    // Español: Mantiene un identificador de reutilización estable para cada fila de detalle de clase.
    // 中文：为所有类详情行使用稳定的复用标识符。
    private let cellIdentifier = "ClassExplorerCell"
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        return tableView
    }()
    
    private lazy var createInstanceButton: PTBaseButton = {
        let button = PTBaseButton(type: .system)
        button.setImage(UIImage(.plus), for: .normal)
        button.addActionHandlers(handler: { [weak self] sender in
            self?.createInstanceTapped()
        })
        button.bounds = CGRectMake(0, 0, PTAppBaseConfig.share.navBarButtonSize, PTAppBaseConfig.share.navBarButtonSize)
        return button
    }()
    
    private lazy var backButton:PTBaseButton = {
        let button = PTBaseButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        button.addActionHandlers { [weak self] sender in
            self?.navigationController?.popViewController(animated: true)
        }
        return button
    }()
        
    init(libraryName: String, className: String) {
        self.libraryName = libraryName
        self.classNames = className
        self.viewModel = PTClassExplorerViewModel(className: className)
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        self.libraryName = ""
        self.classNames = ""
        self.viewModel = PTClassExplorerViewModel(className: "")
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
        
    // MARK: - Initialization
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(backButton)
        setCustomRightButtons(buttons: [createInstanceButton], buttonSpacing: 0)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.loadClassInfo()
        tableView.reloadData()
    }
    
    // MARK: - Setup
    
    private func setup() {
        
        pt_Title = classNames
        view.addSubviews([tableView])

        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
        }

        createInstanceButton.isHidden = !viewModel.canCreateInstance
        createInstanceButton.isUserInteractionEnabled = viewModel.canCreateInstance
    }
    
    // MARK: - Actions
    
    @objc private func createInstanceTapped() {
        viewModel.createInstance()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension PTClassExplorerViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        PTClassExplorerViewModel.Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = PTClassExplorerViewModel.Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .classInfo:
            return viewModel.classInfo.count
        case .properties:
            return viewModel.properties.count
        case .methods:
            return viewModel.methods.count
        case .instanceState:
            return viewModel.instanceProperties.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        guard let sectionType = PTClassExplorerViewModel.Section(rawValue: indexPath.section) else {
            return cell
        }
        
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        cell.textLabel?.font = .systemFont(ofSize: 14)
        cell.textLabel?.numberOfLines = 0
        
        switch sectionType {
        case .classInfo:
            let info = viewModel.classInfo[indexPath.row]
            cell.textLabel?.text = "\(info.key): \(info.value)"
            
        case .properties:
            let property = viewModel.properties[indexPath.row]
            cell.textLabel?.text = property.description
            
        case .methods:
            let method = viewModel.methods[indexPath.row]
            cell.textLabel?.text = method.description
            
        case .instanceState:
            let property = viewModel.instanceProperties[indexPath.row]
            cell.textLabel?.text = "\(property.name): \(property.value)"
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = PTClassExplorerViewModel.Section(rawValue: section) else { return nil }
        
        switch sectionType {
        case .classInfo:
            return viewModel.classInfo.isEmpty ? nil : "Class Information"
        case .properties:
            return viewModel.properties.isEmpty ? nil : "Properties (\(viewModel.properties.count))"
        case .methods:
            return viewModel.methods.isEmpty ? nil : "Methods (\(viewModel.methods.count))"
        case .instanceState:
            return viewModel.instanceProperties.isEmpty ? nil : "Instance State"
        }
    }
}

// MARK: - UITableViewDelegate

extension PTClassExplorerViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
