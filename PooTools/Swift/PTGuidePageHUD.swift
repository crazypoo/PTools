//
//  PTGuidePageHUD.swift
//  Diou
//
//  Created by ken lam on 2021/10/16.
//  Copyright © 2021 DO. All rights reserved.
//

import UIKit
import AVKit

class PTGuidePageHUD: UIView {
    fileprivate var imageArray : [String]?
    fileprivate var imagePageControl = UIPageControl()
    fileprivate var slideIntoNumber : Int = 0
    fileprivate var player = AVPlayerViewController()
    
    var slideInto : Bool? = false
    var animationTime : CGFloat? = 3.0
    var adHadRemove:(()->Void)?
    
    let StartString = "开始体验"
    
    init(mainView:UIView,imageNameArray:[String],tapHidden:Bool) {
        super.init(frame: mainView.frame)
        if tapHidden
        {
            self.imageArray = imageNameArray
        }
        
        let guidePageView = UIScrollView()
        guidePageView.backgroundColor = .lightGray
        guidePageView.contentSize = CGSize.init(width: kSCREEN_WIDTH * CGFloat(imageNameArray.count), height: kSCREEN_HEIGHT)
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
        skipButton.addActionHandler { sender in
            self.buttonClick(sender: sender!)
        }
        self.addSubview(skipButton)
        skipButton.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(25)
            make.right.equalToSuperview().inset(10)
            make.top.equalToSuperview().inset(kStatusBarHeight + 10)
        }
        
        imageNameArray.enumerated().forEach { (index,value) in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            let contentImage = UIImage.init(named: imageNameArray[index])
            let data = contentImage!.pngData()
            if data?.detectImageType() == .gif
            {
                let source = CGImageSourceCreateWithData(data as! CFData, nil)
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
            
            if index == (imageNameArray.count - 1) && !tapHidden
            {
                imageView.isUserInteractionEnabled = true
                
                let startButton = UIButton(type: .custom)
                startButton.setTitle(StartString, for: .normal)
                startButton.setTitleColor(UIColor(red: 164/255, green: 201/255, blue: 67/255, alpha: 1), for: .normal)
                startButton.titleLabel?.font = .systemFont(ofSize: 21)
                startButton.setBackgroundImage(UIImage(named: "GuideImage.bundle/guideImage_button_backgound"), for: .normal)
                startButton.addActionHandler { sender in
                    self.buttonClick(sender: sender!)
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
        imagePageControl.numberOfPages = imageNameArray.count
        imagePageControl.pageIndicatorTintColor = .gray
        imagePageControl.currentPageIndicatorTintColor = .white
        self.addSubview(imagePageControl)
        imagePageControl.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(30)
            make.bottom.equalToSuperview().inset(kTabbarSaveAreaHeight)
        }
    }
    
    init(mainView:UIView,videlURL:URL) {
        super.init(frame: mainView.frame)
        player.player = AVPlayer.init(url: videlURL)
        player.showsPlaybackControls = false
        player.entersFullScreenWhenPlaybackBegins = true
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
        movieStartButton.addActionHandler { sender in
            self.buttonClick(sender: sender!)
        }
        UIView.animate(withDuration: animationTime!) {
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
        UIView.animate(withDuration: animationTime!) {
            self.alpha = 0
            PTUtils.gcdAfter(time: self.animationTime!) {
//                self.perform(#selector(), with: nil, afterDelay: 1)
                self.removeGuidePageHUD()
            }
        }
    }
    
    func removeGuidePageHUD()
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
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        imagePageControl.currentPage = Int((scrollView.contentOffset.x / scrollView.frame.size.width) + 0.5)
    }
}
