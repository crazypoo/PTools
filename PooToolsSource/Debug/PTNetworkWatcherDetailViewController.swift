//
//  PTNetworkWatcherDetailViewController.swift
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

class PTNetworkWatcherDetailViewController: PTBaseViewController {

    fileprivate var viewModel:PTHttpModel!
    private var infos: [Config]!
    private var filteredInfos: [Config] = []
    private var currentInfos: [Config] {
        return searchIsActivity ? filteredInfos : infos
    }
    
    fileprivate var searchIsActivity:Bool = false
    
    lazy var fakeNav:UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var searchBar:PTSearchBar = {
        let view = PTSearchBar()
        view.searchPlaceholder = "Search"
        view.delegate = self
        return view
    }()

    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.headerInCollection = { kind,collectionView,model,index in
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as! PTFusionHeader
            header.sectionModel = (model.headerDataModel as! PTFusionCellModel)
            return header
        }
        view.customerLayout = { sectionIndex,sectionModel in
            let headerModel = sectionModel.headerDataModel as! PTFusionCellModel
            
            if headerModel.name == "Simple info" {
                return UICollectionView.girdCollectionLayout(data: sectionModel.rows, groupWidth: CGFloat.kSCREEN_WIDTH, itemHeight: 64,cellRowCount: 1,originalX: 0)
            } else {
                var bannerGroupSize : NSCollectionLayoutSize
                var customers = [NSCollectionLayoutGroupCustomItem]()
                var groupH:CGFloat = 0
                let screenW:CGFloat = CGFloat.kSCREEN_WIDTH
                let cellModel = self.currentInfos[sectionIndex - 1]
                var cellHeight:CGFloat = UIView.sizeFor(string: cellModel.description, font: .appfont(size: 12),width: screenW - PTAppBaseConfig.share.defaultViewSpace * 2).height + 10
                if cellHeight < 64 {
                    cellHeight = 64
                }
                
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: 0, y: groupH, width: screenW, height: cellHeight), zIndex: 1000)
                customers.append(customItem)
                groupH = cellHeight

                bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenW), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
                return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                    customers
                })
            }
        }
        view.cellInCollection = { collection,itemSection,indexPath in
            let itemRow = itemSection.rows[indexPath.row]
            let headerModel = itemSection.headerDataModel as! PTFusionCellModel
            if headerModel.name == "Simple info" {
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTNetworkWatcherCell
                cell.cellModel = (itemRow.dataModel as! PTHttpModel)
                return cell
            } else {
                let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTNetworkWatcherDetailCell
                let cellModel = self.currentInfos[indexPath.section - 1]
                cell.setup(cellModel.description, self.searchBar.text)
                return cell
            }
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

    init(viewModel: PTHttpModel!) {
        self.viewModel = viewModel
        self.infos = .init(model: viewModel)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([fakeNav,newCollectionView])
        fakeNav.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(20)
            make.height.equalTo(CGFloat.kNavBarHeight * 2)
        }
        
        let button = UIButton(type: .custom)
        button.backgroundColor = .randomColor
        
        let deleteButton = UIButton(type: .custom)
        deleteButton.backgroundColor = .randomColor

        fakeNav.addSubviews([button,searchBar,deleteButton])
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
        }
        
        searchBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(34)
            make.bottom.equalToSuperview().inset(5)
        }
        
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
        
        loadListModel()
    }
    
    func loadListModel() {
        var sections = [PTSection]()
        
        let simpleData_row = PTRows(cls: PTNetworkWatcherCell.self, ID: PTNetworkWatcherCell.ID, dataModel: viewModel)
        let headerModel_simple = PTFusionCellModel()
        headerModel_simple.name = "Simple info"
        let section = PTSection(headerCls:PTFusionHeader.self,headerID:PTFusionHeader.ID,headerHeight: 34 ,rows: [simpleData_row],headerDataModel: headerModel_simple)
        sections.append(section)
        
        if currentInfos.count > 0 {
            currentInfos.enumerated().forEach { index,value in
                let headerModel = PTFusionCellModel()
                headerModel.name = value.title
                let row = PTRows(cls: PTNetworkWatcherDetailCell.self, ID: PTNetworkWatcherDetailCell.ID)
                let section_detail = PTSection(headerCls:PTFusionHeader.self,headerID:PTFusionHeader.ID,headerHeight: 34 ,rows: [row],headerDataModel: headerModel)
                sections.append(section_detail)
            }
        }
        
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
}

extension PTNetworkWatcherDetailViewController {
    struct Config {
        let title: String
        let description: String
    }
}

extension [PTNetworkWatcherDetailViewController.Config] {
    init(model: PTHttpModel) {
        self = [
            .init(
                title: "TOTAL TIME",
                description: model.totalDuration ?? "No data"
            ),
            .init(
                title: "REQUEST HEADER",
                description: model.requestHeaderFields?.formattedString() ?? "No data"
            ),
            .init(
                title: "REQUEST",
                description: model.requestData?.formattedString() ?? "No data"
            ),
            .init(
                title: "RESPONSE HEADER",
                description: model.responseHeaderFields?.formattedString() ?? "No data"
            ),
            .init(
                title: "RESPONSE",
                description: model.responseData?.formattedString() ?? "No data"
            ),
            .init(
                title: "RESPONSE SIZE",
                description: model.responseData?.formattedSize() ?? "No data"
            ),
            .init(
                title: "MIME TYPE",
                description: model.mineType ?? "No data"
            )
        ]
    }
}

extension PTNetworkWatcherDetailViewController:UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchIsActivity = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchIsActivity = false
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredInfos = searchText.isEmpty ? infos : infos.filter { $0.description.localizedCaseInsensitiveContains(searchText) }
        newCollectionView.clearAllData { cView in
            self.loadListModel()
        }
    }
}
