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

    private lazy var titleViewContailer:PTNavTitleContainer = {
        let view = PTNavTitleContainer()
        view.addSubviews([searchBar])
        searchBar.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        view.snp.makeConstraints { make in
            make.width.equalTo(CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 4 - 132)
            make.height.equalTo(32)
        }
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

    lazy var backButton:UIButton = {
        let button = baseButtonCreate(image: UIImage(.arrow.uturnLeftCircle))
        button.addActionHandlers { sender in
            self.navigationController?.popViewController()
        }
        return button
    }()
    
    lazy var deleteButton:UIButton = {
        let deleteButton = baseButtonCreate(image: UIImage(.trash))
        deleteButton.addActionHandlers { sender in
            self.viewModel.handleClearAction()
            self.loadListModel()
        }
        return deleteButton
    }()

    lazy var shareButton:UIButton = {
        let shareButton = baseButtonCreate(image: UIImage(.square.andArrowUp))
        shareButton.addActionHandlers { sender in
            let allLeaks = PTPerformanceLeakDetector.leaks.reduce("") { $0 + "\n\n\($1.symbol)\($1.details)" }
            PTDebugShareManager.generateFileAndShare(text: allLeaks, fileName: "leaks")
        }
        return shareButton
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(backButton)
        setCustomRightButtons(buttons: [deleteButton,shareButton], rightPadding: 10)
        setCustomTitleView(titleViewContailer)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let collectionInset:CGFloat = CGFloat.kTabbarSaveAreaHeight
        let collectionInset_Top:CGFloat = CGFloat.kNavBarHeight_Total
        
        newCollectionView.contentCollectionView.contentInsetAdjustmentBehavior = .never
        newCollectionView.contentCollectionView.contentInset.top = collectionInset_Top
        newCollectionView.contentCollectionView.contentInset.bottom = collectionInset
        newCollectionView.contentCollectionView.verticalScrollIndicatorInsets.bottom = collectionInset

        view.addSubviews([newCollectionView])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
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
