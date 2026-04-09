//
//  PTLoadedLibsViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 6/4/25.
//  Copyright © 2025 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols

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
                
                // 修复 1：使用 viewModel.filteredLibraries 作为数据源
                let headerModel = self.viewModel.filteredLibraries[index.section]
                header.configure(with: headerModel)
                header.onToggle = { [weak self] in
                    self?.viewModel.toggleLibraryExpansion(at: index.section)
                    // 展开/收起由于没有异步网络请求，本地直接刷新即可
                    self?.setDataList()
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
            // 修复 1：使用 viewModel.filteredLibraries 作为数据源
            let library = self.viewModel.filteredLibraries[indexPath.section]
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
        searchBar.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.snp.makeConstraints { make in
            make.width.equalTo(CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 4 - 88)
            make.height.equalTo(32)
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
    
    // 修复 1：删除了多余的 private var libraries: [PTLoadedLibrary] = []
    
    open override func preferredNavigationBarStyle() -> PTNavigationBarStyle {
        return .solid(.clear)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        
        // 修复 2：加载库后，必须调用一次 setDataList 以渲染初始 UI
        viewModel.loadLibraries()
        setDataList()
    }
    
    private func bindViewModel() {
        // 清理了无用的注释代码，保留必要的异步加载回调
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
            let descString = value.path + "\nSize: " + value.size + " Address: " + value.address
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
        searchBar.textField?.resignFirstResponder()
        self.viewModel.searchLibraries(with: searchBar.textField?.text ?? "")
        newCollectionView.clearAllData { [weak self] cView in
            self?.setDataList()
        }
    }
    
    // 优化 4：实现边打字边过滤的实时搜索体验
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
    
    private let cellIdentifier = "ClassExplorerCell" // 优化 5：规范化重用标识符
    
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
    
    private lazy var createInstanceButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(.plus), for: .normal)
        button.addActionHandlers(handler: { [weak self] sender in
            self?.createInstanceTapped()
        })
        button.bounds = CGRectMake(0, 0, 34, 34)
        return button
    }()
    
    private lazy var backButton:UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        button.addActionHandlers { [weak self] sender in
//            self?.navigationController?.popViewController()
        }
        return button
    }()
        
    // MARK: - Initialization
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    init(libraryName: String, className: String) {
        self.libraryName = libraryName
        self.classNames = className
        self.viewModel = PTClassExplorerViewModel(className: className)
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setCustomBackButtonView(backButton)
        setCustomRightButtons(buttons: [createInstanceButton], buttonSpacing: 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.loadClassInfo()
        tableView.reloadData() // 确保数据加载后刷新表格
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
