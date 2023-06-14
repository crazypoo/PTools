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
    
    var mSections = [PTSection]()
    func comboLayout()->UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout.init { section, environment in
            self.generateSection(section: section)
        }
        layout.register(PTBaseDecorationView_Corner.self, forDecorationViewOfKind: "background")
        layout.register(PTBaseDecorationView.self, forDecorationViewOfKind: "background_no")
        return layout
    }
    
    func generateSection(section:NSInteger)->NSCollectionLayoutSection {
        let sectionModel = mSections[section]

        var group : NSCollectionLayoutGroup
        let behavior : UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous
        
        let cellSize = CGFloat.kSCREEN_WIDTH - PTAppBaseConfig.share.defaultViewSpace * 2
        group = UICollectionView.girdCollectionLayout(data: sectionModel.rows,groupWidth: CGFloat.kSCREEN_WIDTH,size: CGSize(width: cellSize, height: 54),cellRowCount: 1,originalX: PTAppBaseConfig.share.defaultViewSpace,contentTopAndBottom: 10,cellLeadingSpace: PTAppBaseConfig.share.defaultViewSpace,cellTrailingSpace: 0)
        
        let sectionInsets = NSDirectionalEdgeInsets.init(top: 0, leading: 0, bottom: 0, trailing: 0)
        let laySection = NSCollectionLayoutSection(group: group)
        laySection.orthogonalScrollingBehavior = behavior
        laySection.contentInsets = sectionInsets
        laySection.supplementariesFollowContentInsets = false

        return laySection
    }

    lazy var collectionView : UICollectionView = {
        let view = UICollectionView.init(frame: .zero, collectionViewLayout: self.comboLayout())
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
        
        let dic = UserDefaults.standard.dictionaryRepresentation()
        PTNSLogConsole(dic)

        if self.haveZXbar {
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
            self.title = "UserDefults"
            let backBtn = UIButton(type: .custom)
            backBtn.frame = CGRectMake(0, 0, 34, 34)
            backBtn.setImage("❌".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backBtn)
            backBtn.addActionHandlers { sender in
                self.returnFrontVC()
            }
            
            let cleanBtn = UIButton(type: .custom)
            cleanBtn.frame = CGRectMake(0, 0, 34, 34)
            cleanBtn.setImage("🗑️".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cleanBtn)
            cleanBtn.addActionHandlers { sender in
                self.clearUserdefults()
            }
        }
        
        self.view.addSubview(self.collectionView)
        self.collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            if self.haveZXbar {
                make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
            } else {
                make.top.equalToSuperview()
            }
        }
        
        self.showDetail()
    }
    
    func showDetail() {
        mSections.removeAll()

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
        
        self.collectionView.pt_register(by: mSections)
        self.collectionView.reloadData()
    }
    
    func clearUserdefults() {
        UIAlertController.base_alertVC(title: "提示",msg: "是否删除所有除系统生成外的数据?",okBtns: ["好的"],cancelBtn: "取消") {
            
        } moreBtn: { index, title in
            let bundleIdentifier = Bundle.main.bundleIdentifier
            
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier!)
            
            self.showDetail()
        }
    }
}

extension PTUserDefultsViewController:UICollectionViewDelegate,UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.mSections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.mSections[section].rows.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let itemSec = mSections[indexPath.section]
        let itemRow = itemSec.rows[indexPath.row]
        let cellModel = (itemRow.dataModel as! PTFusionCellModel)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
        cell.contentView.backgroundColor = .white
        cell.cellModel = cellModel
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let itemSec = mSections[indexPath.section]
        let itemRow = itemSec.rows[indexPath.row]
        let cellModel = (itemRow.dataModel as! PTFusionCellModel)
        let vc = PTUserDefultsEditViewController(viewModel: cellModel)
        self.navigationController?.pushViewController(vc)
        vc.doneBlock = {
            self.showDetail()
        }
    }
}

class PTUserDefultsEditViewController:PTBaseViewController {
    
    private var viewModel:PTFusionCellModel!
    
    var doneBlock:(()->Void)?
    
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
        
        if self.haveZXbar {
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
            self.title = "EditUserDefults"
            
            let cleanBtn = UIButton(type: .custom)
            cleanBtn.frame = CGRectMake(0, 0, 34, 34)
            cleanBtn.setImage("⭕️".emojiToImage(emojiFont: .appfont(size: 16)), for: .normal)
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cleanBtn)
            cleanBtn.addActionHandlers { sender in
                self.saveAction()
            }
        }
        
        self.view.addSubviews([self.keyLabel,self.textInputView])
        self.keyLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
            if self.haveZXbar {
                make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total + 10)
            } else {
                make.top.equalToSuperview().inset(10)
            }
        }
        
        self.textInputView.snp.makeConstraints { make in
            make.left.right.equalTo(self.keyLabel)
            make.top.equalTo(self.keyLabel.snp.bottom).offset(10)
            make.bottom.equalTo(self.view.snp.centerY)
        }
        self.textInputView.bk_placeholder = "value"
    }
    
    func saveAction() {
        UserDefaults.standard.setValue(self.textInputView.text, forKey: self.viewModel.name)
        self.navigationController?.popViewController() {
            if self.doneBlock != nil {
                self.doneBlock!()
            }
        }
    }
}
