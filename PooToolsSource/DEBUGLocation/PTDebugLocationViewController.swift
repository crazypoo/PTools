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
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SafeSFSymbols
import CoreLocation

class PTDebugLocationViewController: PTBaseViewController {

    private let viewModel = PTDebugLocationModel()

    lazy var fakeNav:UIView = {
        let view = UIView()
        return view
    }()

    lazy var valueSwitch:PTSwitch = {
        let view = PTSwitch()
        view.isOn = PTCoreUserDefultsWrapper.PTMockLocationOpen
        view.valueChangeCallBack = { value in
            PTCoreUserDefultsWrapper.PTMockLocationOpen = value
            if value {
                CLLocationManager.swizzleMethods()
            }
        }
        return view
    }()

    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 80
        config.refreshWithoutAnimation = true
        
        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { collection,itemSection,indexPath in
            let itemRow = itemSection.rows[indexPath.row]
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
            return cell
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
            make.top.equalToSuperview().inset(20)
            make.height.equalTo(CGFloat.kNavBarHeight)
        }
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(.arrow.uturnLeftCircle), for: .normal)

        let deleteButton = UIButton(type: .custom)
        deleteButton.setImage(UIImage(.trash), for: .normal)

        fakeNav.addSubviews([button,valueSwitch])
        button.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.top.equalToSuperview().inset(5)
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
        }
        button.addActionHandlers { sender in
            self.dismissAnimated()
        }
                
        valueSwitch.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.centerY.equalTo(button)
            make.width.equalTo(51)
            make.height.equalTo(31)
        }
        
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(self.fakeNav.snp.bottom)
        }
        
        loadListModel()
    }
    
    func loadListModel() {
        var sections = [PTSection]()
        
        let customRowModel = baseCellModel(name: viewModel.customDescription ?? "Custom location", isSelected: viewModel.customSelected)
        let customRow = PTRows(cls: PTFusionCell.self, ID: PTFusionCell.ID, dataModel: customRowModel)
        
        var rows = [PTRows]()
        
        rows.append(customRow)
        
        viewModel.locations.enumerated().forEach { index,value in
            let cellRowModel = baseCellModel(name: value.title, isSelected: (viewModel.selectedIndex == index + 1))
            let row = PTRows(cls: PTFusionCell.self, ID: PTFusionCell.ID, dataModel: cellRowModel)
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
