//
//  PTDebugViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/11.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import FloatingPanel

public class PTDebugViewController: PTBaseViewController {
    
    lazy var settingCellModels:[PTFusionCellModel] = {
        
        let disclosureImage = "▶️".emojiToImage(emojiFont: .appfont(size: 14))
        
        var modeName = ""
        switch PTBaseURLMode {
        case .Development:
            modeName = AppCustomMode
        case .Test:
            modeName = AppTestMode
        case .Distribution:
            modeName = AppDisMode
        }
        
        let cell_mode = PTFusionCellModel()
        cell_mode.name = .ipMode
        cell_mode.content = modeName
        cell_mode.accessoryType = .DisclosureIndicator
        cell_mode.disclosureIndicatorImage = disclosureImage
        
        let cell_input = PTFusionCellModel()
        cell_input.name = .addressInput
        let url_debug:String = PTCoreUserDefultsWrapper.AppRequestUrl
        if url_debug.isEmpty {
            cell_input.content = Network.gobalUrl()
        } else {
            cell_input.content = url_debug
        }
        cell_input.accessoryType = .DisclosureIndicator
        cell_input.disclosureIndicatorImage = disclosureImage

        let cell_debug = PTFusionCellModel()
        cell_debug.name = .DebugMode
        cell_debug.accessoryType = .Switch

        return [cell_mode,cell_input,cell_debug]
    }()

    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 44
        config.sectionEdges = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)
        
        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { collection,itemSection,indexPath in
            let itemRow = itemSection.rows[indexPath.row]
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = (itemRow.dataModel as! PTFusionCellModel)
            if itemRow.title == .DebugMode {
                cell.switchValue = PTCoreUserDefultsWrapper.AppDebugMode
                cell.switchValueChangeBlock = { title,sender in
                    let value = !PTCoreUserDefultsWrapper.AppDebugMode
                    PTCoreUserDefultsWrapper.AppDebugMode = value
                    let console = LocalConsole.shared
                    console.isVisiable = value
                }
            }
            return cell
        }
        view.collectionDidSelect = { collection,model,indexPath in
            let itemRow = model.rows[indexPath.row]
            if itemRow.title == .ipMode {
                UIAlertController.baseActionSheet(title: "PT Debug network select".localized(), cancelButtonName: "PT Button cancel".localized(),titles: [AppDisMode,AppTestMode,AppCustomMode], otherBlock: { sheet,index in
                    switch index {
                    case PTActionSheetView.DestructiveButtonTag:
                        break
                    case PTActionSheetView.CancelButtonTag:
                        break
                    default:
                        PTCoreUserDefultsWrapper.AppServiceIdentifier = "\(index + 1)"

                        var modeName = ""
                        switch PTBaseURLMode {
                        case .Development:
                            modeName = AppCustomMode
                        case .Test:
                            modeName = AppTestMode
                        case .Distribution:
                            modeName = AppDisMode
                        }

                        self.settingCellModels[0].content = modeName
                        let cell = collection.cellForItem(at: indexPath) as! PTFusionCell
                        cell.cellModel = self.settingCellModels[0]
                    }
                })
            } else if itemRow.title == .addressInput {
                switch PTBaseURLMode {
                case .Development:
                    var current = ""
                    let url_debug:String = PTCoreUserDefultsWrapper.AppRequestUrl
                    if url_debug.isEmpty {
                        current = Network.share.serverAddress_dev
                    } else {
                        current = url_debug
                    }
                    
                    UIAlertController.base_textfield_alertVC(title:"PT Debug network input title".localized(),okBtn: "PT Button comfirm".localized(), cancelBtn: "PT Button cancel".localized(), showIn: self, placeHolders: ["PT Debug network input placeholder".localized()], textFieldTexts: [current], keyboardType: [.default],textFieldDelegate: self) { result in
                        let newURL = result.values.first
                        PTCoreUserDefultsWrapper.AppRequestUrl = newURL!
                        
                        self.settingCellModels[1].content = newURL!
                        let cell = collection.cellForItem(at: IndexPath.init(row: 1, section: 0)) as! PTFusionCell
                        cell.cellModel = self.settingCellModels[1]
                    }
                default:
                    UIViewController.gobal_drop(title: "Input with custom mode")
                }
            }
        }
        return view
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let backBtn = UIButton(type: .custom)
        backBtn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
        backBtn.addActionHandlers { sender in
            self.returnFrontVC()
        }
        
        if self.parent is FloatingPanelController {
            self.view.addSubview(backBtn)
            backBtn.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.height.equalTo(34)
                make.top.equalToSuperview().inset(PTAppBaseConfig.share.fpcSurfaceShadowBaseSize.height + 5)
            }
        } else {
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubview(backBtn)
        backBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(34)
            make.bottom.equalToSuperview().inset(5)
        }
#else
        backBtn.frame = CGRectMake(0, 0, 34, 34)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
#endif
        }

        view.addSubviews([newCollectionView])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            if self.parent is FloatingPanelController {
                make.top.equalTo(backBtn.snp.bottom).offset(5)
            } else {
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
            make.top.equalToSuperview()
#endif
            }
        }
        showDetail()
    }
    
    func showDetail() {
        var mSections = [PTSection]()
        
        var rows = [PTRows]()
        settingCellModels.enumerated().forEach { index,value in
            let row = PTRows.init(title: value.name,cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            rows.append(row)
        }
        let section = PTSection.init(rows: rows)
        mSections.append(section)
        
        newCollectionView.layoutIfNeeded()
        newCollectionView.showCollectionDetail(collectionData: mSections)
    }
}

extension PTDebugViewController:UITextFieldDelegate {
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        true
    }
}

fileprivate extension String {
    static let ipMode = "\("PT Debug network input title".localized())\("PT Debug mode select".localized())"
    static let addressInput = "PT Debug mode custom address".localized()
    static let DebugMode = "PT Debug mode".localized()
}
