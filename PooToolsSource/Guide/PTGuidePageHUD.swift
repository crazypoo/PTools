//
//  PTGuidePageHUD.swift
//  Diou
//
//  Created by ken lam on 2021/10/16.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import AVKit

@objcMembers
public class PTGuidePageModel: NSObject
{
    public var tapHidden:Bool = false
    public var imageArrays:[String] = []
    public var mainView:UIView = UIView()
    public var pageControl:Bool = false
    public var skipShow:Bool = false
    public var forwardImage:String = ""
    public var backImage:String = ""
}

@objcMembers
public class PTGuidePageHUD: UIView {
    fileprivate var imageArray : [String]?
    fileprivate var imagePageControl = UIPageControl()
    fileprivate var slideIntoNumber : Int = 0
    fileprivate var player = AVPlayerViewController()
    
    public var slideInto : Bool? = false
    public var animationTime : CGFloat = 3.0
    public var adHadRemove:(()->Void)?
    
    let StartString = "开始体验"
    
    lazy var forwardButton:UIButton = {
        let btn = UIButton.init(type: .custom)
        return btn
    }()
    
    lazy var nextButton:UIButton = {
        let btn = UIButton.init(type: .custom)
        return btn
    }()
    
    public init(viewModel:PTGuidePageModel) {
        super.init(frame: viewModel.mainView.frame)
        if viewModel.tapHidden
        {
            self.imageArray = viewModel.imageArrays
        }
        
        let guidePageView = UIScrollView()
        guidePageView.backgroundColor = .lightGray
        guidePageView.contentSize = CGSize.init(width: kSCREEN_WIDTH * CGFloat(viewModel.imageArrays.count), height: kSCREEN_HEIGHT)
        guidePageView.bounces = false
        guidePageView.isPagingEnabled = true
        guidePageView.showsHorizontalScrollIndicator = false
        guidePageView.delegate = self
        self.addSubview(guidePageView)
        guidePageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let skipButton = UIButton.init(type: .custom)
        skipButton.setTitle("跳过", for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 14)
        skipButton.backgroundColor = .gray
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.layer.cornerRadius =  skipButton.frame.height * 0.5
        skipButton.addActionHandlers { sender in
            self.buttonClick(sender: sender)
        }
        self.addSubview(skipButton)
        skipButton.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(25)
            make.right.equalToSuperview().inset(10)
            make.top.equalToSuperview().inset(kStatusBarHeight + 10)
        }
        skipButton.isHidden = viewModel.skipShow ? false : true
        skipButton.isUserInteractionEnabled = viewModel.skipShow
        
        viewModel.imageArrays.enumerated().forEach { (index,value) in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            let contentImage = UIImage.init(named: viewModel.imageArrays[index])
            let data = contentImage!.pngData()
            if data?.detectImageType() == .GIF
            {
                let source = CGImageSourceCreateWithData(data! as CFData, nil)
                let frameCount = CGImageSourceGetCount(source!)
                var frames = [UIImage]()
                for i in 0...frameCount
                {
                    let imageref = CGImageSourceCreateImageAtIndex(source!,i,nil)
                    let imageName = UIImage.init(cgImage: imageref!)
                    frames.append(imageName)
                }
                imageView.animationImages = frames
                imageView.animationDuration = 1
                imageView.startAnimating()
            }
            else
            {
                imageView.image = contentImage
            }
            guidePageView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.width.equalTo(kSCREEN_WIDTH)
                make.height.equalTo(kSCREEN_HEIGHT)
                make.left.equalToSuperview().inset(kSCREEN_WIDTH * CGFloat(index))
            }
            
