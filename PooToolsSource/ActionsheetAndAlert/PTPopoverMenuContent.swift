//
//  PTPopoverMenuContent.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 5/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SnapKit
import SwifterSwift

@objcMembers
public class PTPopoverItem:NSObject {
    open var name:String = ""
    open var icon:Any?
}

@objcMembers
public class PTPopoverConfig:NSObject {
    open var textFont:UIFont = .appfont(size: 16)
    open var textColor:UIColor = PTAppBaseConfig.share.viewDefaultTextColor
    open var backgroundColor:UIColor = PTDarkModeOption.colorLightDark(lightColor: .white, darkColor: .black)
    open var rowHeight:CGFloat = 44
}

public typealias PTPopoverHandler = (String,Int) -> Void

class PTPopoverMenuContent: PTBaseViewController {
    
    var didSelectedHandler:PTPopoverHandler!
    
    var arrowDirections:UIPopoverArrowDirection! {
        didSet {
            
            let size = preferredContentSize
            var newSize = CGSize.zero
            if arrowDirections == .up || arrowDirections == .down {
                newSize = CGSize(width: size.width, height: size.height + 16)
            } else if arrowDirections == .right || arrowDirections == .left {
                newSize = CGSize(width: size.width + 16, height: size.height)
            } else {
                newSize = size
            }
            preferredContentSize = newSize
            
            collectionView.snp.makeConstraints { make in
                if arrowDirections == .up {
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalToSuperview().inset(16)
                } else if arrowDirections == .right {
                    make.right.equalToSuperview().inset(16)
                    make.top.bottom.left.equalToSuperview()
                } else if arrowDirections == .left {
                    make.left.equalToSuperview().inset(16)
                    make.top.bottom.right.equalToSuperview()
                } else if arrowDirections == .down {
                    make.bottom.equalToSuperview().inset(16)
                    make.top.left.right.equalToSuperview()
                } else {
                    make.edges.equalToSuperview()
                }
            }
        }
    }
    
    private var viewModel:[PTPopoverItem] = [PTPopoverItem]()
    private var viewConfig:PTPopoverConfig!

    lazy var collectionView:PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Normal
        cConfig.itemHeight = self.viewConfig.rowHeight
        
        let view = PTCollectionView(viewConfig: cConfig)
        view.registerClassCells(classs: [PTFusionCell.ID:PTFusionCell.self])
        view.backgroundColor = .clear
        view.cellInCollection = { collectionView,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row] {
                let cellModel = (itemRow.dataModel as! PTFusionCellModel)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collectionView,sectionModel,indexPath in
            if let itemRow = sectionModel.rows?[indexPath.row] {
                let cellModel = (itemRow.dataModel as! PTFusionCellModel)
                self.dismiss(animated: true) {
                    self.didSelectedHandler(cellModel.name,indexPath.row)
                }
            }
        }
        return view
    }()
    
    init(config:PTPopoverConfig,viewModel: [PTPopoverItem]) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
        viewConfig = config
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
                
        view.backgroundColor = .clear
        view.addSubviews([collectionView])
        
        var rows = [PTRows]()
        viewModel.enumerated().forEach { index,value in
            let cellModel = PTFusionCellModel()
            cellModel.name = value.name
            cellModel.leftImage = value.icon
            cellModel.nameColor = self.viewConfig.textColor
            cellModel.cellFont = self.viewConfig.textFont

            let row = PTRows(ID: PTFusionCell.ID,dataModel: cellModel)
            rows.append(row)
        }
        
        let sections = [PTSection(rows: rows)]
        collectionView.showCollectionDetail(collectionData: sections)
    }
}
