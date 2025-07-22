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

public enum PTGuidePageControlSelection {
    case none
    case pageControl(type:PTGuidePageControlOption)
    
    public enum PTGuidePageControlOption {
        case system,fill,pill,snake,image,scrolling
    }
}

/*
 Guide初始配置
 */
@objcMembers
public class PTGuidePageModel: NSObject {
    ///是否显示开始体验
    public var tapHidden:Bool = false
    ///图片s
    public var imageArrays:[Any] = []
    ///展示在X
    public var mainView:UIView = UIView()
    ///是否显示Pagecontrol
    public var pageControl:PTGuidePageControlSelection = .pageControl(type: .system)
    ///是否显示跳过按钮
    public var skipShow:Bool = false
    ///上一张按钮图片
    public var forwardImage:Any?
    ///下一张按钮图片
    public var backImage:Any?
    ///开始体验按钮背景
    public var startBackgroundImage:UIImage = UIColor.randomColor.createImageWithColor()
    ///开始体验按钮字体颜色
    public var startTextColor:UIColor = UIColor.randomColor
    ///iCloud文件夹名字
    public var iCloudDocumentName:String = ""
        /// 未选中颜色
    public var pageControlTintColor: UIColor = UIColor.lightGray
    /// 选中颜色
    public var pageControlCurrentPageColor: UIColor = UIColor.white
    ///  圆角(.fill,.snake)
    public var fillPageControlIndicatorRadius: CGFloat = 4
    /// 选中颜色(.pill,.snake)
    public var customPageControlInActiveTintColor: UIColor = UIColor(white: 1, alpha: 0.3)
    /// 普通图片(.system)
    public var pageControlActiveImage: Any? = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotActive")
    /// 选中图片(.system)
    public var pageControlInActiveImage: Any? = Bundle.podBundleImage(bundleName: CorePodBundleName, imageName: "lldotInActive")
    /// 自定义Pagecontrol普通颜色
    public var customPageControlTintColor: UIColor = UIColor.white
    /// 自定义Pagecontrol点阵边距
    public var customPageControlIndicatorPadding: CGFloat = 8
    
    public var skipName:String = "PT Button skip".localized()
    public var skipFont:UIFont = .appfont(size: 14)
    public var startString:String = "PT Guide start".localized()
    public var startFont:UIFont = .appfont(size: 21)
}

@objcMembers
public class PTGuidePageHUD: UIView {
    fileprivate var imageArray : [Any]?
    fileprivate var imagePageControl:UIView?
    fileprivate var slideIntoNumber : Int = 0
    fileprivate var player = AVPlayerViewController()
    
    public var slideInto : Bool? = false
    public var animationTime : CGFloat = 3.0
    public var adHadRemove:PTActionTask?
        
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
        
