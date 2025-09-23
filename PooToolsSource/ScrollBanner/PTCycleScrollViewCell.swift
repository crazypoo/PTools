//
//  LLCycleScrollViewCell.swift
//  LLCycleScrollView
//
//  Created by LvJianfeng on 2016/11/22.
//  Copyright © 2016年 LvJianfeng. All rights reserved.
//

import UIKit
import SnapKit
import SwifterSwift
import AttributedString
import AVKit
import AVFoundation

class PTCycleScrollViewCell: PTBaseNormalCell {
    static let ID = "PTCycleScrollViewCell"
    
    var pageControlHeight:CGFloat = 0
    
    fileprivate var cellHaveTitle:Bool = false
    // 标题
    var title: Any? {
        didSet {
            if title != nil {
                if let titleString = title as? String,!titleString.stringIsEmpty() {
                    titleLabel.text = titleString
                    cellHaveTitle = true
                } else if let titleAtt = title as? ASAttributedString {
                    titleLabel.attributed.text = titleAtt
                    cellHaveTitle = true
                } else {
                    cellHaveTitle = false
                }
            } else {
                cellHaveTitle = false
            }
            
            titleBackView.isHidden = !cellHaveTitle
            titleLabel.isHidden = !cellHaveTitle
        }
    }
    
    /*
     如果内容是att则字体颜色,字体失效
     */
    // 标题颜色
    var titleLabelTextColor: UIColor = UIColor.white {
        didSet {
            titleLabel.textColor = titleLabelTextColor
        }
    }
    
    // 标题字体
    var titleFont: UIFont = UIFont.systemFont(ofSize: 15) {
        didSet {
            titleLabel.font = titleFont
        }
    }
    
    // 文本行数
    var titleLines: NSInteger = 2 {
        didSet {
            titleLabel.numberOfLines = titleLines
        }
    }
    
    // 标题文本x轴间距
    var titleLabelLeading: CGFloat = 15 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // 标题背景色
    var titleBackViewBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3) {
        didSet {
            titleBackView.backgroundColor = titleBackViewBackgroundColor
        }
    }
    
    // 标题Label高度
    var titleLabelHeight: CGFloat! = 56 {
        didSet {
            layoutSubviews()
        }
    }

    lazy var titleBackView: UIView = {
        let view = UIView()
        view.backgroundColor = titleBackViewBackgroundColor
        view.isHidden = true
        return view
    }()
    
    // 图片
    lazy var imageView: UIImageView = {
        let view = UIImageView()
        // 默认模式
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()
    
    fileprivate lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.isHidden = true
        view.textColor = titleLabelTextColor
        view.numberOfLines = titleLines
        view.font = titleFont
        view.backgroundColor = UIColor.clear
        view.isUserInteractionEnabled = false
        return view
    }()
    
    lazy var playerViewController : AVPlayerViewController = {
        let view = AVPlayerViewController()
        return view
    }()

    var player: AVPlayer?
    var videoLink:String = "" {
        didSet {
            // 添加通知监听器，监听视频播放完成事件
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(videoDidEnd),
                name: .AVPlayerItemDidPlayToEndTime,
                object: player?.currentItem
            )
        }
    }
    var pipController: AVPictureInPictureController?
    var playerLayer: AVPlayerLayer?

    lazy var playButton:UIButton = {
        let view = UIButton(type:.custom)
        view.setImage(PTCycleScrollView.playButtonImage, for: .normal)
        view.addActionHandlers { sender in
            if !self.videoLink.stringIsEmpty(),let url = URL(string: self.videoLink) {
                self.setPlayer(videoQ: url)
            }
        }
        return view
    }()
    
    var playEndcallback: PTActionTask? = nil
    var showPlayButton:Bool = true

    deinit {
        // 移除通知监听器
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubviews([imageView,playerViewController.view,playButton,titleBackView])
        titleBackView.addSubview(titleLabel)
        playerViewController.view.isHidden = true
        playButton.isHidden = true
    }
        
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
            
    // MARK: layoutSubviews
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playerViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        playButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerX.centerY.equalToSuperview()
        }
        
        titleBackView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(self.titleLabelHeight + self.pageControlHeight)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.height.equalTo(self.titleLabelHeight)
            make.left.right.equalToSuperview().inset(self.titleLabelLeading)
            make.top.equalToSuperview()
        }
    }
    
    func setPlayer(videoQ:URL,playCallback:PTBoolTask? = nil) {
        imageView.isHidden = true
        playButton.isHidden = true
        playerViewController.view.isHidden = false
        if cellHaveTitle {
            titleBackView.isHidden = true
            titleLabel.isHidden = true
        }
        if player == nil {
            player = AVPlayer(url: videoQ)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = contentView.bounds
            contentView.layer.insertSublayer(playerLayer!, at: 0)
            playerViewController.player = player
        }
        player?.play()
        player?.isMuted = true
        
        if AVPictureInPictureController.isPictureInPictureSupported() {
            pipController = AVPictureInPictureController(playerLayer: playerLayer!)
        }
        playCallback?(true)
    }
    
    func startPiP() {
        if let pipController = pipController, pipController.isPictureInPicturePossible {
            pipController.startPictureInPicture()
        }
    }
    
    func resetPlayerView() {
        playButton.isHidden = !showPlayButton
        imageView.isHidden = false
        playerViewController.view.isHidden = true
        player?.pause()
        player?.seek(to: CMTime.zero)
        if cellHaveTitle {
            titleBackView.isHidden = false
            titleLabel.isHidden = false
        }
    }
    
    // 视频播放完成后的处理
    @objc func videoDidEnd(notification: Notification) {
        // 在这里可以进行进一步的处理，比如重播、显示提示等
        resetPlayerView()
        playEndcallback?()
    }
}
