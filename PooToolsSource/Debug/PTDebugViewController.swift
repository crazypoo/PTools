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

public class PTDebugViewController: PTBaseViewController {
    
    lazy var settingCellModels:[PTFusionCellModel] = {
        
        var modeName = ""
        switch PTBaseURLMode {
        case .Development:
            modeName = "自定义环境"
        case .Test:
            modeName = "测试环境"
        case .Distribution:
            modeName = "生产环境"
        }
        
        let cell_mode = PTFusionCellModel()
        cell_mode.name = .ipMode
        cell_mode.content = modeName
        cell_mode.accessoryType = .DisclosureIndicator
        
        let cell_input = PTFusionCellModel()
        cell_input.name = .addressInput
        let userDefaults_url = UserDefaults.standard.value(forKey: "UI_test_url")
        let url_debug:String = userDefaults_url == nil ? "" : (userDefaults_url as! String)
        if url_debug.isEmpty {
            cell_input.content = Network.gobalUrl()
        } else {
            cell_input.content = url_debug
        }
        cell_input.accessoryType = .DisclosureIndicator

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
                cell.dataContent.valueSwitch.isOn = App_UI_Debug_Bool
                cell.switchValueChangeBLock = { title,sender in
                    let value = !App_UI_Debug_Bool
                    UserDefaults.standard.set(value, forKey: LocalConsole.ConsoleDebug)
                    if value {
                        if PTDevFunction.share.mn_PFloatingButton == nil {
                            //开了
                            PTDevFunction.share.createLabBtn()
                            PTDevFunction.GobalDevFunction_open { showFlex in
#if DEBUG
                                self.showFlexFunction(show: showFlex)
#endif
                            }
                        }
                    } else {
                        //关了
                        PTDevFunction.share.mn_PFloatingButton?.removeFromSuperview()
                        PTDevFunction.share.mn_PFloatingButton = nil
                        PTDevFunction.GobalDevFunction_close { showFlex in
#if DEBUG
                                self.showFlexFunction(show: showFlex)
#endif
                        }
                    }
                }
            }
            return cell
        }
        view.collectionDidSelect = { collection,model,indexPath in
            let itemRow = model.rows[indexPath.row]
            if itemRow.title == .ipMode {
                let actionSheet = PTActionSheetView.init(title: "选择APP请求环境", subTitle: "", cancelButton: NSLocalizedString("取消", comment: ""),destructiveButton: "", otherButtonTitles: ["生产环境","测试","自定义"])
                actionSheet.actionSheetSelectBlock = { (sheet,index) in
                    switch index {
                    case PTActionSheetView.DestructiveButtonTag:
                        break
                    case PTActionSheetView.CancelButtonTag:
                        break
                    default:
                        UserDefaults.standard.set("\(index + 1)", forKey: "AppServiceIdentifier")
                        
                        var modeName = ""
                        switch PTBaseURLMode {
                        case .Development:
                            modeName = "自定义环境"
                        case .Test:
                            modeName = "测试环境"
                        case .Distribution:
                            modeName = "生产环境"
                        }

                        self.settingCellModels[0].content = modeName
                        let cell = collection.cellForItem(at: indexPath) as! PTFusionCell
                        cell.cellModel = self.settingCellModels[0]
                    }
                }
                actionSheet.show()
            } else if itemRow.title == .addressInput {
                switch PTBaseURLMode {
                case .Development:
                    var current = ""
                    let userDefaults_url = UserDefaults.standard.value(forKey: "UI_test_url")
                    let url_debug:String = userDefaults_url == nil ? "" : (userDefaults_url as! String)
                    if url_debug.isEmpty {
                        current = Network.share.serverAddress_dev
                    } else {
                        current = url_debug
                    }
                    
                    UIAlertController.base_textfield_alertVC(title:"输入服务器地址",okBtn: "确定", cancelBtn: "取消", showIn: self, placeHolders: ["请输入服务器地址"], textFieldTexts: [current], keyboardType: [.default],textFieldDelegate: self) { result in
                        let newURL = result.values.first
                        UserDefaults.standard.set(newURL, forKey: "UI_test_url")
                        
                        self.settingCellModels[1].content = newURL!
                        let cell = collection.cellForItem(at: IndexPath.init(row: 1, section: 0)) as! PTFusionCell
                        cell.cellModel = self.settingCellModels[1]
                    }
                default:
                    UIViewController.gobal_drop(title: "仅在自定义模式中输入")
                }
            }
        }
        return view
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubviews([newCollectionView])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
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
    static let ipMode = "选择服务器地址(默认是正式环境)"
    static let addressInput = "自定义地址"
    static let DebugMode = "DebugMode"
}
