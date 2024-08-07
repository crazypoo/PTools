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
    fileprivate var isPause:Bool = false
    
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
                
        if cellModel.belongToMe {
            dataContentStatusView.setBackgroundImage(PTChatConfig.share.chatMeBubbleImage.resizeImage(), for: .normal)
            dataContentStatusView.setBackgroundImage(PTChatConfig.share.chatMeHighlightedBubbleImage.resizeImage(), for: .highlighted)
        } else {
            dataContentStatusView.setBackgroundImage(PTChatConfig.share.chatOtherBubbleImage.resizeImage(), for: .normal)
            dataContentStatusView.setBackgroundImage(PTChatConfig.share.chatOtherHighlightedBubbleImage.resizeImage(), for: .highlighted)
        }
        dataContent.snp.remakeConstraints { make in
            if cellModel.belongToMe {
                make.right.equalTo(self.userIcon.snp.left).offset(-PTChatBaseCell.dataContentUserIconInset)
            } else {
                make.left.equalTo(self.userIcon.snp.right).offset(PTChatBaseCell.dataContentUserIconInset)
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
                    if FileManager.pt.judgeFileOrFolderExists(filePath: url.absoluteString.replace("file://", with: "")) {
                        if self.isPause {
                            self.audioPlayer?.play()
                            self.isPause = false
                        } else {
                            self.audioPlayer = try? AVAudioPlayer(contentsOf: url)
                            self.audioPlayer?.prepareToPlay()
                            self.audioPlayer?.delegate = self
                            self.audioPlayer?.play()
                            self.startTimerProgres()
                            self.isPause = false
                        }
                    } else {
                        let localPath = FileManager.pt.CachesDirectory().appendingPathComponent(url.lastPathComponent)
                        if FileManager.pt.judgeFileOrFolderExists(filePath: localPath) {
                            if self.isPause {
                                self.audioPlayer?.play()
                                self.isPause = false
                            } else {
                                self.audioPlayer = try? AVAudioPlayer(contentsOf: URL(fileURLWithPath: localPath))
                                self.audioPlayer?.prepareToPlay()
                                self.audioPlayer?.delegate = self
                                self.audioPlayer?.play()
                                self.startTimerProgres()
                            }
                        } else {
                            self.waitImageView.setImage(PTChatConfig.share.chatWaitImage, for: .normal)
                            self.startWaitAnimation()
                            self.waitImageView.isHidden = false
                            Network.share.createDownload(fileUrl: url.absoluteString, saveFilePath: localPath) { bytesRead, totalBytesRead, progress in
                                
                            } success: { reponse in
                                self.audioPlayer = try? AVAudioPlayer(data: reponse.value!)
                                self.audioPlayer?.prepareToPlay()
                                self.audioPlayer?.delegate = self
                                self.audioPlayer?.play()
                                self.startTimerProgres()
                                self.stopWaitAnimation()
                                self.waitImageView.isHidden = true
                                self.waitImageView.isUserInteractionEnabled = false
                                self.isPause = false
                            } fail: { error in
                                self.stopWaitAnimation()
                                self.waitImageView.isHidden = true
                                self.waitImageView.isUserInteractionEnabled = false
                            }
                        }
                    }
                } else {
                    if self.audioPlayer != nil {
                        self.audioPlayer?.pause()
                        self.isPause = true
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
        
        resetSubsFrame(cellModel: cellModel)
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