            if index == (viewModel.imageArrays.count - 1) && !viewModel.tapHidden
            {
                imageView.isUserInteractionEnabled = true
                
                let startButton = UIButton(type: .custom)
                startButton.setTitle(StartString, for: .normal)
                startButton.setTitleColor(UIColor(red: 164/255, green: 201/255, blue: 67/255, alpha: 1), for: .normal)
                startButton.titleLabel?.font = .systemFont(ofSize: 21)
                startButton.setBackgroundImage(UIImage(named: "GuideImage.bundle/guideImage_button_backgound"), for: .normal)
                startButton.addActionHandlers { sender in
                    self.buttonClick(sender: sender)
                }
                imageView.addSubview(startButton)
                startButton.snp.makeConstraints { make in
                    make.width.equalTo(100)
                    make.height.equalTo(50)
                    make.centerX.equalTo(imageView)
                    make.bottom.equalTo(imageView).inset(kTabbarSaveAreaHeight + 20)
                }
            }
        }
        
        imagePageControl.currentPage = 0
        imagePageControl.numberOfPages = viewModel.imageArrays.count
        imagePageControl.pageIndicatorTintColor = .gray
        imagePageControl.currentPageIndicatorTintColor = .white
        self.addSubview(imagePageControl)
        imagePageControl.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(30)
            make.bottom.equalToSuperview().inset(kTabbarSaveAreaHeight)
        }
        
        imagePageControl.isHidden = viewModel.pageControl ? false : true
        imagePageControl.isUserInteractionEnabled = viewModel.pageControl
        
        self.addSubview(forwardButton)
        forwardButton.snp.makeConstraints { make in
            make.width.height.equalTo(64)
            make.bottom.equalToSuperview().offset(-(kTabbarSaveAreaHeight + 10))
            make.left.equalToSuperview().inset(10)
        }
        forwardButton.isHidden = true
        forwardButton.isUserInteractionEnabled = false
        forwardButton.addActionHandlers { seder in
            self.imagePageControl.currentPage = self.imagePageControl.currentPage - 1
            guidePageView.contentOffset.x = guidePageView.contentOffset.x - guidePageView.frame.size.width
        }
        
        self.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.width.height.bottom.equalTo(forwardButton)
            make.right.equalToSuperview().inset(10)
        }
        nextButton.addActionHandlers { seder in
            if viewModel.imageArrays.count == (self.imagePageControl.currentPage + 1)
            {
                self.buttonClick(sender: seder)
            }
            else
            {
                self.imagePageControl.currentPage = self.imagePageControl.currentPage + 1
                guidePageView.contentOffset.x = guidePageView.contentOffset.x + guidePageView.frame.size.width
            }
        }
        
        if !viewModel.forwardImage.isEmpty && !viewModel.backImage.isEmpty
        {
            if viewModel.imageArrays.count > 1
            {
                nextButton.isHidden = false
                nextButton.isUserInteractionEnabled = true
            }
            else
            {
                nextButton.isHidden = true
                nextButton.isUserInteractionEnabled = false
            }
            nextButton.setImage(UIImage.init(named: viewModel.backImage), for: .normal)
            forwardButton.setImage(UIImage.init(named: viewModel.forwardImage), for: .normal)
        }
        else
        {
            nextButton.isHidden = true
            nextButton.isUserInteractionEnabled = false
            forwardButton.isHidden = true
            forwardButton.isUserInteractionEnabled = false
        }
    }
    
    public init(mainView:UIView,videlURL:URL) {
        super.init(frame: mainView.frame)
        player.player = AVPlayer.init(url: videlURL)
        player.showsPlaybackControls = false
        if #available(iOS 11.0, *) {
            player.entersFullScreenWhenPlaybackBegins = true
        }
        self.addSubview(player.view)
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
            make.bottom.equalTo(self.player.view).inset(kTabbarSaveAreaHeight + 20)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buttonClick(sender:UIButton?)
    {
        UIView.animate(withDuration: animationTime) {
            self.alpha = 0
            PTUtils.gcdAfter(time: self.animationTime) {
                self.removeGuidePageHUD()
            }
        }
    }
    
    public func removeGuidePageHUD()
    {
        self.removeFromSuperview()
        if adHadRemove != nil
        {
            adHadRemove!()
        }
    }
}

extension PTGuidePageHUD : UIScrollViewDelegate
{
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page : Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        if (imageArray?.count ?? 0) > 0 && page == (imageArray!.count - 1) && !slideInto!
        {
            self.buttonClick(sender: nil)
        }
        
        if (imageArray?.count ?? 0 > 0) && page < (imageArray!.count - 1) && slideInto!
        {
            slideIntoNumber = 1
        }
        
        if (imageArray?.count ?? 0 > 0) && page == (imageArray!.count - 1) && slideInto!
        {
            let swipeGestureRecognizer = UISwipeGestureRecognizer.init(target: nil, action: nil)
            if swipeGestureRecognizer.direction == .right
            {
                slideIntoNumber += 1
                if slideIntoNumber == 3
                {
                    buttonClick(sender: nil)
                }
            }
        }
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        let currentInt = "\((scrollView.contentOffset.x / scrollView.frame.size.width) + 0.5)".int ?? 0
        imagePageControl.currentPage = currentInt
        if currentInt >= 1
        {
            self.forwardButton.isHidden = false
            self.forwardButton.isUserInteractionEnabled = true
        }
        else
        {
            self.forwardButton.isHidden = true
            self.forwardButton.isUserInteractionEnabled = false
        }
    }
}
