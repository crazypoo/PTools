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
import MBProgressHUD

#if canImport(LifetimeTracker)
import LifetimeTracker
#endif

let shareText = "我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡我是辣鸡"
let shareURLString = "https://www.github.com/crazypoo"

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
        
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        PTNSLogConsole(self)

        let layoutBtn = PTLayoutButton()
        layoutBtn.layoutStyle = .leftImageRightTitle
        layoutBtn.setTitle("123", for: .normal)
        layoutBtn.midSpacing = 0
        layoutBtn.imageSize = CGSizeMake(100, 100)
        
        layoutBtn.backgroundColor = .systemBlue
        view.addSubview(layoutBtn)
        layoutBtn.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.centerX.centerY.equalToSuperview()
        }
        
        PTGCDManager.gcdMain {
            layoutBtn.layerProgress(value: 0.5,borderWidth: 4)
        }
        
        layoutBtn.addActionHandlers { sender in
        }
                
        self.screenShotHandle = { image in
        }
    }    
}

extension PTSwiftViewController:PTRouterable {
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

@available(iOS 17, *)
#Preview {
    PTSwiftViewController()
}
