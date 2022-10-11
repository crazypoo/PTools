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

@available(iOS 13.0,*)
public class PTDebugViewController: PTBaseViewController {
    
    lazy var settingCellModels:[PTFunctionCellModel] = {
        
        var modeName = ""
        switch PTBaseURLMode {
        case .Development:
            modeName = "自定义环境"
        case .Test:
            modeName = "测试环境"
        case .Distribution:
            modeName = "生产环境"
        }
        
        let cell_mode = PTFunctionCellModel()
        cell_mode.name = .ipMode
        cell_mode.content = modeName
        cell_mode.haveDisclosureIndicator = true
        
        let cell_input = PTFunctionCellModel()
        cell_input.name = .addressInput
        let userDefaults_url = UserDefaults.standard.value(forKey: "UI_test_url")
        let url_debug:String = userDefaults_url == nil ? "" : (userDefaults_url as! String)
        if url_debug.isEmpty
        {
            cell_input.content = Network.gobalUrl()
        }
        else
        {
            cell_input.content = url_debug
        }
        cell_input.haveDisclosureIndicator = true

        let cell_debug = PTFunctionCellModel()
        cell_debug.name = .DebugMode
        cell_debug.haveSwitch = true

        return [cell_mode,cell_input,cell_debug]
    }()

    
    var mSections = [PTSection]()
    
    func comboLayout()->UICollectionViewCompositionalLayout
    {
        let layout = UICollectionViewCompositionalLayout.init { section, environment in
            self.generateSection(section: section)
        }
        return layout
    }
    
    func generateSection(section:NSInteger)->NSCollectionLayoutSection
    {
        let sectionModel = mSections[section]

        var group : NSCollectionLayoutGroup
        let behavior : UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous

        let bannerItemSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.fractionalWidth(1), heightDimension: NSCollectionLayoutDimension.fractionalHeight(1))
        let bannerItem = NSCollectionLayoutItem.init(layoutSize: bannerItemSize)
        
        var bannerGroupSize : NSCollectionLayoutSize
        
        bannerItem.contentInsets = NSDirectionalEdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0)
        bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(kSCREEN_WIDTH), heightDimension: NSCollectionLayoutDimension.absolute(44 * CGFloat(sectionModel.rows.count)))
        group = NSCollectionLayoutGroup.vertical(layoutSize: bannerGroupSize, subitem: bannerItem, count: sectionModel.rows.count)

        let sectionInsets = NSDirectionalEdgeInsets.init(top: 10, leading: 0, bottom: 0, trailing: 0)
        let laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets

        return laySection
    }

    lazy var viewCollection : UICollectionView = {
        let view = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: self.comboLayout())
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .white
        return view
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubviews([self.viewCollection])
        self.viewCollection.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalToSuperview().inset(kNavBarHeight_Total)
        }
        self.showDetail()
    }
    
    func showDetail()
    {
        self.mSections.removeAll()
        
        var rows = [PTRows]()
        self.settingCellModels.enumerated().forEach { index,value in
            let row = PTRows.init(title: value.name,cls: PTFusionCell.self,ID: PTFusionCell.ID,dataModel: value)
            rows.append(row)
        }
        let section = PTSection.init(rows: rows)
        self.mSections.append(section)
        
        self.viewCollection.pt_register(by: self.mSections)
        self.viewCollection.reloadData()
    }
}

@available(iOS 13.0,*)
extension PTDebugViewController : UICollectionViewDelegate,UICollectionViewDataSource
{
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.mSections.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mSections[section].rows.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let itemSec = mSections[indexPath.section]
        let itemRow = itemSec.rows[indexPath.row]
        if itemRow.ID == PTFusionCell.ID
        {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.cellModel = (itemRow.dataModel as! PTFunctionCellModel)
            if itemRow.title == .DebugMode
            {
                cell.dataContent.valueSwitch.isOn = App_UI_Debug_Bool
                cell.switchValueChangeBLock = { title,sender in
                    let value = !App_UI_Debug_Bool
                    UserDefaults.standard.set(value, forKey: LocalConsole.ConsoleDebug)
                    if value
                    {
                        if PTDevFunction.share.mn_PFloatingButton == nil
                        {
                            //开了
                            PTDevFunction.share.createLabBtn()
                            PTDevFunction.GobalDevFunction_open()
                        }
                    }
                    else
                    {
                        //关了
                        PTDevFunction.share.mn_PFloatingButton?.removeFromSuperview()
                        PTDevFunction.share.mn_PFloatingButton = nil
                        PTDevFunction.GobalDevFunction_close()
                    }
                }
            }
            return cell
        }
        else
        {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath)
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemSec = mSections[indexPath.section]
        let itemRow = itemSec.rows[indexPath.row]
        if itemRow.title == .ipMode
        {
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
                    let cell = self.viewCollection.cellForItem(at: indexPath) as! PTFusionCell
                    cell.cellModel = self.settingCellModels[0]
                }
            }
            actionSheet.show()
        }
        else if itemRow.title == .addressInput
        {
            switch PTBaseURLMode {
            case .Development:
                var current = ""
                let userDefaults_url = UserDefaults.standard.value(forKey: "UI_test_url")
                let url_debug:String = userDefaults_url == nil ? "" : (userDefaults_url as! String)
                if url_debug.isEmpty
                {
                    current = Network.share.serverAddress_dev
                }
                else
                {
                    current = url_debug
                }
                
                PTUtils.base_textfiele_alertVC(title:"输入服务器地址",okBtn: "确定", cancelBtn: "取消", showIn: self, placeHolders: ["请输入服务器地址"], textFieldTexts: [current], keyboardType: [.default],textFieldDelegate: self) { result in
                    let newURL = result.values.first
                    UserDefaults.standard.set(newURL, forKey: "UI_test_url")
                    
                    self.settingCellModels[1].content = newURL!
                    let cell = self.viewCollection.cellForItem(at: IndexPath.init(row: 1, section: 0)) as! PTFusionCell
                    cell.cellModel = self.settingCellModels[1]
                }
            default:
                PTUtils.gobal_drop(title: "仅在自定义模式中输入")
            }
        }
    }
}

@available(iOS 13.0,*)
extension PTDebugViewController:UITextFieldDelegate
{
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}

fileprivate extension String
{
    static let ipMode = "选择服务器地址(默认是正式环境)"
    static let addressInput = "自定义地址"
    static let DebugMode = "DebugMode"
}
