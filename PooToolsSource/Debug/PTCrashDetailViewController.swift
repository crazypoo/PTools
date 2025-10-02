//
//  PTCrashDetailViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols

class PTCrashDetailViewController: PTBaseViewController {
    
    fileprivate var viewModel:PTCrashDetailModel!
    
    lazy var fakeNav : PTNavBar = {
        let view = PTNavBar()
        return view
    }()
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Custom
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFusionCell.ID:PTFusionCell.self])
        view.registerSupplementaryView(classs: [PTFusionHeader.ID:PTFusionHeader.self], kind: UICollectionView.elementKindSectionHeader)
        view.customerLayout = { index,model in
            return UICollectionView.waterFallLayout(data: model.rows,rowCount: 1,itemOriginalX: 0, itemSpace: 0) { subIndex, objc in
                var baseRowHeight:CGFloat = 44
                let font:UIFont = .appfont(size: 16)
                if let rowModel = objc as? PTRows,let cellModel = rowModel.dataModel as? PTFusionCellModel {
                    let viewHeight = UIView.sizeFor(string: (cellModel.name + cellModel.content), font: font,width: CGFloat.kSCREEN_WIDTH).height
                    if viewHeight > baseRowHeight {
                        baseRowHeight = viewHeight
                    }
                }
                return baseRowHeight
            }
        }
        view.headerInCollection = { kind,collectionView,model,index in
            if let headerId = model.headerID,!headerId.stringIsEmpty(),let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: index) as? PTFusionHeader,let headerModel = model.headerDataModel as? PTFusionCellModel {
                header.sectionModel = headerModel
                return header
            }
            return nil
        }
        view.cellInCollection = { collection,itemSection,indexPath in
            if let itemRow = itemSection.rows?[indexPath.row],let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFusionCell,let cellModel = itemRow.dataModel as? PTFusionCellModel {
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,model,indexPath in
            if PTCrashDetailViewController.Features(rawValue: indexPath.section)?.title == "Context" {
                let cellModel = self.viewModel.dataSourceForItem(indexPath)
                if cellModel?.title == "Snapshot" {
                    let image = self.viewModel.data.context.uiImage
                    let vc = PTDebugSnapshotViewController(snapshotImage: image)
                    self.navigationController?.pushViewController(vc)
                }
            }
        }
        return view
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    init(viewModel: PTCrashDetailModel!) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            make.height.equalTo(CGFloat.kNavBarHeight)
            make.top.equalTo(self.newCollectionView)
        }
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)
        if #available(iOS 26.0, *) {
            button.configuration = UIButton.Configuration.clearGlass()
        }

        let shareButton = UIButton(type: .custom)
        shareButton.setImage(UIImage(.square.andArrowUp), for: .normal)
        if #available(iOS 26.0, *) {
            shareButton.configuration = UIButton.Configuration.clearGlass()
        }

        fakeNav.setLeftButtons([button])
        fakeNav.setRightButtons([shareButton])

        button.addActionHandlers { sender in
            self.navigationController?.popViewController()
        }
        
        shareButton.addActionHandlers { sender in
            let image = self.viewModel.data.context.uiImage

            guard let pdf = PTPDFManager.generatePDF(title: "Crash", body: self.viewModel.getAllValues(), image: image, logs: self.viewModel.data.context.consoleOutput
            ) else {
                PTNSLogConsole("Failure in create PDF")
                return
            }

            guard let fileURL = PTPDFManager.savePDFData(pdf, fileName: "Crash-\(UUID().uuidString).pdf") else {
                PTNSLogConsole("Failure to save PDF")
                return
            }
            PTDebugShareManager.share(fileURL)
        }
                        
        loadListData()
    }
    
    func loadListData() {
        var sections = [PTSection]()
        
        PTCrashDetailViewController.Features.allCases.enumerated().forEach { index,value in
            var rows = [PTRows]()
            let rowCount = self.viewModel.numberOfItems(section: index)
            for i in 0..<rowCount {
                let cellRealModel = self.viewModel.dataSourceForItem(IndexPath(row: i, section: index))
                switch PTCrashDetailViewController.Features(rawValue: index) {
                case .details,.stackTrace:
                    let cellModel = self.normalCellModel(name: cellRealModel?.title ?? "", content: cellRealModel?.detail ?? "")
                    let row = PTRows(ID: PTFusionCell.ID,dataModel: cellModel)
                    rows.append(row)
                case .context:
                    let cellModel = self.tapCellModel(name: cellRealModel?.title ?? "")
                    let row = PTRows(ID: PTFusionCell.ID,dataModel: cellModel)
                    rows.append(row)
                default:
                    break
                }
            }
            let headerModel = PTFusionCellModel()
            headerModel.name = value.title
            headerModel.cellFont = .appfont(size: 18,bold: true)
            let section = PTSection(headerID:PTFusionHeader.ID,headerHeight: 34,rows: rows,headerDataModel: headerModel)
            sections.append(section)
        }
        
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
    
    func normalCellModel(name:String,content:String) -> PTFusionCellModel {
        let model = PTFusionCellModel()
        model.name = name
        model.content = content
        return model
    }
    
    func tapCellModel(name:String) -> PTFusionCellModel {
        let model = PTFusionCellModel()
        model.name = name
        model.accessoryType = .DisclosureIndicator
        model.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
        return model
    }
}

extension PTCrashDetailViewController {
    enum Features: Int, CaseIterable {
        case details
        case context
        case stackTrace

        var title: String {
            switch self {
            case .details:
                return "Detail"
            case .context:
                return "Context"
            case .stackTrace:
                return "Stack Trace"
            }
        }
    }
}
