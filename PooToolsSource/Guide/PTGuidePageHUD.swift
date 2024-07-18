//
//  PTGuidePageHUD.swift
//  Diou
//
//  Created by ken lam on 2021/10/16.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import AVKit
import SnapKit
import SwifterSwift
import Kingfisher

/*
 Guide初始配置
 */
@objcMembers
public class PTGuidePageModel: NSObject {
    ///是否显示开始体验
    open var tapHidden:Bool = false
    ///图片s
    open var imageArrays:[Any] = []
    ///展示在X
    open var mainView:UIView = UIView()
    ///是否显示Pagecontrol
    open var pageControl:PTGuidePageControlSelection = .pageControl(type: .system)
    ///是否显示跳过按钮
    open var skipShow:Bool = false
    ///上一张按钮图片
    open var forwardImage:Any?
    ///下一张按钮图片
    open var backImage:Any?
    ///开始体验按钮背景
    open var startBackgroundImage:UIImage = UIColor.randomColor.createImageWithColor()
    ///开始体验按钮字体颜色
    open var startTextColor:UIColor = UIColor.randomColor
    ///iCloud文件夹名字
    open var iCloudDocumentName:String = ""
        /// 未选中颜色
    open var pageControlTintColor: UIColor = UIColor.lightGray
    /// 选中颜色
    open var pageControlCurrentPageColor: UIColor = UIColor.white
    ///  圆角(.fill,.snake)
    open var fillPageControlIndicatorRadius: CGFloat = 4
    /// 选中颜色(.pill,.snake)
    open var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3)
    /// 普通图片(.system)
    open var pageControlActiveImage: Any? = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive")
    /// 选中图片(.system)
    open var pageControlInActiveImage: Any? = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive")
    /// 自定义Pagecontrol普通颜色
    open var customPageControlTintColor: UIColor = UIColor.white
    /// 自定义Pagecontrol点阵边距
    open var customPageControlIndicatorPadding: CGFloat = 8

    public enum PTGuidePageControlSelection {
        case none
        case pageControl(type:PTGuidePageControlOption)
        
        public enum PTGuidePageControlOption {
            case system
            case fill
            case pill
            case snake
            case image
            case scrolling
        }
    }
}

@objcMembers
public class PTGuidePageHUD: UIView {
    fileprivate var imageArray : [Any]?
    fileprivate var imagePageControl:UIView?
    fileprivate var slideIntoNumber : Int = 0
    fileprivate var player = AVPlayerViewController()
    
    open var slideInto : Bool? = false
    open var animationTime : CGFloat = 3.0
    open var adHadRemove:PTActionTask?
    
    let StartString = "PT Guide start".localized()
    
    lazy var forwardButton:UIButton = {
        let btn = UIButton.init(type: .custom)
        return btn
    }()
    
    lazy var nextButton:UIButton = {
        let btn = UIButton.init(type: .custom)
        return btn
    }()
    
    fileprivate var viewModel = PTGuidePageModel()
    
    public init(viewModel:PTGuidePageModel) {
        super.init(frame: viewModel.mainView.frame)
        self.viewModel = viewModel
        if viewModel.tapHidden {
            imageArray = viewModel.imageArrays
        }
        
        let guidePageView = UIScrollView()
        guidePageView.backgroundColor = .lightGray
        guidePageView.contentSize = CGSize.init(width: CGFloat.kSCREEN_WIDTH * CGFloat(viewModel.imageArrays.count), height: CGFloat.kSCREEN_HEIGHT)
        guidePageView.bounces = false
        guidePageView.isPagingEnabled = true
        guidePageView.showsHorizontalScrollIndicator = false
        guidePageView.delegate = self
        addSubview(guidePageView)
        guidePageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let skipButton = UIButton.init(type: .custom)
        skipButton.setTitle("PT Button skip".localized(), for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 14)
        skipButton.backgroundColor = .gray
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.layer.cornerRadius =  skipButton.frame.height * 0.5
        skipButton.addActionHandlers { sender in
            self.buttonClick(sender: sender)
        }
        addSubview(skipButton)
        skipButton.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(25)
            make.right.equalToSuperview().inset(10)
            make.top.equalToSuperview().inset(CGFloat.statusBarHeight() + 10)
        }
        skipButton.isHidden = viewModel.skipShow ? false : true
        skipButton.isUserInteractionEnabled = viewModel.skipShow
        
