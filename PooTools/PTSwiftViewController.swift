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
import TipKit
import AttributedString

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
    
    lazy var newCollectionView : PTCollectionView = {
        let cConfig = PTCollectionViewConfig()
        cConfig.viewType = .Custom
        cConfig.itemOriginalX = PTAppBaseConfig.share.defaultViewSpace
        cConfig.contentTopAndBottom = 0
        cConfig.cellTrailingSpace = 0
        cConfig.cellLeadingSpace = 0
        cConfig.topRefresh = true
        let aaaaaaa = PTCollectionView(viewConfig: cConfig)
                
        aaaaaaa.headerInCollection = { kind,collectionView,model,index in
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.headerID!, for: index) as! PTTestHeader
            header.backgroundColor = .blue
            return header
        }
        aaaaaaa.footerInCollection = { kind,collectionView,model,index in
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: model.footerID!, for: index) as! PTTestFooter
            footer.backgroundColor = .red
            return footer
        }
        aaaaaaa.cellInCollection = { collectionView ,dataModel,indexPath in
            let itemRow = dataModel.rows[indexPath.row]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: itemRow.ID, for: indexPath) as! PTFusionCell
            cell.backgroundColor = .randomColor
            return cell
        }
        aaaaaaa.headerRefreshTask = { sender in
            PTGCDManager.gcdAfter(time: 3) {
                sender.endRefreshing()
            }
        }
        
        aaaaaaa.customerLayout = { sectionModel in
            var bannerGroupSize : NSCollectionLayoutSize
            var customers = [NSCollectionLayoutGroupCustomItem]()
            var groupH:CGFloat = 0
            var cellHeight:CGFloat = 0
            cellHeight = CGFloat.ScaleW(w: 44 + 12.5)
            sectionModel.rows.enumerated().forEach { (index,model) in
                let customItem = NSCollectionLayoutGroupCustomItem.init(frame: CGRect.init(x: cConfig.itemOriginalX, y: groupH, width: CGFloat.kSCREEN_WIDTH - cConfig.itemOriginalX * 2, height: cellHeight), zIndex: 1000+index)
                customers.append(customItem)
                groupH += cellHeight
            }
            bannerGroupSize = NSCollectionLayoutSize.init(widthDimension: NSCollectionLayoutDimension.absolute(CGFloat.kSCREEN_WIDTH - cConfig.itemOriginalX * 2), heightDimension: NSCollectionLayoutDimension.absolute(groupH))
            return NSCollectionLayoutGroup.custom(layoutSize: bannerGroupSize, itemProvider: { layoutEnvironment in
                customers
            })
        }
        return aaaaaaa
    }()
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
//        if #available(iOS 17, *) {
//            self.aaaaaa()
//        } else {
//            // Fallback on earlier versions
//        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        PTNSLogConsole(self)

        self.view.addSubview(newCollectionView)
        newCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        
        
//        let btn = UIButton(type: .custom)
//        btn.backgroundColor = .randomColor
//        view.addSubview(btn)
//        btn.snp.makeConstraints { make in
//            make.width.height.equalTo(100)
//            make.centerX.centerY.equalToSuperview()
//        }
//                
//        btn.addActionHandlers { sender in
//        }
        
