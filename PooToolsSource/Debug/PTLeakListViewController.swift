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
import SafeSFSymbols

class PTLeakListViewController: PTBaseViewController {

    var viewModel = PTLeakViewModel()
    
    lazy var fakeNav:PTNavBar = {
        let view = PTNavBar()
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
        view.bounds = CGRect(origin: .zero, size: CGSize(width: 320, height: 34))
        return view
    }()

    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 64
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFusionCell.ID:PTFusionCell.self])
        view.cellInCollection = { collection,itemSection,indexPath in
            if let itemRow = itemSection.rows?[indexPath.row],let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFusionCell,let cellModel = itemRow.dataModel as? PTFusionCellModel {
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,model,indexPath in            
            let vc = PTDebugSnapshotViewController(snapshotImage: self.viewModel.filteredInfo[indexPath.row].screenshot ?? UIImage())
            self.navigationController?.pushViewController(vc)
        }
        return view
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let collectionInset:CGFloat = CGFloat.kTabbarSaveAreaHeight
        let collectionInset_Top:CGFloat = CGFloat.kNavBarHeight
        
        newCollectionView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        newCollectionView.contentCollectionView.contentInset.top = collectionInset_Top
        newCollectionView.contentCollectionView.contentInset.bottom = collectionInset
        newCollectionView.contentCollectionView.verticalScrollIndicatorInsets.bottom = collectionInset

        view.addSubviews([newCollectionView,fakeNav])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.sheetViewController?.options.pullBarHeight ?? 0)
        }
        
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.newCollectionView)
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        if #available(iOS 26.0, *) {
            button.configuration = UIButton.Configuration.clearGlass()
        }

        let deleteButton = UIButton(type: .custom)
        deleteButton.setImage(UIImage(.trash), for: .normal)
        if #available(iOS 26.0, *) {
            deleteButton.configuration = UIButton.Configuration.clearGlass()
        }

        let shareButton = UIButton(type: .custom)
        shareButton.setImage(UIImage(.square.andArrowUp), for: .normal)
        if #available(iOS 26.0, *) {
            shareButton.configuration = UIButton.Configuration.clearGlass()
        }

        fakeNav.setLeftButtons([button])
        fakeNav.titleView = searchBar
        fakeNav.setRightButtons([deleteButton,shareButton])
        button.addActionHandlers { sender in
            self.navigationController?.popViewController()
        }

        deleteButton.addActionHandlers { sender in
            self.viewModel.handleClearAction()
            self.loadListModel()
        }
        shareButton.addActionHandlers { sender in
            let allLeaks = PTPerformanceLeakDetector.leaks.reduce("") { $0 + "\n\n\($1.symbol)\($1.details)" }
            PTDebugShareManager.generateFileAndShare(text: allLeaks, fileName: "leaks")
        }
        
        viewModel.applyFilter()
        loadListModel()
    }
    
    func loadListModel() {
        var sections = [PTSection]()
        
        let rows = viewModel.filteredInfo.map { value in
            let cellModel = PTFusionCellModel()
            cellModel.name = "\(value.symbol)\(value.details)"
            cellModel.accessoryType = .DisclosureIndicator
            cellModel.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
            let row = PTRows(ID: PTFusionCell.ID, dataModel: cellModel)
            return row
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
