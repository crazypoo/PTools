//
//  PTChatVoiceCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/2.
//

import UIKit
import AVFoundation
import SnapKit

public class PTChatVoiceCell: PTChatBaseCell {
    
    public static let ID = "PTChatVoiceCell"

    public var cellModel:PTChatListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.setBaseSubsViews(cellModel: self.cellModel)
                self.dataContentSets(cellModel: self.cellModel)
            }
        }
    }
    
    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var progressTimer:Timer?

    lazy var playButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTChatConfig.share.playButtonImage, for: .normal)
        view.setImage(PTChatConfig.share.pauseButtonImage, for: .selected)
        
        view.isSelected = false
        return view
    }()
    
    lazy var durationLabel: UILabel = {
        let durationLabel = UILabel()
        durationLabel.textAlignment = .right
        durationLabel.font = PTChatConfig.share.durationFont
        durationLabel.textColor = PTChatConfig.share.durationColor
        durationLabel.text = "0:00"
        return durationLabel
    }()
    
    public lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.progress = 0.0
        progressView.tintColor = PTChatConfig.share.progressColor
        return progressView
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func dataContentSets(cellModel:PTChatListModel) {
                
        userIcon.snp.remakeConstraints { make in
            make.size.equalTo(PTChatConfig.share.messageUserIconSize)
            if cellModel.belongToMe {
                make.right.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            } else {
                make.left.equalToSuperview().inset(PTChatConfig.share.userIconFixelSpace)
            }
            make.top.equalTo(self.messageTimeLabel.snp.bottom).offset(PTChatBaseCell.TimeTopSpace)
        }

        senderNameLabel.snp.remakeConstraints { make in
            make.top.equalTo(self.userIcon)
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            
            make.height.equalTo(PTChatConfig.share.showSenderName ? PTChatBaseCell.NameHeight : 0)
        }

        if cellModel.belongToMe {
            dataContent.setBackgroundImage(PTChatConfig.share.chatMeBubbleImage.resizeImage(), for: .normal)
            dataContent.setBackgroundImage(PTChatConfig.share.chatMeHighlightedBubbleImage.resizeImage(), for: .highlighted)
        } else {
            dataContent.setBackgroundImage(PTChatConfig.share.chatOtherBubbleImage.resizeImage(), for: .normal)
            dataContent.setBackgroundImage(PTChatConfig.share.chatOtherHighlightedBubbleImage.resizeImage(), for: .highlighted)
        }
        dataContent.snp.remakeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.DataContentUserIconFixel)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.DataContentUserIconFixel)
            }
            make.top.equalTo(self.senderNameLabel.snp.bottom)
            make.height.equalTo(38)
            make.width.equalTo(PTChatConfig.share.audioMessageImageWidth)
        }
        
        dataContent.addSubviews([playButton,durationLabel,progressView])
        playButton.snp.makeConstraints { make in
            make.size.equalTo(25)
            make.left.equalToSuperview().inset(7.5)
            make.centerY.equalToSuperview()
        }
        
        var audionURL:URL?
        if cellModel.msgContent is String {
            audionURL = URL(string: cellModel.msgContent as! String)
        } else if cellModel.msgContent is URL {
            audionURL = (cellModel.msgContent as! URL)
        }
        
        if let url = audionURL {
            self.durationLabel.text = url.audioLinkGetDurationTime().floatToPlayTimeString()
            
            playButton.addActionHandlers { sender in
                sender.isSelected = !sender.isSelected
                if sender.isSelected {
                    self.audioPlayer = try? AVAudioPlayer(contentsOf: url)
                    self.audioPlayer?.prepareToPlay()
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.play()
                    self.startTimerProgres()
                } else {
                    if self.audioPlayer != nil {
                        self.audioPlayer?.pause()
                    }
                }
            }
        }
        
        durationLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(7.5)
            make.centerY.equalToSuperview()
        }
        
        progressView.snp.makeConstraints { make in
            make.left.equalTo(self.playButton.snp.right).offset(5)
            make.centerY.equalToSuperview()
            make.right.equalTo(self.durationLabel.snp.left).offset(-5)
        }
        
        waitImageView.snp.remakeConstraints { make in
            make.size.equalTo(PTChatBaseCell.WaitImageSize)
            if cellModel.belongToMe {
                make.right.equalTo(self.dataContent.snp.left).offset(-PTChatBaseCell.DataContentWaitImageFixel)
            } else {
                make.left.equalTo(self.dataContent.snp.right).offset(PTChatBaseCell.DataContentWaitImageFixel)
            }
            make.centerY.equalToSuperview()
        }
        waitImageView.addActionHandlers { sender in
            self.sendMesageError?(cellModel)
        }
        checkCellSendStatus(cellModel: cellModel)
    }
    
    func startTimerProgres() {
        progressTimer?.invalidate()
        progressTimer = nil
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, repeats: true, block: { timer in
            self.progressView.progress = (self.audioPlayer?.duration == 0) ? 0 : Float(self.audioPlayer!.currentTime / self.audioPlayer!.duration)
            self.durationLabel.text = self.audioPlayer!.currentTime.float.floatToPlayTimeString()
        })
    }
    
    func stopPlaying() {
        progressTimer?.invalidate()
        progressTimer = nil
        progressView .progress = 0
        playButton.isSelected = false
        audioPlayer = nil
        var audionURL:URL?
        if outputModel.msgContent is String {
            audionURL = URL(string: cellModel.msgContent as! String)
        } else if cellModel.msgContent is URL {
            audionURL = (cellModel.msgContent as! URL)
        }
        
        if let url = audionURL {
            self.durationLabel.text = url.audioLinkGetDurationTime().floatToPlayTimeString()
        } else {
            durationLabel.text = "0:00"
        }
    }
}

extension PTChatVoiceCell:AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlaying()
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        stopPlaying()
    }
}
