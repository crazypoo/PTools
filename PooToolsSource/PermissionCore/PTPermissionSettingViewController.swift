//
//  PTPermissionSettingViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 10/12/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift

@objcMembers
public class PTPermissionSettingViewController: PTBaseViewController {

    fileprivate var permissionStatic = PTPermissionStatic.share
    
    private lazy var newCollectionView:PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Custom
        cConfig.headerWidthOffset = PTAppBaseConfig.share.defaultViewSpace * 2
        cConfig.sectionEdges = NSDirectionalEdgeInsets(top: 0, leading: PTAppBaseConfig.share.defaultViewSpace, bottom: 0, trailing: PTAppBaseConfig.share.defaultViewSpace)
        
        let view = PTCollectionView(viewConfig: cConfig)
        view.registerClassCells(classs: [PTPermissionSettingCell.ID:PTPermissionSettingCell.self])
        view.registerSupplementaryView(classs: [PTPermissionSettingHeader.ID:PTPermissionSettingHeader.self], kind: UICollectionView.elementKindSectionHeader)
        view.headerInCollection = { kind,collectionView,model,indexPath in
            if let headerModel = model.headerDataModel as? PTPermissionModel,let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: indexPath) as? PTPermissionSettingHeader {
                header.headerModel = headerModel
                return header
            }
            return nil
        }
        
        view.customerLayout = { sectionIndex,sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            var groupH:CGFloat = 0
            let screenW:CGFloat = self.view.frame.size.width
            let cellWidth = screenW - PTAppBaseConfig.share.defaultViewSpace * 2
            sectionModel.rows?.enumerated().forEach { (index,model) in
                if let dataModel = model.dataModel as? PTPermissionModel {
                    var descHeight = UIView.sizeFor(string: dataModel.desc, font: PTPermissionStatic.share.permissionSettingFont,lineSpacing: 2,width: cellWidth).height
                    if descHeight <= PTPermissionSettingCell.CellHeight {
                        descHeight = PTPermissionSettingCell.CellHeight
                    }
                    
                    let cellHeight:CGFloat = descHeight + 1 + PTPermissionSettingCell.CellHeight + 1 + PTPermissionSettingCell.CellHeight + 20
                    let customItem = NSCollectionLayoutGroupCustomItem(frame: CGRect(x: 0, y: groupH, width: cellWidth, height: cellHeight), zIndex: 1000+index)
                    customers.append(customItem)
                    groupH += cellHeight
                }
            }
            bannerGroupSize = NSCollectionLayoutSize(widthDimension: NSCollectionLayoutDimension.absolute(cellWidth), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.cellInCollection = { collectionView ,dataModel,indexPath in
            if let itemRow = dataModel.rows?[indexPath.row],let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTPermissionSettingCell,let cellModel = itemRow.dataModel as? PTPermissionModel {
                cell.cellModel  = cellModel
                return cell
            }
            return nil
        }
        return view
    }()

    private lazy var dismissButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        view.addActionHandlers { sender in
            self.returnFrontVC()
        }
        return view
    }()
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let nav = navigationController else { return }
        PTBaseNavControl.GobalNavControl(nav: nav)
        dismissButton.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        setCustomBackButtonView(dismissButton)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "PT Permission Authorize title".localized()
        
        view.addSubviews([newCollectionView])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview()
        }

        let sections = permissionStatic.permissionModels.map { value in
            let row = PTRows(ID: PTPermissionSettingCell.ID,dataModel: value)
            let section = PTSection(headerID: PTPermissionSettingHeader.ID,headerHeight: PTPermissionSettingHeader.headerHeight + 10,rows: [row],headerDataModel: value)
            return section
        }
        newCollectionView.showCollectionDetail(collectionData: sections)
    }
    
    public func permissionShow(vc:UIViewController) {
        let nav = PTBaseNavControl(rootViewController: self)
        nav.modalPresentationStyle = .formSheet
        vc.showDetailViewController(nav, sender: nil)
    }
}
