//
//  PTTestVC.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/6/18.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import Network
import ObjectiveC
import Foundation
import SnapKit
import SwifterSwift

class PTTestVC: PTBaseViewController {

    let datas:[PTFusionCellModel] = {
        let model = PTFusionCellModel()
        let model1 = PTFusionCellModel()
        return [model,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1,model1]
    }()
    
    lazy var collectionView : PTCollectionView = {
                
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .HorizontalLayoutSystem
        cConfig.itemHeight = 55
        cConfig.itemWidth = 100
        cConfig.cellLeadingSpace = 10
        cConfig.contentTopSpace = 10
        cConfig.contentBottomSpace = 10
    
        let aaaaaaa = PTCollectionView(viewConfig: cConfig)
        aaaaaaa.backgroundColor = .orange
        aaaaaaa.registerClassCells(classs: [PTFusionCell.ID:PTFusionCell.self])
        aaaaaaa.cellInCollection = { collectionView ,dataModel,indexPath in
            if let itemRow = dataModel.rows?[indexPath.row] {
                let cellModel = (itemRow.dataModel as! PTFusionCellModel)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
                cell.cellModel = cellModel
                cell.contentView.backgroundColor = .random
                if dataModel.rows!.count == 1 {
                    cell.hideTopLine = true
                } else {
                    cell.hideTopLine = indexPath.row == 0 ? true : false
                }
                cell.hideBottomLine = (dataModel.rows!.count - 1) == indexPath.row ? true : false
                return cell
            }
            return nil
        }
        aaaaaaa.headerRefreshTask = { sender in
            if #available(iOS 17, *) {
                self.collectionView.clearAllData { collectionview in
                    self.collectionView.endRefresh()
                }
            } else {
                self.collectionView.endRefresh()
            }
        }
        aaaaaaa.collectionViewDidScroll = { cView in
            PTNSLogConsole("123123")
        }
        aaaaaaa.emptyTap = { sender in
        }
        return aaaaaaa
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubviews([collectionView])
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(30)
        }
        
        dataSet()
    }
    
    func dataSet() {
        var sections = [PTSection]()
        var rows = [PTRows]()
        datas.enumerated().forEach { index,value in
            let row = PTRows(ID: PTFusionCell.ID,dataModel: value)
            rows.append(row)
        }
        sections.append(PTSection(rows: rows))
        collectionView.showCollectionDetail(collectionData: sections)
    }
}
