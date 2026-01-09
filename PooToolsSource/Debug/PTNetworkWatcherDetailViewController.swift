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
import SafeSFSymbols

class PTNetworkWatcherDetailViewController: PTBaseViewController {

    fileprivate var viewModel:PTHttpModel!
    private var infos: [Config]!
    private var filteredInfos: [Config] = []
    private var currentInfos: [Config] {
        return searchIsActivity ? filteredInfos : infos
    }
    
    fileprivate var searchIsActivity:Bool = false
        
    lazy var searchBar:PTSearchBar = {
        let view = PTSearchBar()
        view.searchBarOutViewColor = .clear
        view.searchTextFieldBackgroundColor = .lightGray
        view.searchBarTextFieldCornerRadius = 0
        view.searchBarTextFieldBorderWidth = 0
        view.searchPlaceholderColor = .gray
        view.searchPlaceholder = "Search"
        view.viewCorner(radius: 17)
        view.bounds = CGRect(origin: .zero, size: CGSizeMake(320, 34))
        return view
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

    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTNetworkWatcherCell.ID:PTNetworkWatcherCell.self,PTNetworkWatcherDetailCell.ID:PTNetworkWatcherDetailCell.self])
        view.registerSupplementaryView(classs: [PTFusionHeader.ID:PTFusionHeader.self], kind: UICollectionView.elementKindSectionHeader)
        
        view.headerInCollection = { kind,collectionView,model,index in
            if let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as? PTFusionHeader,let headerModel = model.headerDataModel as? PTFusionCellModel {
                header.sectionModel = headerModel
                return header
            }
            return nil
        }
        view.customerLayout = { sectionIndex,sectionModel in
            if let headerModel = sectionModel.headerDataModel as? PTFusionCellModel {
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
                    
                    let customItem = NSCollectionLayoutGroupCustomItem(frame: CGRect(x: 0, y: groupH, width: screenW, height: cellHeight), zIndex: 1000)
                    customers.append(customItem)
                    groupH = cellHeight

                    bannerGroupSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.absolute(screenW), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
                    return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                        customers
                    })
                }
            } else {
                return UICollectionView.girdCollectionLayout(data: sectionModel.rows, itemHeight: 0)
            }
        }
        view.cellInCollection = { collection,itemSection,indexPath in
            if let itemRow = itemSection.rows?[indexPath.row],let headerModel = itemSection.headerDataModel as? PTFusionCellModel {
                if headerModel.name == "Simple info",let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTNetworkWatcherCell,let cellModel = itemRow.dataModel as? PTHttpModel {
                    cell.cellModel = cellModel
                    return cell
                } else {
                    if let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTNetworkWatcherDetailCell {
                        let cellModel = self.currentInfos[indexPath.section - 1]
                        cell.setup(cellModel.description, self.searchBar.text)
                        return cell
                    }
                }
            }
            return nil
        }
        view.collectionDidSelect = { collection,model,indexPath in
            if let itemRow = model.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTHttpModel {
                let vc = PTNetworkWatcherDetailViewController(viewModel: cellModel)
                self.navigationController?.pushViewController(vc)
            }
        }
        return view
    }()

    lazy var backButton:UIButton = {
        let button = baseButtonCreate(image: UIImage(.arrow.uturnLeftCircle))
        button.addActionHandlers(handler: { _ in
            self.navigationController?.popViewController()
        })
        return button
    }()

    lazy var shareButton:UIButton = {
        let shareButton = baseButtonCreate(image: UIImage(.square.andArrowUp))
        shareButton.addActionHandlers { sender in
            let logText = self.formatLog(model: self.viewModel)

            var fileName = self.viewModel.url?.path.replacingOccurrences(of: "/", with: "-") ?? "-log"
            fileName.removeFirst()

            PTDebugShareManager.generateFileAndShare(text: logText, fileName: fileName)
        }
        return shareButton
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(backButton)
        setCustomTitleView(titleViewContailer)
        setCustomRightButtons(buttons: [shareButton], rightPadding: 10)
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
                        
        loadListModel()
    }
    
    func loadListModel() {
        var sections = [PTSection]()
        
        let simpleData_row = PTRows(ID: PTNetworkWatcherCell.ID, dataModel: viewModel)
        let headerModel_simple = PTFusionCellModel()
        headerModel_simple.name = "Simple info"
        let section = PTSection(headerID:PTFusionHeader.ID,headerHeight: 34 ,rows: [simpleData_row],headerDataModel: headerModel_simple)
        sections.append(section)
        
        if !currentInfos.isEmpty {
            let sectionInfos = currentInfos.map { value in
                let headerModel = PTFusionCellModel()
                headerModel.name = value.title
                let row = PTRows(ID: PTNetworkWatcherDetailCell.ID)
                let section_detail = PTSection(headerID:PTFusionHeader.ID,headerHeight: 34 ,rows: [row],headerDataModel: headerModel)
                return section_detail
            }
            sections.append(contentsOf: sectionInfos)
        }
        
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
    
    private func formatLog(model: PTHttpModel) -> String {
        let formattedLog = """
        [\(model.method ?? "")] \(model.startTime ?? "") (\(model.statusCode ?? ""))

        ------- URL -------
        \(model.url?.absoluteString ?? "No data")

        ------- REQUEST HEADER -------
        \(model.requestHeaderFields?.formattedString() ?? "No data")

        ------- REQUEST -------
        \(model.requestData?.formattedString() ?? "No data")

        ------- RESPONSE HEADER -------
        \(model.responseHeaderFields?.formattedString() ?? "No data")

        ------- RESPONSE -------
        \(model.responseData?.formattedString() ?? "No data")

        ------- RESPONSE SIZE -------
        \(model.responseData?.formattedSize() ?? "No data")

        ------- TOTAL TIME -------
        \(model.totalDuration ?? "No data")

        ------- MIME TYPE -------
        \(model.mineType ?? "No data")
        """
        return formattedLog
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
