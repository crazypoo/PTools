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
    public var tapHidden:Bool = false
    ///图片s
    public var imageArrays:[Any] = []
    ///展示在X
    public var mainView:UIView = UIView()
    ///是否显示Pagecontrol
    public var pageControl:Bool = false
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
}

@objcMembers
public class PTGuidePageHUD: UIView {
    fileprivate var imageArray : [Any]?
    fileprivate var imagePageControl = UIPageControl()
    fileprivate var slideIntoNumber : Int = 0
    fileprivate var player = AVPlayerViewController()
    
    public var slideInto : Bool? = false
    public var animationTime : CGFloat = 3.0
    public var adHadRemove:PTActionTask?
    
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
            PTLoadImageFunction.loadImage(contentData: contentData, iCloudDocumentName: viewModel.iCloudDocumentName) { images,image in
                if (images?.count ?? 0) > 1 {
                    imageView.animationImages = images
                    imageView.animationDuration = 2
                    imageView.startAnimating()
                } else if images?.count == 1 {
                    imageView.image = images!.first
                }
            }
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
        
        imagePageControl.currentPage = 0
        imagePageControl.numberOfPages = viewModel.imageArrays.count
        imagePageControl.pageIndicatorTintColor = .gray
        imagePageControl.currentPageIndicatorTintColor = .white
        imagePageControl.addPageControlHandlers { sender in
            
            if viewModel.imageArrays.count == (sender.currentPage + 1) {
                self.buttonClick(sender: nil)
            } else {
                guidePageView.contentOffset.x = guidePageView.contentOffset.x + guidePageView.frame.size.width
            }
        }
        addSubview(imagePageControl)
        imagePageControl.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(30)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
        }
        
        imagePageControl.isHidden = viewModel.pageControl ? false : true
        imagePageControl.isUserInteractionEnabled = viewModel.pageControl
        
        addSubview(forwardButton)
        forwardButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.bottom.equalToSuperview().inset(CGFloat.kTabbarSaveAreaHeight + 10)
            make.left.equalToSuperview().inset(10)
        }
        forwardButton.isHidden = true
        forwardButton.isUserInteractionEnabled = false
        forwardButton.addActionHandlers { seder in
            self.imagePageControl.currentPage = self.imagePageControl.currentPage - 1
            guidePageView.contentOffset.x = guidePageView.contentOffset.x - guidePageView.frame.size.width
        }
        
        addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.width.height.bottom.equalTo(forwardButton)
            make.right.equalToSuperview().inset(10)
        }
        nextButton.addActionHandlers { seder in
            if viewModel.imageArrays.count == (self.imagePageControl.currentPage + 1) {
                self.buttonClick(sender: seder)
            } else {
                self.imagePageControl.currentPage = self.imagePageControl.currentPage + 1
                guidePageView.contentOffset.x = guidePageView.contentOffset.x + guidePageView.frame.size.width
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
            
            PTLoadImageFunction.loadImage(contentData: viewModel.backImage as Any, iCloudDocumentName: viewModel.iCloudDocumentName) { images,image in
                if images?.count != 0 {
                    self.nextButton.setImage(images!.first, for: .normal)
                }
            }
            PTLoadImageFunction.loadImage(contentData: viewModel.forwardImage as Any, iCloudDocumentName: viewModel.iCloudDocumentName) { images,image in
                if images?.count != 0 {
                    self.forwardButton.setImage(images!.first, for: .normal)
                }
            }
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
        
        imagePageControl.currentPage = page
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
        PTNSLogConsole(page)
        pageControlAction(page: page)
    }
}
