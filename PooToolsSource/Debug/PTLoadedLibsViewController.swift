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
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SafeSFSymbols

enum FileSharingManager {
    static func generateFileAndShare(text: String, fileName: String) {
        let tempURL = URL(
            fileURLWithPath: NSTemporaryDirectory()
        ).appendingPathComponent("\(fileName).txt")

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
        let activity = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        guard let controller = PTUtils.getTopViewController() else { return }

        if let popover = activity.popoverPresentationController {
            popover.sourceView = controller.view
            popover.permittedArrowDirections = .up
        }

        controller.present(activity, animated: true, completion: nil)
    }
}

class PTLoadedLibsViewController: PTBaseViewController {

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .black
        tableView.separatorColor = .darkGray
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: .cell)
        return tableView
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All", "Public", "Private"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
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
        return view
    }()

    private let viewModel = PTLoadedLibrariesViewModel()
    private var libraries: [PTLoadedLibrary] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#else
        navigationController?.navigationBar.isHidden = true
#endif
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.addSubviews([exportButton,searchBar,segmentedControl,tableView])
        exportButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset((self.sheetViewController?.options.pullBarHeight ?? 0) + 10)
        }
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(self.exportButton.snp.bottom).offset(5)
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(44)
        }
        segmentedControl.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(44)
            make.top.equalTo(self.searchBar.snp.bottom).offset(10)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(self.segmentedControl.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
        
        bindViewModel()
        viewModel.loadLibraries()
    }
    
    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] libraries in
            self?.libraries = libraries
            DispatchQueue.main.async {
                self?.tableView.reloadData()
            }
        }

        viewModel.onLibraryUpdated = { [weak self] updatedPath in
            guard let self = self else { return }
            if let row = self.libraries.firstIndex(where: { $0.path == updatedPath }) {
                DispatchQueue.main.async {
                    self.tableView.reloadSections(IndexSet([row]), with: .none)
                }
            }
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
        tableView.reloadData()
    }
    
    @objc private func exportLibraries() {
        let report = viewModel.generateReport()
        FileSharingManager.generateFileAndShare(
            text: report,
            fileName: "loaded_libraries_\(Date().timeIntervalSince1970)"
        )
    }
}

// MARK: - UITableViewDataSource
extension PTLoadedLibsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        libraries.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let library = libraries[section]
        return library.isExpanded ? library.classes.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .cell, for: indexPath)
        let library = libraries[indexPath.section]
        let className = library.classes[indexPath.row]
        
        cell.textLabel?.text = className
        cell.textLabel?.textColor = .white
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let library = libraries[section]
        
        let headerView = PTLibraryHeaderView()
        headerView.configure(with: library)
        headerView.onToggle = { [weak self] in
            self?.viewModel.toggleLibraryExpansion(path: library.path)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let screenWidth = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 4 - 24 - 4.5
        let value = libraries[section]
        let nameHeight = UIView.sizeFor(string: value.name, font: .appfont(size: 18),width: screenWidth).height
        let descString = value.path + "\nSize: " + value.size + " Address: " + value.address
        let descHeight = UIView.sizeFor(string: descString, font: .appfont(size: 14),width: screenWidth).height
        let totalHeight = nameHeight + descHeight + 17
        return totalHeight
    }
}

// MARK: - UITableViewDelegate

extension PTLoadedLibsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let library = libraries[indexPath.section]
        let className = library.classes[indexPath.row]
        
        let classExplorer = PTClassExplorerViewController(
            libraryName: library.name,
            className: className
        )
        navigationController?.pushViewController(classExplorer, animated: true)
    }
}

// MARK: - UISearchResultsUpdating

extension PTLoadedLibsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.textField?.resignFirstResponder()
        viewModel.searchLibraries(with: searchBar.textField?.text ?? "")
        tableView.reloadData()
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
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_hideBaseNavBar = true
#else
        navigationController?.navigationBar.isHidden = true
#endif
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
