//
//  PTDarkModeControl.swift
//  PTChatGPT
//
//  Created by 邓杰豪 on 20/3/23.
//  Copyright © 2023 SexyBoy. All rights reserved.
//

import UIKit
import SnapKit
#if POOTOOLS_NAVBARCONTROLLER
import ZXNavigationBar
#endif
import SwifterSwift

@objcMembers
public class PTDarkModeControl: PTBaseViewController {

    private var darkTime: String = PTDarkModeOption.smartPeelingTimeIntervalValue
    
    open var themeSetBlock: PTActionTask?

    lazy var darkModeControlArr : [[PTFusionCellModel]] = {
        let smart = PTFusionCellModel()
        smart.name = "PT Theme smart".localized()
        smart.nameColor = PTAppBaseConfig.share.viewDefaultTextColor
        smart.accessoryType = .Switch
        
        let followSystem = PTFusionCellModel()
        followSystem.name = "PT Theme follow system".localized()
        followSystem.nameColor = PTAppBaseConfig.share.viewDefaultTextColor
        followSystem.accessoryType = .Switch

        return [[smart],[followSystem]]
    }()
    
    var mSections = [PTSection]()
    
    lazy var newCollectionView : PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Custom
        cConfig.itemHeight = PTAppBaseConfig.share.baseCellHeight
        cConfig.topRefresh = false
        cConfig.customReuseViews = true
        let view = PTCollectionView(viewConfig: cConfig)
            
        view.customerReuseViews = { index,sectionModel in
            var items = [NSCollectionLayoutBoundarySupplementaryItem]()
            let screenW:CGFloat = CGFloat.kSCREEN_WIDTH
            if sectionModel.headerID == PTDarkModeHeader.ID {
                let headerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenW), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel.headerHeight ?? CGFloat.leastNormalMagnitude))
                let headerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .topTrailing)
                
                let footerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenW), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel.footerHeight ?? CGFloat.leastNormalMagnitude))
                let footerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottomTrailing)

                if PTDarkModeOption.isSmartPeeling {
                    items = [headerItem,footerItem]
                } else {
                    items = [headerItem]
                }
            } else if sectionModel.footerID == PTDarkFollowSystemFooter.ID {
                let footerSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenW), heightDimension: NSCollectionLayoutDimension.absolute(sectionModel.footerHeight ?? CGFloat.leastNormalMagnitude))
                let footerItem = NSCollectionLayoutBoundarySupplementaryItem.init(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottomTrailing)
                items = [footerItem]
            }
            return items
        }
        view.customerLayout = { sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            var groupH:CGFloat = 0
            let screenW:CGFloat = CGFloat.kSCREEN_WIDTH
            var cellHeight:CGFloat = 0
            if Gobal_device_info.isPad {
                cellHeight = 64
            } else {
                cellHeight = CGFloat.ScaleW(w: 44)
            }
            sectionModel.rows.enumerated().forEach { (index,model) in
                let cellHeight:CGFloat = cellHeight
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: PTAppBaseConfig.share.defaultViewSpace, y: groupH, width: screenW - PTAppBaseConfig.share.defaultViewSpace * 2, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupH += cellHeight
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(screenW - PTAppBaseConfig.share.defaultViewSpace * 2), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        view.headerInCollection = { kind,collectionView,model,index in
            if model.headerID == PTDarkModeHeader.ID {
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as! PTDarkModeHeader
                header.currentMode = PTDarkModeOption.isLight ? .light : .dark
                header.selectModeBlock = { mode in
                    PTDarkModeOption.setDarkModeCustom(isLight: mode == .light ? true : false)
                    self.showDetail()
                    if self.themeSetBlock != nil {
                        self.themeSetBlock!()
                    }
                }
                return header
            }
            return nil
        }
        view.footerInCollection = { kind,collectionView,itemSec,indexPath in
            if itemSec.footerID == PTDarkSmartFooter.ID {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: itemSec.footerID!, for: indexPath) as! PTDarkSmartFooter
                footer.themeTimeButton.normalTitle = self.darkTime
                footer.themeTimeButton.addActionHandlers { sender in
                    let timeIntervalValue = PTDarkModeOption.smartPeelingTimeIntervalValue.separatedByString(with: "~")
                    let darkModePickerView = PTDarkModePickerView(startTime: timeIntervalValue[0], endTime: timeIntervalValue[1]) { (startTime, endTime) in
                        
                        if startTime == endTime {
                            PTBaseViewController.gobal_drop(title: "PT Theme time set error".localized())
                        } else {
                            PTDarkModeOption.setSmartPeelingTimeChange(startTime: startTime, endTime: endTime)
                            self.darkTime = startTime + "~" + endTime
                            self.showDetail()
                        }
                    }
                    darkModePickerView.showTime()
                }
                return footer
            } else if itemSec.footerID == PTDarkFollowSystemFooter.ID {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: itemSec.footerID!, for: indexPath) as! PTDarkFollowSystemFooter
                return footer
            }
            return nil
        }
        view.cellInCollection = { collectionView ,dataModel,indexPath in
            let itemRow = dataModel.rows[indexPath.row]
            let cellModel = (itemRow.dataModel as! PTFusionCellModel)
            if itemRow.ID == PTFusionCell.ID {
                let cellModel = (itemRow.dataModel as! PTFusionCellModel)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
                cell.cellModel = cellModel
                cell.hideBottomLine = indexPath.row == (dataModel.rows.count - 1) ? true : false
                cell.hideTopLine = true
                cell.contentView.backgroundColor = PTAppBaseConfig.share.baseCellBackgroundColor
                if cellModel.name == "PT Theme smart".localized() {
                    cell.switchValue = PTDarkModeOption.isSmartPeeling
                    PTGCDManager.gcdMain {
                        cell.contentView.viewCornerRectCorner(cornerRadii: 5, corner: [.topLeft,.topRight])
                    }
                } else if cellModel.name == "PT Theme follow system".localized() {
                    cell.switchValue = PTDarkModeOption.isFollowSystem
                    PTGCDManager.gcdMain {
                        cell.contentView.viewCornerRectCorner(cornerRadii: 5, corner: [.bottomLeft,.bottomRight])
                    }
                }
                cell.switchValueChangeBlock = { title,sender in
                    if cellModel.name == "PT Theme smart".localized() {
                        PTDarkModeOption.setSmartPeelingDarkMode(isSmartPeeling: sender.isOn)
                        self.showDetail()
                    } else if cellModel.name == "PT Theme follow system".localized() {
                        PTDarkModeOption.setDarkModeFollowSystem(isFollowSystem: sender.isOn)
                        self.showDetail()
                    }
                    if self.themeSetBlock != nil {
                        self.themeSetBlock!()
                    }
                }
                return cell
            }
            return nil
        }
        return view
    }()
    
    lazy var backButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage("❌".emojiToImage(emojiFont: .appfont(size: 20)), for: .normal)
        view.addActionHandlers { sender in
            self.returnFrontVC()
        }
        return view
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()

