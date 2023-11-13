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

class PTUserDefultsViewController: PTBaseViewController {

#if POOTOOLS_NAVBARCONTROLLER
    let haveZXbar:Bool = true
#else
    let haveZXbar:Bool = false
#endif
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 44
        config.sectionEdges = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)
        
        let view = PTCollectionView(viewConfig: config)
        view.cellInCollection = { collection,itemSection,indexPath in
            let itemRow = itemSection.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTFusionCellModel)
            let cell = collection.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.contentView.backgroundColor = .white
            cell.cellModel = cellModel
            return cell
        }
        view.collectionDidSelect = { collection,model,indexPath in
            let itemRow = model.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTFusionCellModel)
            let vc = PTUserDefultsEditViewController(viewModel: cellModel)
            self.navigationController?.pushViewController(vc)
            vc.doneBlock = {
                self.showDetail()
            }
        }
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        
        let dic = UserDefaults.standard.dictionaryRepresentation()
        PTNSLogConsole(dic)

        if haveZXbar {
#if POOTOOLS_NAVBARCONTROLLER
            
            self.zx_navTitle = "UserDefults"
            
            let backBtn = UIButton(type: .custom)
            backBtn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
            self.zx_navBar?.addSubview(backBtn)
            backBtn.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.height.equalTo(34)
                make.bottom.equalToSuperview().inset(5)
            }
            backBtn.addActionHandlers { sender in
                self.returnFrontVC()
            }
            
            let cleanBtn = UIButton(type: .custom)
            cleanBtn.setImage("🗑️".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
            self.zx_navBar?.addSubview(cleanBtn)
            cleanBtn.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.height.equalTo(34)
                make.bottom.equalToSuperview().inset(5)
            }
            cleanBtn.addActionHandlers { sender in
                self.clearUserdefults()
            }
#endif
        } else {
            title = "UserDefults"
            let backBtn = UIButton(type: .custom)
            backBtn.frame = CGRectMake(0, 0, 34, 34)
            backBtn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
            backBtn.addActionHandlers { sender in
                self.returnFrontVC()
            }
            
            let cleanBtn = UIButton(type: .custom)
            cleanBtn.frame = CGRectMake(0, 0, 34, 34)
            cleanBtn.setImage("🗑️".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cleanBtn)
            cleanBtn.addActionHandlers { sender in
                self.clearUserdefults()
            }
        }
        
        view.addSubview(newCollectionView)
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            if self.haveZXbar {
                make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
            } else {
                make.top.equalToSuperview()
            }
        }
        
        showDetail()
    }
    
    func showDetail() {
        var mSections = [PTSection]()

        var userdefultArrs = [PTFusionCellModel]()
        let dic = UserDefaults.standard.dictionaryRepresentation()
        dic.enumerated().forEach { index,value in
            let model = PTFusionCellModel()
            model.name = value.key
            model.desc = String(format: "%@", value.value as! CVarArg)
            model.haveLine = true
            model.haveTopLine = false
            model.accessoryType = .DisclosureIndicator
            model.disclosureIndicatorImage = "➡️".emojiToImage(emojiFont: .appfont(size: 14))
            userdefultArrs.append(model)
        }
        
        var rows = [PTRows]()
        userdefultArrs.enumerated().forEach { (index,value) in
            let row_List = PTRows.init(cls: PTFusionCell.self, ID: PTFusionCell.ID, dataModel: value)
            rows.append(row_List)
        }
        let cellSection = PTSection.init(rows: rows)
        mSections.append(cellSection)
        
        newCollectionView.layoutIfNeeded()
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

class PTUserDefultsEditViewController:PTBaseViewController {
    
    private var viewModel:PTFusionCellModel!
    
    var doneBlock:PTActionTask?
    
#if POOTOOLS_NAVBARCONTROLLER
    let haveZXbar:Bool = true
#else
    let haveZXbar:Bool = false
#endif

    lazy var keyLabel:UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = .appfont(size: 17)
        view.textColor = .black
        view.text = self.viewModel.name
        return view
    }()
    
    lazy var textInputView:UITextView = {
        let view = UITextView()
        view.text = self.viewModel.desc
        return view
    }()
    
    init(viewModel: PTFusionCellModel!) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if haveZXbar {
#if POOTOOLS_NAVBARCONTROLLER
            
            self.zx_navTitle = "EditUserDefults"
                        
            let cleanBtn = UIButton(type: .custom)
            cleanBtn.setImage("⭕️".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
            self.zx_navBar?.addSubview(cleanBtn)
            cleanBtn.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.height.equalTo(34)
                make.bottom.equalToSuperview().inset(5)
            }
            cleanBtn.addActionHandlers { sender in
                self.saveAction()
            }
#endif
        } else {
            title = "EditUserDefults"
            
            let cleanBtn = UIButton(type: .custom)
            cleanBtn.frame = CGRectMake(0, 0, 34, 34)
            cleanBtn.setImage("⭕️".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cleanBtn)
            cleanBtn.addActionHandlers { sender in
                self.saveAction()
            }
        }
        
        view.addSubviews([keyLabel, textInputView])
        keyLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            if self.haveZXbar {
                make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total + 10)
            } else {
                make.top.equalToSuperview().inset(10)
            }
        }
        
        textInputView.snp.makeConstraints { make in
            make.left.right.equalTo(self.keyLabel)
            make.top.equalTo(self.keyLabel.snp.bottom).offset(10)
            make.bottom.equalTo(self.view.snp.centerY)
        }
        textInputView.pt_placeholder = "value"
    }
    
    func saveAction() {
        UserDefaults.standard.setValue(textInputView.text, forKey: viewModel.name)
        navigationController?.popViewController {
            if self.doneBlock != nil {
                self.doneBlock!()
            }
        }
    }
}
