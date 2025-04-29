//
//  PTUserDefultsViewController.swift
//  PooTools_Example
//
//  Created by 邓杰豪 on 8/6/23.
//  Copyright © 2023 crazypoo. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

class PTUserDefultsViewController: PTBaseViewController {
    
    fileprivate let userdefaultShares = PTUserDefaultKeysAndValues.shares
    
    var showAllUserDefaultsKeys:Bool! = false {
        didSet {
            userdefaultShares.showAllUserDefaultsKeys = showAllUserDefaultsKeys
        }
    }
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 64
        config.sectionEdges = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)
        
        let view = PTCollectionView(viewConfig: config)
        view.registerClassCells(classs: [PTFusionCell.ID:PTFusionCell.self])
        view.cellInCollection = { collection,itemSection,indexPath in
            if let itemRow = itemSection.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTFusionCellModel,let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as? PTFusionCell {
                cell.contentView.backgroundColor = .white
                cell.cellModel = cellModel
                return cell
            }
            return nil
        }
        view.collectionDidSelect = { collection,model,indexPath in
            if let itemRow = model.rows?[indexPath.row],let cellModel = itemRow.dataModel as? PTFusionCellModel {
                UIAlertController.base_textfield_alertVC(title:"Edit\n" + cellModel.name,okBtn: "⭕️", cancelBtn: "Cancel", placeHolders: [cellModel.name], textFieldTexts: [cellModel.desc], keyboardType: [.default], textFieldDelegate: self) { result in
                    let newValue = result.values.first
                    UserDefaults.standard.setValue(newValue, forKey: cellModel.name)
                    self.showDetail()
                }
            }
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        
        let dic = UserDefaults.standard.dictionaryRepresentation()
        PTNSLogConsole(dic,levelType: PTLogMode,loggerType: .UserDefaults)

        let backBtn = UIButton(type: .custom)
        backBtn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        backBtn.addActionHandlers { sender in
            self.returnFrontVC()
        }
        
        let cleanBtn = UIButton(type: .custom)
        cleanBtn.setImage("🗑️".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        cleanBtn.addActionHandlers { sender in
            self.clearUserdefults()
        }
        
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubviews([backBtn,cleanBtn])
        backBtn.snp.makeConstraints { make in
            make.size.equalTo(34)
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.equalToSuperview().inset(21)
        }
            
        cleanBtn.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.top.size.equalTo(backBtn)
        }
#else
        backBtn.frame = CGRectMake(0, 0, 34, 34)
        cleanBtn.frame = CGRectMake(0, 0, 34, 34)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cleanBtn)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: backBtn)
#endif

        view.addSubview(newCollectionView)
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
#if POOTOOLS_NAVBARCONTROLLER
                make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
                make.top.equalToSuperview()
#endif
        }
        
        showDetail()
    }
    
    func showDetail() {
        var mSections = [PTSection]()

        let userdefultArrs = userdefaultShares.keyAndValues().map { value in
            let model = PTFusionCellModel()
            model.name = value.keys.first!
            model.desc = String(format: "%@", value.values.first as! CVarArg)
            model.haveLine = .Normal
            model.haveTopLine = .NO
            model.accessoryType = .DisclosureIndicator
            model.disclosureIndicatorImage = "➡️".emojiToImage(emojiFont: .appfont(size: 14))
            return model
        }
        
        let rows = userdefultArrs.map { PTRows.init(ID: PTFusionCell.ID, dataModel: $0) }
        let cellSection = PTSection.init(rows: rows)
        mSections.append(cellSection)
        
        newCollectionView.showCollectionDetail(collectionData: mSections)
    }
    
    func clearUserdefults() {
        UIAlertController.base_alertVC(title: "PT Alert Opps".localized(),msg: "PT UserDefault delete".localized(),okBtns: ["PT Button comfirm".localized()],cancelBtn: "PT Button cancel".localized()) {
            
        } moreBtn: { index, title in
            let bundleIdentifier = Bundle.main.bundleIdentifier
            
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier!)
            
            self.showDetail()
        }
    }
}

extension PTUserDefultsViewController:UITextFieldDelegate {}

#if POOTOOLS_ROUTER
extension PTUserDefultsViewController:PTRouterable {
    public static var priority: UInt {
        PTRouterDefaultPriority
    }

    public static var patternString: [String] {
        ["scheme://route/userdefault"]
    }
    
    public static func registerAction(info: [String : Any]) -> Any {
        let vc = PTUserDefultsViewController()
        return vc
    }
}
#endif
