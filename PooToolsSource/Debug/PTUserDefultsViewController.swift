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
import FloatingPanel
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif

class PTUserDefultsViewController: PTBaseViewController {
    
    lazy var newCollectionView:PTCollectionView = {
        let config = PTCollectionViewConfig()
        config.viewType = .Normal
        config.itemOriginalX = 0
        config.itemHeight = 64
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
            self.dismiss(animated: true) {
                let itemRow = model.rows[indexPath.row]
                let cellModel = (itemRow.dataModel as! PTFusionCellModel)
                let vc = PTUserDefultsEditViewController(viewModel: cellModel)
                LocalConsole.shared.floatingAction(vc: vc)
                vc.doneBlock = {
                    let userdefault = PTUserDefultsViewController()
                    LocalConsole.shared.floatingAction(vc: userdefault)
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
        PTNSLogConsole(dic)

        let backBtn = UIButton(type: .custom)
        backBtn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
        backBtn.addActionHandlers { sender in
            self.returnFrontVC()
        }
        
        let cleanBtn = UIButton(type: .custom)
        cleanBtn.setImage("🗑️".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
        cleanBtn.addActionHandlers { sender in
            self.clearUserdefults()
        }
        
        if self.parent is FloatingPanelController {
            view.addSubviews([backBtn,cleanBtn])
            backBtn.snp.makeConstraints { make in
                make.size.equalTo(34)
                make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.top.equalToSuperview().inset(PTAppBaseConfig.share.fpcSurfaceShadowBaseSize.height + 5)
            }
            
            cleanBtn.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.top.size.equalTo(backBtn)
            }
        } else {
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
        }
        
        self.view.addSubview(newCollectionView)
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
        
        let cleanBtn = UIButton(type: .custom)
        cleanBtn.setImage("⭕️".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
        cleanBtn.addActionHandlers { sender in
            self.saveAction()
        }

        if self.parent is FloatingPanelController {
            self.view.addSubview(cleanBtn)
            cleanBtn.snp.makeConstraints { make in
                make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.height.equalTo(34)
                make.top.equalToSuperview().inset(PTAppBaseConfig.share.fpcSurfaceShadowBaseSize.height + 5)
            }
        } else {
#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navBar?.addSubview(cleanBtn)
        cleanBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            make.height.equalTo(34)
            make.bottom.equalToSuperview().inset(5)
        }
#else
        cleanBtn.frame = CGRectMake(0, 0, 34, 34)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cleanBtn)
#endif
        }

        view.addSubviews([keyLabel, textInputView])

        keyLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            if self.parent is FloatingPanelController {
                make.top.equalTo(cleanBtn.snp.bottom).offset(10)
            } else {
#if POOTOOLS_NAVBARCONTROLLER
                make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total + 10)
#else
                make.top.equalToSuperview().inset(10)
#endif
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
        dismiss(animated: true) {
            if self.doneBlock != nil {
                self.doneBlock!()
            }
        }
    }
}

#if POOTOOLS_ROUTER
extension PTUserDefultsViewController:PTRouterable {
    public static var patternString: [String] {
        ["scheme://route/userdefault"]
    }
    
    public static func registerAction(info: [String : Any]) -> Any {
        let vc = PTUserDefultsViewController()
        return vc
    }
}

extension PTUserDefultsEditViewController:PTRouterable {
    public static var patternString: [String] {
        ["scheme://route/userdefaultedit"]
    }
    
    public static func registerAction(info: [String : Any]) -> Any {
        let vc = PTUserDefultsEditViewController(viewModel: PTFusionCellModel())
        return vc
    }
}
#endif

extension PTUserDefultsViewController {
    public override func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        let layout = PTCustomControlHeightPanelLayout()
        layout.viewHeight = (CGFloat.kSCREEN_HEIGHT - CGFloat.statusBarHeight())
        return layout
    }
}

extension PTUserDefultsEditViewController {
    public override func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        let layout = PTCustomControlHeightPanelLayout()
        layout.viewHeight = (CGFloat.kSCREEN_HEIGHT - CGFloat.statusBarHeight())
        return layout
    }
}
