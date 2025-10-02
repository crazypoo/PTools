//
//  PTCrashLogViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/27.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols

class PTCrashLogViewController: PTBaseViewController {

    private let viewModel = PTCrashViewModel()

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
        view.customerLayout = { index,model in
            return UICollectionView.waterFallLayout(data: model.rows,rowCount: 1,itemOriginalX: 0, itemSpace: 0) { subIndex, objc in
                var baseRowHeight:CGFloat = 54
                let font:UIFont = .appfont(size: 16)
                let descFont:UIFont = .appfont(size: 14)
                if let rowModel = objc as? PTRows,let cellModel = rowModel.dataModel as? PTFusionCellModel {
                    let nameHeight = UIView.sizeFor(string: cellModel.name, font: font,width: CGFloat.kSCREEN_WIDTH).height
                    let descHeight = UIView.sizeFor(string: cellModel.desc, font: descFont,width: CGFloat.kSCREEN_WIDTH).height
                    let totalHeight = nameHeight + descHeight
                    if totalHeight > baseRowHeight {
                        baseRowHeight = totalHeight
                    }
                }
                return baseRowHeight
            }
        }
        view.cellInCollection = { collection,itemSection,indexPath in
            if let itemRow = itemSection.rows?[indexPath.row],let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFusionCell,let cellModel = itemRow.dataModel as? PTFusionCellModel {
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,model,indexPath in
            let data = self.viewModel.data[indexPath.row]
            let viewModel = PTCrashDetailModel(data: data)
            let vc = PTCrashDetailViewController(viewModel: viewModel)
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
        
        view.addSubviews([fakeNav,newCollectionView])
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

        let crashButton = UIButton(type: .custom)
        crashButton.setImage(UIImage(.bolt.fill), for: .normal)
        if #available(iOS 26.0, *) {
            crashButton.configuration = UIButton.Configuration.clearGlass()
        }

        fakeNav.setLeftButtons([button])
        fakeNav.setRightButtons([crashButton])
        
        button.addActionHandlers { sender in
            self.returnFrontVC()
        }
        
        crashButton.addActionHandlers { sender in
            let array = NSArray()
            let _ = array.object(at: 4)
        }
        
        PTNSLogConsole("▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️\(PTHttpDatasource.shared.httpModels)")
    
        listDataSet()
    }
    
    func listDataSet() {
        var sections = [PTSection]()
        
        let rows = viewModel.data.map { value in
            let row_model = PTFusionCellModel()
            row_model.name = value.details.name
            row_model.desc = value.details.date.dateFormat(formatString: "yyyy-MM-dd HH:mm:ss")
            row_model.accessoryType = .DisclosureIndicator
            row_model.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
            
            let row = PTRows(ID: PTFusionCell.ID, dataModel: row_model)
            return row
        }
        
        let section = PTSection(rows: rows)
        sections.append(section)
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
}
