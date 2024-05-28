//
//  PTLeakListViewController.swift
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

class PTLeakListViewController: PTBaseViewController {

    var viewModel = PTLeakViewModel()
    
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
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
            return cell
        }
        view.collectionDidSelect = { collection,model,indexPath in            
            let vc = PTDebugSnapshotViewController(snapshotImage: self.viewModel.filteredInfo[indexPath.row].screenshot ?? UIImage())
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
        
        let shareButton = UIButton(type: .custom)
        shareButton.setImage(UIImage(.square.andArrowUp), for: .normal)

        fakeNav.addSubviews([button,searchBar,deleteButton,shareButton])
        button.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.top.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        button.addActionHandlers { sender in
            self.navigationController?.popViewController()
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
        
        shareButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.top.equalToSuperview().inset(5)
            make.right.equalTo(deleteButton.snp.left).offset(-7.5)
        }
        shareButton.addActionHandlers { sender in
            let allLeaks = PTPerformanceLeakDetector.leaks.reduce("") { $0 + "\n\n\($1.symbol)\($1.details)" }
            PTDebugShareManager.generateFileAndShare(text: allLeaks, fileName: "leaks")
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
        
        viewModel.applyFilter()
        loadListModel()
    }
    
    func loadListModel() {
        var sections = [PTSection]()
        
        var rows = [PTRows]()
        viewModel.filteredInfo.enumerated().forEach { index,value in
            let cellModel = PTFusionCellModel()
            cellModel.name = "\(value.symbol)\(value.details)"
            cellModel.accessoryType = .DisclosureIndicator
            cellModel.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
            let row = PTRows(cls: PTFusionCell.self, ID: PTFusionCell.ID, dataModel: cellModel)
            rows.append(row)
        }
        let section = PTSection(rows: rows)
        sections.append(section)
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
}

extension PTLeakListViewController:UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.leakSearchWord = searchText
        viewModel.applyFilter()
        loadListModel()
    }
}
