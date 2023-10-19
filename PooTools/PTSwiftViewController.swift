//
//  PTSwiftViewController.swift
//  PooTools_Example
//
//  Created by jax on 2022/10/3.
//  Copyright © 2022 crazypoo. All rights reserved.
//

import CommonCrypto
import CryptoSwift
import SnapKit
import UIKit
import AnyImageKit
import Photos
import Combine

#if canImport(LifetimeTracker)
import LifetimeTracker
#endif

class PTSwiftViewController: PTBaseViewController {
    
    private var videoEdit: PTVideoEdit?
    fileprivate var cancellables = Set<AnyCancellable>()

    lazy var cycleView: LLCycleScrollView = {
        
        let banner = LLCycleScrollView.llCycleScrollViewWithFrame(.zero)
//        banner.delegate = self
        // 滚动间隔时间(默认为2秒)
        banner.autoScrollTimeInterval = 3.0
        // 等待数据状态显示的占位图
        banner.placeHolderImage = PTAppBaseConfig.share.defaultPlaceholderImage
        // 如果没有数据的时候，使用的封面图
        banner.coverImage = PTAppBaseConfig.share.defaultPlaceholderImage
        // 设置图片显示方式=UIImageView的ContentMode
        banner.imageViewContentMode = .scaleAspectFill
        banner.viewCorner(radius: 10)
        // 设置当前PageControl的样式 (.none, .system, .fill, .pill, .snake)
        banner.customPageControlStyle = .pill
        // 非.system的状态下，设置PageControl的tintColor
        banner.customPageControlInActiveTintColor = UIColor.lightGray
        // 设置.system系统的UIPageControl当前显示的颜色
        banner.pageControlCurrentPageColor = UIColor.white
        // 非.system的状态下，设置PageControl的间距(默认为8.0)
        banner.customPageControlIndicatorPadding = 5.0
        // 设置PageControl的位置 (.left, .right 默认为.center)
        banner.pageControlPosition = .center
        // 圆角
        banner.backgroundColor = .clear
        return banner
    }()
    