        viewModel.imageArrays.enumerated().forEach { (index,value) in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            
            let contentData = viewModel.imageArrays[index]
            imageView.loadImage(contentData: contentData,iCloudDocumentName: viewModel.iCloudDocumentName)
            guidePageView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.width.equalTo(CGFloat.kSCREEN_WIDTH)
                make.height.equalTo(CGFloat.kSCREEN_HEIGHT)
                make.left.equalToSuperview().inset(CGFloat.kSCREEN_WIDTH * CGFloat(index))
            }
            
            if index == (viewModel.imageArrays.count - 1) && !viewModel.tapHidden {
                imageView.isUserInteractionEnabled = true
                
                let startButton = UIButton(type: .custom)
                startButton.setTitle(StartString, for: .normal)
                startButton.setTitleColor(viewModel.startTextColor, for: .normal)
                startButton.titleLabel?.font = .systemFont(ofSize: 21)
                startButton.setBackgroundImage(viewModel.startBackgroundImage, for: .normal)
                startButton.addActionHandlers { sender in
                    self.buttonClick(sender: sender)
                }
                imageView.addSubview(startButton)
                startButton.snp.makeConstraints { make in
                    make.width.equalTo(100)
                    make.height.equalTo(44)
                    make.centerX.equalTo(imageView)
                    make.bottom.equalTo(imageView).inset(CGFloat.kTabbarSaveAreaHeight + 40)
                }
            }
        }
        
        switch viewModel.pageControl {
        case .none:
            break
        case .pageControl(let type):
            switch type {
            case .system:
                imagePageControl = UIPageControl.init()
                (imagePageControl as! UIPageControl).pageIndicatorTintColor = viewModel.pageControlTintColor
                (imagePageControl as! UIPageControl).currentPageIndicatorTintColor = viewModel.pageControlCurrentPageColor
                (imagePageControl as! UIPageControl).currentPage = 0
                (imagePageControl as! UIPageControl).numberOfPages = viewModel.imageArrays.count
                addSubview(imagePageControl!)
                (imagePageControl as! UIPageControl).addPageControlHandlers { sender in
                    if viewModel.imageArrays.count == (sender.currentPage + 1) {
                        self.buttonClick(sender: nil)
                    } else {
                        guidePageView.contentOffset.x = guidePageView.contentOffset.x + guidePageView.frame.size.width
                    }
                }
            case .fill:
                imagePageControl = PTFilledPageControl.init(frame: CGRect.zero)
                (imagePageControl as! PTFilledPageControl).tintColor = viewModel.customPageControlTintColor
                (imagePageControl as! PTFilledPageControl).indicatorPadding = viewModel.customPageControlIndicatorPadding
                (imagePageControl as! PTFilledPageControl).indicatorRadius = viewModel.fillPageControlIndicatorRadius
                (imagePageControl as! PTFilledPageControl).progress = 0
                (imagePageControl as! PTFilledPageControl).pageCount = viewModel.imageArrays.count
                addSubview(imagePageControl!)
            case .pill:
                imagePageControl = PTPillPageControl.init(frame: CGRect.zero)
                (imagePageControl as! PTPillPageControl).indicatorPadding = viewModel.customPageControlIndicatorPadding
                (imagePageControl as! PTPillPageControl).activeTint = viewModel.customPageControlTintColor
                (imagePageControl as! PTPillPageControl).inactiveTint = viewModel.customPageControlInActiveTintColor
                (imagePageControl as! PTPillPageControl).pageCount = viewModel.imageArrays.count
                (imagePageControl as! PTPillPageControl).progress = 0
                addSubview(imagePageControl!)
            case .snake:
                imagePageControl = PTSnakePageControl.init(frame: CGRect.zero)
                (imagePageControl as! PTSnakePageControl).activeTint = viewModel.customPageControlTintColor
                (imagePageControl as! PTSnakePageControl).indicatorPadding = viewModel.customPageControlIndicatorPadding
                (imagePageControl as! PTSnakePageControl).indicatorRadius = viewModel.fillPageControlIndicatorRadius
                (imagePageControl as! PTSnakePageControl).inactiveTint = viewModel.customPageControlInActiveTintColor
                (imagePageControl as! PTSnakePageControl).pageCount = viewModel.imageArrays.count
                (imagePageControl as! PTSnakePageControl).progress = 0
                addSubview(imagePageControl!)
            case .image:
                imagePageControl = PTImagePageControl()
                (imagePageControl as! PTImagePageControl).pageIndicatorTintColor = UIColor.clear
                (imagePageControl as! PTImagePageControl).currentPageIndicatorTintColor = UIColor.clear
                
                if let activeImage = viewModel.pageControlActiveImage {
                    (imagePageControl as! PTImagePageControl).pageImage = activeImage
                }
                if let inActiveImage = viewModel.pageControlInActiveImage {
                    (imagePageControl as! PTImagePageControl).currentPageImage = inActiveImage
                }
                (imagePageControl as! PTImagePageControl).currentPage = 0
                (imagePageControl as! PTImagePageControl).numberOfPages = viewModel.imageArrays.count
                addSubview(imagePageControl!)
            case .scrolling:
                imagePageControl = PTScrollingPageControl()
                (imagePageControl as! PTScrollingPageControl).progress = 0
                (imagePageControl as! PTScrollingPageControl).pageCount = viewModel.imageArrays.count
                addSubview(imagePageControl!)
            }
        }

        switch viewModel.pageControl {
        case .none:
            imagePageControl!.isHidden = true
        default:
            imagePageControl!.isHidden = false
        }
        addSubviews([forwardButton,nextButton,imagePageControl!])

        forwardButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
            make.left.equalToSuperview().inset(10)
        }
        
        nextButton.snp.makeConstraints { make in
            make.width.height.bottom.equalTo(forwardButton)
            make.right.equalToSuperview().inset(10)
        }

        imagePageControl!.snp.makeConstraints { make in
            make.left.equalTo(self.forwardButton.snp.right).offset(10)
            make.right.equalTo(self.nextButton.snp.left).offset(-10)
            make.height.equalTo(20)
            make.centerY.equalTo(self.forwardButton)
        }

        forwardButton.isHidden = true
        forwardButton.isUserInteractionEnabled = false
        forwardButton.addActionHandlers { seder in
            switch viewModel.pageControl {
            case .none:
                break
            case .pageControl(let type):
                switch type {
                case .system:
                    (self.imagePageControl as! UIPageControl).currentPage = (self.imagePageControl as! UIPageControl).currentPage - 1
                case .fill:
                    (self.imagePageControl as! PTFilledPageControl).progress = CGFloat((self.imagePageControl as! PTFilledPageControl).currentPage - 1)
                case .pill:
                    (self.imagePageControl as! PTPillPageControl).progress = CGFloat((self.imagePageControl as! PTPillPageControl).currentPage - 1)
                case .snake:
                    (self.imagePageControl as! PTSnakePageControl).progress = CGFloat((self.imagePageControl as! PTSnakePageControl).currentPage - 1)
                case .image:
                    (self.imagePageControl as! PTImagePageControl).currentPage = (self.imagePageControl as! PTImagePageControl).currentPage - 1
                case .scrolling:
                    (self.imagePageControl as! PTScrollingPageControl).progress = CGFloat((self.imagePageControl as! PTScrollingPageControl).currentPage - 1)
                }
            }

            guidePageView.contentOffset.x = guidePageView.contentOffset.x - guidePageView.frame.size.width
        }
        
        nextButton.addActionHandlers { seder in
            switch viewModel.pageControl {
            case .none:
                break
            case .pageControl(let type):
                var currentCount = 0
                switch type {
                case .system:
                    currentCount = (self.imagePageControl as! UIPageControl).currentPage + 1
                case .fill:
                    currentCount = (self.imagePageControl as! PTFilledPageControl).currentPage + 1
                case .pill:
                    currentCount = (self.imagePageControl as! PTPillPageControl).currentPage + 1
                case .snake:
                    currentCount = (self.imagePageControl as! PTSnakePageControl).currentPage + 1
                case .image:
                    currentCount = (self.imagePageControl as! PTImagePageControl).currentPage + 1
                case .scrolling:
                    currentCount = (self.imagePageControl as! PTScrollingPageControl).currentPage + 1
                }
                
                if viewModel.imageArrays.count == currentCount {
                    self.buttonClick(sender: seder)
                } else {
                    switch type {
                    case .system:
                        (self.imagePageControl as! UIPageControl).currentPage = currentCount
                    case .fill:
                        (self.imagePageControl as! PTFilledPageControl).progress = CGFloat(currentCount)
                    case .pill:
                        (self.imagePageControl as! PTPillPageControl).progress = CGFloat(currentCount)
                    case .snake:
                        (self.imagePageControl as! PTSnakePageControl).progress = CGFloat(currentCount)
                    case .image:
                        (self.imagePageControl as! PTImagePageControl).currentPage = currentCount
                    case .scrolling:
                        (self.imagePageControl as! PTScrollingPageControl).progress = CGFloat(currentCount)
                    }
                    
                    guidePageView.contentOffset.x = guidePageView.contentOffset.x + guidePageView.frame.size.width
                }
            }
        }
        
        if !NSObject.checkObject((viewModel.forwardImage as! NSObject)) && !NSObject.checkObject((viewModel.backImage as! NSObject)) {
            if viewModel.imageArrays.count > 1 {
                nextButton.isHidden = false
                nextButton.isUserInteractionEnabled = true
            } else {
                nextButton.isHidden = true
                nextButton.isUserInteractionEnabled = false
            }
            
            nextButton.loadImage(contentData: viewModel.backImage as Any,iCloudDocumentName: viewModel.iCloudDocumentName)
            
            forwardButton.loadImage(contentData: viewModel.forwardImage as Any,iCloudDocumentName: viewModel.iCloudDocumentName)
        } else {
            nextButton.isHidden = true
            nextButton.isUserInteractionEnabled = false
            forwardButton.isHidden = true
            forwardButton.isUserInteractionEnabled = false
        }
    }
    
    public init(mainView:UIView,
                videlURL:URL) {
        super.init(frame: mainView.frame)
        player.player = AVPlayer.init(url: videlURL)
        player.showsPlaybackControls = false
        player.entersFullScreenWhenPlaybackBegins = true
        addSubview(player.view)
        player.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        player.player?.play()
        
        let movieStartButton = UIButton(type: .custom)
        movieStartButton.layer.borderWidth = 1
        movieStartButton.layer.cornerRadius = 20
        movieStartButton.layer.borderColor = UIColor.white.cgColor
        movieStartButton.setTitle(StartString, for: .normal)
        movieStartButton.alpha = 0
        player.view.addSubview(movieStartButton)
        movieStartButton.addActionHandlers { sender in
            self.buttonClick(sender: sender)
        }
        UIView.animate(withDuration: animationTime) {
            movieStartButton.alpha = 1
        }
        movieStartButton.snp.makeConstraints { make in
            make.width.equalTo(100)
            make.height.equalTo(50)
            make.centerX.equalTo(self.player.view)
            make.bottom.equalTo(self.player.view).inset(CGFloat.kTabbarSaveAreaHeight + 20)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buttonClick(sender:UIButton?) {
        UIView.animate(withDuration: animationTime) {
            self.alpha = 0
            PTGCDManager.gcdAfter(time: self.animationTime) {
                self.removeGuidePageHUD()
            }
        }
    }
    
    public func removeGuidePageHUD() {
        removeFromSuperview()
        if adHadRemove != nil {
            adHadRemove!()
        }
    }
    
    public func guideShow() {
        viewModel.mainView.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
#if POOTOOLS_DEBUG
        if let windows = viewModel.mainView as? UIWindow {
            let share = LocalConsole.shared
            if share.isVisiable {
                windows.bringSubviewToFront(share.terminal!)
            }
        }
#endif
    }
    
    fileprivate func pageControlAction(page:Int) {
        if (imageArray?.count ?? 0) > 0 && page == (imageArray!.count - 1) && !slideInto! {
            buttonClick(sender: nil)
        }
        
        if (imageArray?.count ?? 0 > 0) && page < (imageArray!.count - 1) && slideInto! {
            slideIntoNumber = 1
        }
        
        if (imageArray?.count ?? 0 > 0) && page == (imageArray!.count - 1) && slideInto! {
            let swipeGestureRecognizer = UISwipeGestureRecognizer.init(target: nil, action: nil)
            if swipeGestureRecognizer.direction == .right {
                slideIntoNumber += 1
                if slideIntoNumber == 3 {
                    buttonClick(sender: nil)
                }
            }
        }
        
        switch viewModel.pageControl {
        case .none:
            break
        case .pageControl(let type):
            switch type {
            case .system:
                (imagePageControl as! UIPageControl).currentPage = page
            case .fill:
                (imagePageControl as! PTFilledPageControl).progress = CGFloat(page)
            case .pill:
                (imagePageControl as! PTPillPageControl).progress = CGFloat(page)
            case .snake:
                (imagePageControl as! PTSnakePageControl).progress = CGFloat(page)
            case .image:
                (imagePageControl as! PTImagePageControl).currentPage = page
            case .scrolling:
                (imagePageControl as! PTScrollingPageControl).progress = CGFloat(page)
            }
        }
        if page >= 1 {
            forwardButton.isHidden = false
            forwardButton.isUserInteractionEnabled = true
        } else {
            forwardButton.isHidden = true
            forwardButton.isUserInteractionEnabled = false
        }

    }
}

extension PTGuidePageHUD : UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page : Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControlAction(page: page)
    }
}
