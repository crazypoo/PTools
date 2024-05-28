//
//  PTNetworkWatcherViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SafeSFSymbols

class PTNetworkWatcherViewController: PTBaseViewController {

    private let viewModel = PTNetworkViewModel()

    lazy var fakeNav:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var searchBar:PTSearchBar = {
        let view = PTSearchBar()
        view.delegate = self
        view.searchBarOutViewColor = .clear
        view.searchTextFieldBackgroundColor = .lightGray
        view.searchBarTextFieldCornerRadius = 0
        view.searchBarTextFieldBorderWidth = 0
        view.searchPlaceholderColor = .gray
        view.searchPlaceholder = "Search"
        view.viewCorner(radius: 17)
        return view
    }()
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 64
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { collection,itemSection,indexPath in
            let itemRow = itemSection.rows[indexPath.row]
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTNetworkWatcherCell
            cell.cellModel = (itemRow.dataModel as! PTHttpModel)
            return cell
        }
        view.collectionDidSelect = { collection,model,indexPath in
            let itemRow = model.rows[indexPath.row]
            let vc = PTNetworkWatcherDetailViewController(viewModel: (itemRow.dataModel as! PTHttpModel))
            self.navigationController?.pushViewController(vc)
        }
        return view
    }()

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

        view.addSubviews([fakeNav,newCollectionView])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(20)
            make.height.equalTo(CGFloat.kNavBarHeight + 53)
        }
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)

        let deleteButton = UIButton(type: .custom)
        deleteButton.setImage(UIImage(.trash), for: .normal)

        fakeNav.addSubviews([button,searchBar,deleteButton])
        button.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.top.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        button.addActionHandlers { sender in
            self.dismissAnimated()
        }

        deleteButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.top.equalToSuperview().inset(5)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        deleteButton.addActionHandlers { sender in
            self.viewModel.handleClearAction()
            self.loadListModel()
        }
        
        searchBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().inset(5)
        }
        
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
        
        loadListModel()
        setup()
    }
    
    func loadListModel() {
        var sections = [PTSection]()
        
        var rows = [PTRows]()
        viewModel.models.enumerated().forEach { index,value in
            let row = PTRows(cls: PTNetworkWatcherCell.self, ID: PTNetworkWatcherCell.ID, dataModel: value)
            rows.append(row)
        }
        let section = PTSection(rows: rows)
        sections.append(section)
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
    
    func setup() {
        observers()
    }
    
    func observers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "reloadHttp_PooTools"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let success = notification.object as? Bool {
                self?.reloadHttp(
                    needScrollToEnd: self?.viewModel.reachEnd ?? true,
                    success: success
                )
            }
        }
    }
    
    func reloadHttp(needScrollToEnd: Bool = false, success: Bool = true) {
        guard viewModel.reloadDataFinish else { return }

        viewModel.applyFilter()
        loadListModel()

        if needScrollToEnd {
            scrollToBottom()
        }
    }

    private func scrollToBottom() {
        if viewModel.models.count > 0 {
            newCollectionView.contentCollectionView.scrollToBottom()
        }
    }
}

extension PTNetworkWatcherViewController:UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.networkSearchWord = searchText
        viewModel.applyFilter()
        loadListModel()
    }
}