    class var lifetimeConfiguration: LifetimeConfiguration {
        LifetimeConfiguration(maxCount: 1, groupName: "VC")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
#if canImport(LifetimeTracker)
        trackLifetime()
#endif
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func cellModels() -> [[PTFusionCellModel]] {
        
        let disclosureIndicatorImageName = "➡️".emojiToImage(emojiFont: .appfont(size: 14))
        let nameFont:UIFont = .appfont(size: 16,bold: true)

        let onlyLeft = PTFusionCellModel()
        onlyLeft.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeft.accessoryType = .NoneAccessoryView
        onlyLeft.nameColor = .black
        onlyLeft.cellFont = nameFont
        
        let onlyLeftRight = PTFusionCellModel()
        onlyLeftRight.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight.accessoryType = .NoneAccessoryView
        onlyLeftRight.nameColor = .black
        onlyLeftRight.cellFont = nameFont

        let onlyLeft_a = PTFusionCellModel()
        onlyLeft_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeft_a.accessoryType = .DisclosureIndicator
        onlyLeft_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyLeft_a.nameColor = .black
        onlyLeft_a.cellFont = nameFont

        let onlyRight_a = PTFusionCellModel()
        onlyRight_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyRight_a.accessoryType = .DisclosureIndicator
        onlyRight_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyRight_a.nameColor = .black
        onlyRight_a.cellFont = nameFont

        let onlyRight = PTFusionCellModel()
        onlyRight.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyRight.accessoryType = .NoneAccessoryView
        onlyRight.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyRight.nameColor = .black
        onlyRight.cellFont = nameFont

        let onlyLeftRight_a = PTFusionCellModel()
        onlyLeftRight_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_a.accessoryType = .DisclosureIndicator
        onlyLeftRight_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyLeftRight_a.nameColor = .black
        onlyLeftRight_a.cellFont = nameFont

        let onlyLeftRight_n_a = PTFusionCellModel()
        onlyLeftRight_n_a.name = "左标题"
        onlyLeftRight_n_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_n_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_n_a.accessoryType = .DisclosureIndicator
        onlyLeftRight_n_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyLeftRight_n_a.nameColor = .black
        onlyLeftRight_n_a.cellFont = nameFont

        let onlyLeftRight_nc_a = PTFusionCellModel()
        onlyLeftRight_nc_a.name = "左标题"
        onlyLeftRight_nc_a.content = "右标题"
        onlyLeftRight_nc_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_nc_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_nc_a.accessoryType = .DisclosureIndicator
        onlyLeftRight_nc_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyLeftRight_nc_a.nameColor = .black
        onlyLeftRight_nc_a.cellFont = nameFont

        let onlyLeftRight_nd_a = PTFusionCellModel()
        onlyLeftRight_nd_a.name = "左标题"
        onlyLeftRight_nd_a.desc = "底部标题"
        onlyLeftRight_nd_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_nd_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_nd_a.accessoryType = .DisclosureIndicator
        onlyLeftRight_nd_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyLeftRight_nd_a.nameColor = .black
        onlyLeftRight_nd_a.cellFont = nameFont

        let onlyLeftRight_c_a = PTFusionCellModel()
        onlyLeftRight_c_a.content = "右边标题"
        onlyLeftRight_c_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_c_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeftRight_c_a.accessoryType = .DisclosureIndicator
        onlyLeftRight_c_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyLeftRight_c_a.nameColor = .black
        onlyLeftRight_c_a.cellFont = nameFont

        let onlyRight_n_a = PTFusionCellModel()
        onlyRight_n_a.name = "左标题"
        onlyRight_n_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyRight_n_a.accessoryType = .DisclosureIndicator
        onlyRight_n_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyRight_n_a.nameColor = .black
        onlyRight_n_a.cellFont = nameFont

        let onlyRight_nc_a = PTFusionCellModel()
        onlyRight_nc_a.name = "左标题"
        onlyRight_nc_a.content = "右标题"
        onlyRight_nc_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyRight_nc_a.accessoryType = .DisclosureIndicator
        onlyRight_nc_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyRight_nc_a.nameColor = .black
        onlyRight_nc_a.cellFont = nameFont

        let onlyRight_nd_a = PTFusionCellModel()
        onlyRight_nd_a.name = "左标题"
        onlyRight_nd_a.desc = "底部标题"
        onlyRight_nd_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyRight_nd_a.accessoryType = .DisclosureIndicator
        onlyRight_nd_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyRight_nd_a.nameColor = .black
        onlyRight_nd_a.cellFont = nameFont

        let onlyRight_c_a = PTFusionCellModel()
        onlyRight_c_a.content = "右边标题"
        onlyRight_c_a.contentIcon = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyRight_c_a.accessoryType = .DisclosureIndicator
        onlyRight_c_a.disclosureIndicatorImage = disclosureIndicatorImageName
        onlyRight_c_a.nameColor = .black
        onlyRight_c_a.cellFont = nameFont

        let only_n_a = PTFusionCellModel()
        only_n_a.name = "左标题"
        only_n_a.nameColor = .black
        only_n_a.cellFont = nameFont

        let only_nc_a = PTFusionCellModel()
        only_nc_a.name = "左标题"
        only_nc_a.content = "右标题"
        only_nc_a.nameColor = .black
        only_nc_a.cellFont = nameFont

        let only_nd_a = PTFusionCellModel()
        only_nd_a.name = "左标题"
        only_nd_a.desc = "底部标题"
        only_nd_a.nameColor = .black
        only_nd_a.cellFont = nameFont

        let only_c_a = PTFusionCellModel()
        only_c_a.content = "右边标题"
        only_c_a.nameColor = .black
        only_c_a.cellFont = nameFont

        let onlyLeft_n_a = PTFusionCellModel()
        onlyLeft_n_a.name = "左标题"
        onlyLeft_n_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeft_n_a.nameColor = .black
        onlyLeft_n_a.cellFont = nameFont

        let onlyLeft_nc_a = PTFusionCellModel()
        onlyLeft_nc_a.name = "左标题"
        onlyLeft_nc_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeft_nc_a.content = "右标题"
        onlyLeft_nc_a.nameColor = .black
        onlyLeft_nc_a.cellFont = nameFont

        let onlyLeft_nd_a = PTFusionCellModel()
        onlyLeft_nd_a.name = "左标题"
        onlyLeft_nd_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeft_nd_a.desc = "底部标题"
        onlyLeft_nd_a.nameColor = .black
        onlyLeft_nd_a.cellFont = nameFont

        let onlyLeft_c_a = PTFusionCellModel()
        onlyLeft_c_a.content = "右边标题"
        onlyLeft_c_a.leftImage = "🧐".emojiToImage(emojiFont: .appfont(size: 24))
        onlyLeft_c_a.nameColor = .black
        onlyLeft_c_a.cellFont = nameFont

        return [[onlyLeft,onlyLeftRight,onlyLeft_a,onlyRight_a,onlyRight],[onlyLeftRight_n_a,onlyLeftRight_nc_a,onlyLeftRight_nd_a,onlyLeftRight_c_a,onlyRight_n_a,onlyRight_nc_a,onlyRight_nd_a,onlyRight_c_a],[only_n_a,only_nc_a,only_nd_a,only_c_a],[onlyLeft_n_a,onlyLeft_nc_a,onlyLeft_nd_a,onlyLeft_c_a]]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        PTNSLogConsole(self)
                           
//        let cConfig = PTCollectionViewConfig()
//        cConfig.viewType = .Custom
//        cConfig.itemOriginalX = PTAppBaseConfig.share.defaultViewSpace
//        cConfig.contentTopAndBottom = 0
//        cConfig.cellTrailingSpace = 0
//        cConfig.cellLeadingSpace = 0
//        cConfig.topRefresh = true
//        let aaaaaaa = PTCollectionView(viewConfig: cConfig)
//        
//        var sections = [PTSection]()
//        cellModels().enumerated().forEach { (index,value) in
//            var rows = [PTRows]()
//            value.enumerated().forEach { subIndex,subValue in
//                let row_List = PTRows.init(title: subValue.name, placeholder: subValue.content,cls: PTFusionCell.self, ID: PTFusionCell.ID, dataModel: subValue)
//                rows.append(row_List)
//            }
//            let cellSection = PTSection.init(headerTitle: "123123123123",headerCls: PTTestHeader.self,headerID: PTTestHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: rows)
//            sections.append(cellSection)
//        }
//        
//        aaaaaaa.headerInCollection = { kind,collectionView,model,index in
//            
//            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as! PTTestHeader
//            header.backgroundColor = .blue
//            return header
//        }
//        aaaaaaa.footerInCollection = { kind,collectionView,model,index in
//            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.footerID!, for: index) as! PTTestFooter
//            footer.backgroundColor = .red
//            return footer
//        }
//        aaaaaaa.cellInCollection = { collectionView ,dataModel,indexPath in
//            let itemRow = dataModel.rows[indexPath.row]
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
//            cell.backgroundColor = .randomColor
//            return cell
//        }
//        aaaaaaa.headerRefreshTask = { sender in
//            PTGCDManager.gcdAfter(time: 3) {
//                sender.endRefreshing()
//            }
//        }
//        
//        aaaaaaa.customerLayout = { sectionModel in
//            var bannerGroupSize : NSCollectionLayoutSize
//            var customers = [NSCollectionLayoutGroupCustomItem]()
//            var groupH:CGFloat = 0
//            var cellHeight:CGFloat = 0
//            cellHeight = CGFloat.ScaleW(w: 44 + 12.5)
//            sectionModel.rows.enumerated().forEach { (index,model) in
//                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: cConfig.itemOriginalX, y: groupH, width: CGFloat.kSCREEN_WIDTH - cConfig.itemOriginalX * 2, height: cellHeight), zIndex: 1000+index)
//                customers.append(customItem)
//                groupH += cellHeight
//            }
//            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(CGFloat.kSCREEN_WIDTH - cConfig.itemOriginalX * 2), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
//            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
//                customers
//            })
//        }
//
//        self.view.addSubview(aaaaaaa)
//        aaaaaaa.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        aaaaaaa.layoutIfNeeded()
//        aaaaaaa.showCollectionDetail(collectionData: sections)

        
        let btn = UIButton(type: .custom)
        btn.backgroundColor = .randomColor
        view.addSubview(btn)
        btn.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.centerX.centerY.equalToSuperview()
        }
        btn.addActionHandlers { sender in
            
            let bt = PTPermissionModel()
            bt.type = .bluetooth
            bt.name = "123123123"
            bt.desc = "33333333"
            
            let calendarF = PTPermissionModel()
            calendarF.type = .calendar(access: .full)
            calendarF.name = "123123123"
            calendarF.desc = "33333333"

            let calendarW = PTPermissionModel()
            calendarW.type = .calendar(access: .write)
            calendarW.name = "123123123"
            calendarW.desc = "33333333"

            let camera = PTPermissionModel()
            camera.type = .camera
            camera.name = "123123123"
            camera.desc = "33333333"

            let contacts = PTPermissionModel()
            contacts.type = .contacts
            contacts.name = "123123123"
            contacts.desc = "33333333"

            let faceID = PTPermissionModel()
            faceID.type = .faceID
            faceID.name = "123123123"
            faceID.desc = "33333333"

            let health = PTPermissionModel()
            health.type = .health
            health.name = "123123123"
            health.desc = "33333333"

            let locationA = PTPermissionModel()
            locationA.type = .location(access: .always)
            locationA.name = "123123123"
            locationA.desc = "33333333"

            let locationW = PTPermissionModel()
            locationW.type = .location(access: .whenInUse)
            locationW.name = "123123123"
            locationW.desc = "33333333"

            let media = PTPermissionModel()
            media.type = .mediaLibrary
            media.name = "123123123"
            media.desc = "33333333"

            let mic = PTPermissionModel()
            mic.type = .microphone
            mic.name = "123123123"
            mic.desc = "33333333"

            let motion = PTPermissionModel()
            motion.type = .motion
            motion.name = "123123123"
            motion.desc = "33333333"

            let notification = PTPermissionModel()
            notification.type = .notification
            notification.name = "123123123"
            notification.desc = "33333333"

            let photo = PTPermissionModel()
            photo.type = .photoLibrary
            photo.name = "123123123"
            photo.desc = "33333333"

            let reminders = PTPermissionModel()
            reminders.type = .reminders
            reminders.name = "123123123"
            reminders.desc = "33333333"

            let siri = PTPermissionModel()
            siri.type = .siri
            siri.name = "123123123"
            siri.desc = "33333333"

            let speech = PTPermissionModel()
            speech.type = .speech
            speech.name = "123123123"
            speech.desc = "33333333"

            let tracking = PTPermissionModel()
            tracking.type = .tracking
            tracking.name = "123123123"
            tracking.desc = "33333333"

            let aaaaa = PTPermissionViewController(datas: [bt,calendarF,calendarW,camera,contacts,faceID,health,locationA,locationW,media,mic,motion,notification,photo,reminders,siri,speech,tracking])
//            let nav = PTBaseNavControl(rootViewController: aaaaa)
            self.present(aaaaa, animated: true)
        }
    }
    