#if POOTOOLS_NAVBARCONTROLLER
        self.zx_navTitle = "PT Theme title".localized()
        
        if checkVCIsPresenting() {
            zx_navBar?.addSubviews([backButton])
            backButton.snp.makeConstraints { make in
                make.size.equalTo(34)
                make.left.equalToSuperview().inset(PTAppBaseConfig.share.defaultViewSpace)
                make.bottom.equalToSuperview().inset(5)
            }
        }
#else
        title = "PT Theme title".localized()
        
        if checkVCIsPresenting() {
            backButton.frame = CGRectMake(0, 0, 34, 34)
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
        }
#endif
        // Do any additional setup after loading the view.
        view.addSubviews([newCollectionView])
        newCollectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
#if POOTOOLS_NAVBARCONTROLLER
            make.top.equalToSuperview().inset(CGFloat.kNavBarHeight_Total)
#else
            make.top.equalToSuperview()
#endif
        }
        apply()
    }
    
    func showDetail() {
        mSections.removeAll()

        darkModeControlArr.enumerated().forEach { (index,value) in
            var rows = [PTRows]()
            value.enumerated().forEach { subIndex,subValue in
                let row = PTRows(cls:PTFusionCell.self,ID: PTFusionCell.ID,dataModel: subValue)
                rows.append(row)
            }
            switch index {
            case 0:
                var sections:PTSection
                if PTDarkModeOption.isSmartPeeling {
                    sections = PTSection(headerCls: PTDarkModeHeader.self,headerID: PTDarkModeHeader.ID,footerCls: PTDarkSmartFooter.self,footerID: PTDarkSmartFooter.ID,footerHeight: PTDarkSmartFooter.footerTotalHeight,headerHeight: PTDarkModeHeader.contentHeight + 10, rows: rows)
                } else {
                    sections = PTSection(headerCls: PTDarkModeHeader.self,headerID: PTDarkModeHeader.ID,headerHeight: PTDarkModeHeader.contentHeight + 10, rows: rows)
                }
                mSections.append(sections)
            case 1:
                var sections:PTSection
                if PTDarkModeOption.isFollowSystem {
                    sections = PTSection(footerCls: PTDarkFollowSystemFooter.self,footerID: PTDarkFollowSystemFooter.ID,footerHeight: PTDarkFollowSystemFooter.footerHeight, rows: rows)
                } else {
                    sections = PTSection(rows: rows)
                }
                mSections.append(sections)
            default:break
            }
        }
        
        newCollectionView.showCollectionDetail(collectionData: mSections)
    }
}

extension PTDarkModeControl: PTThemeable {
    public func apply() {
        showDetail()
        PTGCDManager.gcdMain {
            let type:VCStatusBarChangeStatusType = PTDarkModeOption.isLight ? .Light : .Dark
            self.changeStatusBar(type: type)
            self.view.backgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
            self.showDetail()
#if POOTOOLS_NAVBARCONTROLLER
            self.zx_navTitleColor = PTAppBaseConfig.share.navTitleTextColor
            self.zx_navBarBackgroundColor = PTAppBaseConfig.share.viewControllerBaseBackgroundColor
#else
            PTBaseNavControl.GobalNavControl(nav: self.navigationController!)
#endif
        }
    }
}

#if POOTOOLS_ROUTER
extension PTDarkModeControl:PTRouterable {
    public static var priority: UInt {
        PTRouterDefaultPriority
    }

    public static var patternString: [String] {
        ["scheme://route/darkmode"]
    }
    
    public static func registerAction(info: [String : Any]) -> Any {
        let vc = PTDarkModeControl()
        return vc
    }
}
#endif