//        let ios15Btn = PTLayoutButton()
//        ios15Btn.layoutStyle = .leftImageRightTitle
//        ios15Btn.midSpacing = 0
//        ios15Btn.setTitle("11111", for: .normal)
//        ios15Btn.imageSize = CGSize(width: 12, height: 12)
//        ios15Btn.setImage(UIImage(systemName: "globe"), for: .normal)
//        ios15Btn.addActionHandlers { sender in
//            sender.isSelected = true
//        }
//        view.addSubview(ios15Btn)
//        ios15Btn.snp.makeConstraints { make in
//            make.width.height.equalTo(150)
//            make.centerX.centerY.equalToSuperview()
//        }
    }
    
    func convertPHAssetToAVAsset(phAsset: PHAsset, completion: @escaping (AVAsset?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .original

        PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, _ in
            completion(avAsset)
        }
    }
    
    @available(iOS 17, *)
    func aaaaaa() {
        
//        let attTitle:ASAttributedString = """
//        \(wrap: .embedding("""
//        \("123123123",.foreground(.random),.font(.appfont(size: 16)),.paragraph(.alignment(.center)),.action {
//        PTNSLogConsole("22222222222222222")
//        //        self.aaaaaa()
//                    self.contentUnavailableConfiguration = nil
//        })
//        """))
//        """
//
//        let attBottom:ASAttributedString = """
//        \(wrap: .embedding("""
//        \("123123123123123123123123123123123123123",.foreground(.random),.font(.appfont(size: 16)),.paragraph(.alignment(.center)),.action {
//        PTNSLogConsole("123123123123123123")
//        //        self.aaaaaa()
//                    self.contentUnavailableConfiguration = nil
//        })
//        """))
//        """
//        
//        var emptyConfig = UIContentUnavailableConfiguration.empty()
////        emptyConfig.text = "暂无数据"
//        emptyConfig.attributedText = attBottom.value
//        emptyConfig.image = UIImage(systemName: "exclamationmark.triangle")
//        emptyConfig.secondaryAttributedText = attTitle.value
////        let aaaaa = UIButton(type: .custom)
////        aaaaa.bounds = CGRectMake(0, 0, 100, 100)
////        aaaaa.backgroundColor = .randomColor
//        
//        var plainConfig = UIButton.Configuration.plain()
//        plainConfig.title = "22222222222"
//        plainConfig.titleTextAttributesTransformer = .init({ container in
//            container.merging(AttributeContainer.font(UIFont.appfont(size: 24)).foregroundColor(UIColor.YellowGreenColor))
//        })
////        plainConfig.attributedTitle = AttributedString(stringLiteral: "11111")//NSAttributedString(string: "123123123",attributes: [NSForegroundColorAttributeName:UIColor.red])
//        
//        var filledConfig = UIButton.Configuration.filled()
//        filledConfig.title = "11111"
//        
//        emptyConfig.button = plainConfig
//        emptyConfig.buttonProperties.primaryAction = UIAction() { sender in
//            PTNSLogConsole("123123123123123")
//        }
//        var listB = UIBackgroundConfiguration.clear()
//        listB.backgroundColor = .systemRed
//        
//        emptyConfig.background = listB
//
//        contentUnavailableConfiguration = emptyConfig
        
        self.emptyDataViewConfig = PTEmptyDataViewConfig()
        self.emptyDataViewConfig?.buttonTitle = "123123"
        self.emptyDataViewConfig?.backgroundColor = .BabyBlueColor
        
        self.showEmptyView() {
            PTNSLogConsole("123")
        }

//        let una = UIContentUnavailableView(configuration: emptyConfig)
//        una.frame = UIScreen.main.bounds
//        self.view.addSubview(una)
        
        // 切换UIContentUnavailableConfiguration
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            let loadingConfig = UIContentUnavailableConfiguration.loading()
//            self.contentUnavailableConfiguration = loadingConfig
//        }
//        // 移除UIContentUnavailableConfiguration
//        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
//            self.contentUnavailableConfiguration = nil
//            self.showCollectionViewData()
//        }

    }
    
    func showCollectionViewData() {
        var sections = [PTSection]()
        cellModels().enumerated().forEach { (index,value) in
            var rows = [PTRows]()
            value.enumerated().forEach { subIndex,subValue in
                let row_List = PTRows.init(title: subValue.name, placeholder: subValue.content,cls: PTFusionCell.self, ID: PTFusionCell.ID, dataModel: subValue)
                rows.append(row_List)
            }
            let cellSection = PTSection.init(headerTitle: "123123123123",headerCls: PTTestHeader.self,headerID: PTTestHeader.ID,footerCls: PTTestFooter.self,footerID: PTTestFooter.ID,footerHeight: 44,headerHeight: 44, rows: rows)
            sections.append(cellSection)
        }
        self.newCollectionView.layoutIfNeeded()
        self.newCollectionView.showCollectionDetail(collectionData: sections)
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

@available(iOS 17, *)
#Preview {
    PTSwiftViewController()
}