    func convertPHAssetToAVAsset(phAsset: PHAsset, completion: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original

        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, _ in
            completion(avAsset)
        }
    }
}

extension PTSwiftViewController: PTRouterable {
    
    static var patternString: [String] {
        ["scheme://router/demo"]
    }
    
    static var descriptions: String {
        "PTSwiftViewController"
    }
    
    static func registerAction(info: [String : Any]) -> Any {
        PTNSLogConsole("Router info:\(info)")
        let vc =  PTSwiftViewController()
        return vc
    }
}

// MARK: - ImagePickerControllerDelegate
extension PTSwiftViewController: ImagePickerControllerDelegate {
    
    func imagePicker(_ picker: ImagePickerController, didFinishPicking result: PickerResult) {
        PTNSLogConsole(result.assets.first!.image)
        
        picker.dismiss(animated: true, completion: nil)

        convertPHAssetToAVAsset(phAsset: result.assets.first!.phAsset) { avAsset in
            if let avAsset = avAsset {
                PTGCDManager.gcdMain {
                    let controller = PTVideoEditorVideoEditorViewController(asset: avAsset, videoEdit: self.videoEdit)
                    controller.onEditCompleted
                        .sink {  editedPlayerItem, videoEdit in
                            self.videoEdit = videoEdit
                            
//                            self.saveVideoToCache(playerItem: editedPlayerItem) { finish in
//                                if finish {
//                                    UIImage.pt.getVideoFirstImage(videoUrl: self.outputURL.description) { images in
//                                        self.resultImageView.image = images
//                                    }
//                                }
//                            }
                        }
                        .store(in: &self.cancellables)
                    let nav = PTBaseNavControl(rootViewController: controller)
                    nav.modalPresentationStyle = .fullScreen
                    self.navigationController?.present(nav, animated: true)
                }
            } else {
                PTNSLogConsole("123", error: false)
            }
        }
    }
}

// MARK: - ImageKitDataTrackDelegate
extension PTSwiftViewController: ImageKitDataTrackDelegate {
    
    func dataTrack(page: AnyImagePage, state: AnyImagePageState) {
        switch state {
        case .enter:
            PTNSLogConsole("[Data Track] ENTER Page: \(page.rawValue)")
        case .leave:
            PTNSLogConsole("[Data Track] LEAVE Page: \(page.rawValue)")
        }
    }
    
    func dataTrack(event: AnyImageEvent, userInfo: [AnyImageEventUserInfoKey: Any]) {
        PTNSLogConsole("[Data Track] EVENT: \(event.rawValue), userInfo: \(userInfo)")
    }
}
