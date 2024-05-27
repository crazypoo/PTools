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
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

class PTCrashLogViewController: PTBaseViewController {

    private let viewModel = PTCrashViewModel()

    lazy var fakeNav : UIView = {
        let view = UIView()
        view.backgroundColor = .randomColor
        return view
    }()
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 100
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { collection,itemSection,indexPath in
            let itemRow = itemSection.rows[indexPath.row]
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
            return cell
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
            make.height.equalTo(CGFloat.kNavBarHeight)
            make.top.equalTo(20)
        }
        
        let button = UIButton(type: .custom)
        button.backgroundColor = .randomColor
        
        let crashButton = UIButton(type: .custom)
        crashButton.backgroundColor = .randomColor

        fakeNav.addSubviews([button,crashButton])
        button.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        button.addActionHandlers { sender in
            self.returnFrontVC()
        }
        
        crashButton.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        crashButton.addActionHandlers { sender in
            let array = NSArray()
            let _ = array.object(at: 4)
        }
        
        PTNSLogConsole("▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️▶️\(PTHttpDatasource.shared.httpModels)")
        
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
        
        listDataSet()
    }
    
    func listDataSet() {
        var sections = [PTSection]()
        
        var rows = [PTRows]()
        viewModel.data.enumerated().forEach( { index,value in
            let row_model = PTFusionCellModel()
            row_model.name = value.details.name
            row_model.desc = value.details.date.dateFormat(formatString: "yyyy-MM-dd HH:mm:ss")
            row_model.accessoryType = .DisclosureIndicator
            row_model.disclosureIndicatorImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
            
            let row = PTRows(cls: PTFusionCell.self,ID: PTFusionCell.ID, dataModel: row_model)
            rows.append(row)
        })
        
        let section = PTSection(rows: rows)
        sections.append(section)
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
}
