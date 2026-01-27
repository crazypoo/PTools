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

    var audioCachePath:URL?
    var audioDuration:Float = 0

    public var cellModel:PTChatListModel! {
        didSet {
            PTGCDManager.gcdMain {
                self.setBaseSubviews(cellModel: self.cellModel)
                self.dataContentSets(cellModel: self.cellModel)
                self.configureContent(cellModel: self.cellModel)
            }
        }
    }
    
    fileprivate var audioPlayer: AVAudioPlayer?
    fileprivate var displayLink: CADisplayLink?
    fileprivate var isPaused: Bool = false

    lazy var playButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTChatConfig.share.playButtonImage, for: .normal)
        view.setImage(PTChatConfig.share.pauseButtonImage, for: .selected)
        view.isSelected = false
        // 播放按钮点击事件
        view.addActionHandlers { sender in
            sender.isSelected.toggle()
            if sender.isSelected {
                if let cachePath = self.audioCachePath {
                    let localURL = URL(fileURLWithPath:cachePath.path)
                    self.startAudioPlayback(from: localURL)
                } else {
                    self.configureContent(cellModel: self.cellModel)
                }
            } else {
                self.pauseAudioPlayback()
            }
        }
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
        displayLink?.invalidate()
        displayLink = nil
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

        // 添加子视图
        dataContent.addSubviews([playButton, durationLabel, progressView])
        playButton.snp.makeConstraints { make in
            make.size.equalTo(25)
            make.left.equalToSuperview().inset(7.5)
            make.centerY.equalToSuperview()
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
        
        resetSubviewsFrame(cellModel: cellModel)
    }
    
    // 配置音频内容
    func configureContent(cellModel: PTChatListModel) {
        var audioURL: URL?
        if let content = cellModel.msgContent as? String {
            audioURL = URL(string: content)
        } else if let url = cellModel.msgContent as? URL {
            audioURL = url
        }
        
        if let url = audioURL {
            waitImageView.setImage(PTChatConfig.share.chatWaitImage, for: .normal)
            startWaitAnimation()
            waitImageView.isHidden = false
            PTAudioService.shared.fetchDuration(for: url, completion: { duration,url in
                self.audioDuration = duration
                self.audioCachePath = url
                self.durationLabel.text = duration.floatToPlayTimeString()
                self.stopWaitAnimation()
                self.waitImageView.isHidden = true
                self.waitImageView.isUserInteractionEnabled = false
            })
        }
    }
    
    // 播放音频
    func startAudioPlayback(from url: URL) {
        if self.isPaused {
            self.audioPlayer?.play()
            self.isPaused = false
        } else {
            self.playAudio(at: url)
            self.startTimerProgres()
        }
    }

    // 暂停音频
    func pauseAudioPlayback() {
        audioPlayer?.pause()
        isPaused = true
    }

    // 播放音频文件
    private func playAudio(at url: URL) {
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.play()
    }
    
    func startTimerProgres() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    // 更新进度条
    @objc func updateProgress() {
        guard let player = audioPlayer else { return }
        progressView.progress = Float(player.currentTime / player.duration)
        durationLabel.text = player.currentTime.float.floatToPlayTimeString()
    }

    func stopPlaying() {
        displayLink?.invalidate()
        displayLink = nil
        progressView.progress = 0
        playButton.isSelected = false
        audioPlayer = nil
        durationLabel.text = self.audioDuration.floatToPlayTimeString()
        isPaused = false
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