        let skipButton = UIButton(type: .custom)
        skipButton.setTitle(viewModel.skipName, for: .normal)
        skipButton.titleLabel?.font = viewModel.skipFont
        skipButton.backgroundColor = .gray
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.layer.cornerRadius =  skipButton.frame.height * 0.5
        skipButton.addActionHandlers { sender in
            self.buttonClick(sender: sender)
        }
        addSubview(skipButton)
        skipButton.snp.makeConstraints { make in
            make.width.equalTo(skipButton.sizeFor(height: 25).width + 10)
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
                startButton.setTitle(viewModel.startString, for: .normal)
                startButton.setTitleColor(viewModel.startTextColor, for: .normal)
                startButton.titleLabel?.font = viewModel.startFont
                startButton.setBackgroundImage(viewModel.startBackgroundImage, for: .normal)
                startButton.addActionHandlers { sender in
                    self.buttonClick(sender: sender)
                }
                imageView.addSubview(startButton)
                let y = CGFloat.kTabbarSaveAreaHeight + 10 + 44 / 2 + 20
                startButton.snp.makeConstraints { make in
                    make.width.equalTo(startButton.sizeFor(height: 44).width + 10)
                    make.height.equalTo(44)
                    make.centerX.equalTo(imageView)
                    switch viewModel.pageControl {
                    case .none:
                        make.bottom.equalTo(imageView).inset(CGFloat.kTabbarSaveAreaHeight + 40)
                    default:
                        make.bottom.equalToSuperview().inset(y)
                    }
                }
            }
        }
        
        switch viewModel.pageControl {
        case .none: break
        case .pageControl(let type):
            imagePageControl = setPageControlView(type: type)
            if let control = imagePageControl as? UIPageControl {
                control.addPageControlHandlers { sender in
                    if viewModel.imageArrays.count == (sender.currentPage + 1) {
                        self.buttonClick(sender: nil)
                    } else {
                        guidePageView.contentOffset.x = guidePageView.contentOffset.x + guidePageView.frame.size.width
                    }
                }
            }
            addSubview(imagePageControl!)
        }

        var pageViews = [UIView]()
        if let control = imagePageControl {
            switch viewModel.pageControl {
            case .none:
                control.isHidden = true
            default:
                control.isHidden = false
            }
            pageViews = [forwardButton,nextButton,imagePageControl!]
        } else {
            pageViews = [forwardButton,nextButton]
        }
        addSubviews(pageViews)

        forwardButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
            make.left.equalToSuperview().inset(10)
        }
        
        nextButton.snp.makeConstraints { make in
            make.width.height.bottom.equalTo(forwardButton)
            make.right.equalToSuperview().inset(10)
        }

        if let _ = imagePageControl {
            imagePageControl!.snp.makeConstraints { make in
                make.left.equalTo(self.forwardButton.snp.right).offset(10)
                make.right.equalTo(self.nextButton.snp.left).offset(-10)
                make.height.equalTo(20)
                make.centerY.equalTo(self.forwardButton)
            }
        }

        forwardButton.isHidden = true
        forwardButton.isUserInteractionEnabled = false
        forwardButton.addActionHandlers { seder in
            switch viewModel.pageControl {
            case .none:
                break
            case .pageControl( _):
                let currentCount = self.getPageControlCurrentValue() - 1
                self.pageControlProgressSet(currentIndex: currentCount)
            }

            guidePageView.contentOffset.x = guidePageView.contentOffset.x - guidePageView.frame.size.width
        }
        
        nextButton.addActionHandlers { seder in
            switch viewModel.pageControl {
            case .none:
                break
            case .pageControl( _):
                let currentCount = self.getPageControlCurrentValue() + 1
                
                if viewModel.imageArrays.count == currentCount {
                    self.buttonClick(sender: seder)
                } else {
                    self.pageControlProgressSet(currentIndex: currentCount)
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
        movieStartButton.setTitle(viewModel.startString, for: .normal)
        movieStartButton.titleLabel?.font = viewModel.startFont
        movieStartButton.alpha = 0
        player.view.addSubview(movieStartButton)
        movieStartButton.addActionHandlers { sender in
            self.buttonClick(sender: sender)
        }
        UIView.animate(withDuration: animationTime) {
            movieStartButton.alpha = 1
        }
        movieStartButton.snp.makeConstraints { make in
            make.width.equalTo(movieStartButton.sizeFor(height: 50).width + 10)
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
        adHadRemove?()
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
        case .pageControl( _):
            self.pageControlProgressSet(currentIndex: page)
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

//MAKR: PageControl
fileprivate extension PTGuidePageHUD {
    func setPageControlView(type:PTGuidePageControlSelection.PTGuidePageControlOption) -> UIView {
        switch type {
        case .system:
            let view = UIPageControl()
            view.pageIndicatorTintColor = viewModel.pageControlTintColor
            view.currentPageIndicatorTintColor = viewModel.pageControlCurrentPageColor
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            return view
        case .fill:
            let view = PTFilledPageControl(frame: CGRect.zero)
            view.tintColor = viewModel.customPageControlTintColor
            view.indicatorPadding = viewModel.customPageControlIndicatorPadding
            view.indicatorRadius = viewModel.fillPageControlIndicatorRadius
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            return view
        case .pill:
            let view = PTPillPageControl(frame: CGRect.zero)
            view.indicatorPadding = viewModel.customPageControlIndicatorPadding
            view.activeTint = viewModel.customPageControlTintColor
            view.inactiveTint = viewModel.customPageControlInActiveTintColor
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            return view
        case .snake:
            let view = PTSnakePageControl(frame: CGRect.zero)
            view.activeTint = viewModel.customPageControlTintColor
            view.indicatorPadding = viewModel.customPageControlIndicatorPadding
            view.indicatorRadius = viewModel.fillPageControlIndicatorRadius
            view.inactiveTint = viewModel.customPageControlInActiveTintColor
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            return view
        case .image:
            let view = PTImagePageControl()
            view.pageIndicatorTintColor = UIColor.clear
            view.currentPageIndicatorTintColor = UIColor.clear
            if let activeImage = viewModel.pageControlActiveImage {
                view.pageImage = activeImage
            }
            if let inActiveImage = viewModel.pageControlInActiveImage {
                view.currentPageImage = inActiveImage
            }
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            return view
        case .scrolling:
            let view = PTScrollingPageControl()
            view.update(currentPage: 0, totalPages: viewModel.imageArrays.count)
            return view
        }
    }
    
    func pageControlProgressSet(currentIndex:Int) {
        guard let controllable = imagePageControl as? PTPageControllable else { return }
        controllable.setCurrentPage(index: currentIndex)
    }
    
    func getPageControlCurrentValue() -> Int {
        return (imagePageControl as? PTPageControllable)?.currentPage ?? 0
    }
    
    func setPageControlValue(_ value: Int) {
        guard let control = imagePageControl as? PTPageControllable else { return }
        control.update(currentPage: value, totalPages: self.viewModel.imageArrays.count)
    }
}
