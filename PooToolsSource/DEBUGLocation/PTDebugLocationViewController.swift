//
//  PTDebugLocationViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 2024/5/31.
//  Copyright © 2024 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import SafeSFSymbols
import CoreLocation

class PTDebugLocationViewController: PTBaseViewController {

    private let viewModel = PTDebugLocationModel()

    lazy var valueSwitch:PTSwitch = {
        let view = PTSwitch()
        view.isOn = PTCoreUserDefultsWrapper.PTMockLocationOpen
        view.valueChangeCallBack = { value in
            PTCoreUserDefultsWrapper.PTMockLocationOpen = value
            if value {
                CLLocationManager.swizzleMethods()
            }
        }
        view.bounds = CGRect(origin: .zero, size: CGSize.SwitchSize)
        return view
    }()

    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 80
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
            switch indexPath.row {
            case 0:
                let vc = PTDebugLocationMapViewController()
                vc.locationCallBack = { location in
                    PTDebugLocationKit.shared.simulatedLocation = location
                    self.viewModel.selectedIndex = .zero
                    self.loadListModel()
                }
                self.navigationController?.pushViewController(vc)
            default:
                self.viewModel.selectedIndex = indexPath.row
                let location = self.viewModel.locations[indexPath.row - 1]
                PTDebugLocationKit.shared.simulatedLocation = CLLocation(latitude: location.latitude,longitude: location.longitude)
                self.loadListModel()
            }
        }
        return view
    }()

    lazy var backButton:UIButton = {
        let button = baseButtonCreate(image: UIImage(.arrow.uturnLeftCircle))
        button.addActionHandlers { sender in
            self.dismissAnimated()
        }
        return button
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setCustomBackButtonView(backButton)
        setCustomRightButtons(buttons: [valueSwitch], rightPadding: 10)
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
        
//        let deleteButton = UIButton(type: .custom)
//        deleteButton.setImage(UIImage(.trash), for: .normal)
//        if #available(iOS 26.0, *) {
//            deleteButton.configuration = UIButton.Configuration.clearGlass()
//        }
        loadListModel()
    }
    
    func loadListModel() {
        var sections = [PTSection]()
        
        let customRowModel = baseCellModel(name: viewModel.customDescription ?? "Custom location", isSelected: viewModel.customSelected)
        let customRow = PTRows(ID: PTFusionCell.ID, dataModel: customRowModel)
        var rows = [PTRows]()
        rows.append(customRow)
        
        viewModel.locations.enumerated().forEach { index,value in
            let cellRowModel = baseCellModel(name: value.title, isSelected: (viewModel.selectedIndex == index + 1))
            let row = PTRows(ID: PTFusionCell.ID, dataModel: cellRowModel)
            rows.append(row)
        }
        let section = PTSection(rows: rows)
        sections.append(section)
        newCollectionView.showCollectionDetail(collectionData: sections)
    }

    func baseCellModel(name:String,isSelected:Bool) ->PTFusionCellModel {
        let model = PTFusionCellModel()
        model.name = name
        model.accessoryType = .DisclosureIndicator
        model.disclosureIndicatorImage = isSelected ? UIImage(.checkmark.circle) : nil
        return model
    }
}
