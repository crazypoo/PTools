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
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFusionCell.ID:PTFusionCell.self])
        view.registerSupplementaryView(classs: [PTloadedLibHeader.ID:PTloadedLibHeader.self], kind: UICollectionView.elementKindSectionHeader)
        view.headerInCollection = { kind,collectionView,model,index in
            if let headerID = model.headerID,!headerID.stringIsEmpty(),let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerID, for: index) as? PTloadedLibHeader {
                let headerModel = self.libraries[index.section]
                header.configure(with: headerModel)
                header.onToggle = { [weak self] in
                    self?.viewModel.toggleLibraryExpansion(at: index.section)
                }
                return header
            }
            return nil
        }
        view.customerLayout = { sectionIndex,sectionModel in
            return UICollectionView.waterFallLayout(data: sectionModel.rows,rowCount: 1, itemSpace: 8) { index, obj in
                return 44
            }
        }
        view.cellInCollection = { collection,itemSection,indexPath in
            if let itemRow = itemSection.rows?[indexPath.row],let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFusionCell,let cellModel = itemRow.dataModel as? PTFusionCellModel {
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,itemSection,indexPath in
            let library = self.libraries[indexPath.section]
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
    
    private lazy var titleViewContailer:PTNavTitleContainer = {
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
    
    private lazy var searchBar:PTSearchBar = {
        let view = PTSearchBar()
        view.delegate = self
        return view
    }()
    
    lazy var exportButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(UIImage(.square.andArrowUp), for: .normal)
        view.addActionHandlers(handler: { sender in
            self.exportLibraries()
        })
        view.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return view
    }()

    lazy var backButton:UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        if #available(iOS 26.0, *) {
            button.configuration = UIButton.Configuration.clearGlass()
        }
        button.addActionHandlers { sender in
            self.dismissAnimated()
        }
        button.bounds = CGRect(origin: .zero, size: .init(width: 34, height: 34))
        return button
    }()

    private let viewModel = PTLoadedLibrariesViewModel()
    private var libraries: [PTLoadedLibrary] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(backButton)
        setCustomTitleView(titleViewContailer)
        setCustomRightButtons(buttons: [exportButton], rightPadding: 10)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.addSubviews([segmentedControl,newCollectionView])
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
    }
    
    private func bindViewModel() {
        viewModel.onLoadingStateChanged = { [weak self] index in
            self!.setDataList()
        }
//        viewModel.onStateChanged = { [weak self] libraries in
//            self?.libraries = libraries
//            DispatchQueue.main.async {
//                self?.setDataList()
//            }
//        }
//
//        viewModel.onLibraryUpdated = { [weak self] updatedPath in
//            guard let self = self else { return }
//            if let row = self.libraries.firstIndex(where: { $0.path == updatedPath }) {
//                DispatchQueue.main.async {
//                    if self.libraries[row].classes.count > 0 {
//                        if self.libraries[row].isExpanded {
//                            let rows = self.newCollectionView.collectionSectionDatas[row].rows ?? []
//                            self.newCollectionView.deleteRows(rows, from: row)
//                        } else {
//                            let rows = self.libraries[row].classes.map {
//                                let model = PTFusionCellModel()
//                                model.name = $0
//                                let row = PTRows(ID: PTFusionCell.ID,dataModel: model)
//                                return row
//                            }
//                            self.newCollectionView.insertRows(rows, section: row)
//                        }
//                    }
//                }
//            }
//        }
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
        newCollectionView.clearAllData { cView in
            self.setDataList()
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
                    let row = PTRows(ID: PTFusionCell.ID,dataModel: model)
                    return row
                }
            }
            
            let nameHeight = UIView.sizeFor(string: value.name, font: .appfont(size: 18),width: screenWidth).height
            let descString = value.path + "\nSize: " + value.size + " Address: " + value.address
            let descHeight = UIView.sizeFor(string: descString, font: .appfont(size: 14),width: screenWidth).height
            let totalHeight = nameHeight + descHeight + 17

            let section = PTSection(headerID: PTloadedLibHeader.ID,headerHeight: totalHeight,rows: rows)
            return section
        }
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
}

extension PTLoadedLibsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.textField?.resignFirstResponder()
        self.viewModel.searchLibraries(with: searchBar.textField?.text ?? "")
        newCollectionView.clearAllData { cView in
            self.setDataList()
        }
    }
}

class PTClassExplorerViewController: PTBaseViewController {
    
    // MARK: - Properties
    
    var libraryName: String = ""
    var classNames: String = ""
    var viewModel: PTClassExplorerViewModel = PTClassExplorerViewModel(className: "")
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)
        return tableView
    }()
    
    private lazy var createInstanceButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(.plus), for: .normal)
        button.addActionHandlers(handler: { sender in
            self.createInstanceTapped()
        })
        return button
    }()
    
    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.font = PTAppBaseConfig.share.navTitleFont
        view.textAlignment = .center
        return view
    }()
    
    // MARK: - Initialization
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.loadClassInfo()
    }
    
    // MARK: - Setup
    
    private func setup() {
        titleLabel.text = classNames
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        button.addActionHandlers { sender in
            self.navigationController?.popViewController()
        }
        view.addSubviews([button,titleLabel,tableView,createInstanceButton])
        
        button.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset((self.sheetViewController?.options.pullBarHeight ?? 0) + 10)
        }
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(button)
        }
        
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(button.snp.bottom).offset(5)
        }
        
        createInstanceButton.snp.makeConstraints { make in
            make.size.top.equalTo(button)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
        
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
