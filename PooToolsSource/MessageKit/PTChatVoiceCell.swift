//
//  PTChatVoiceCell.swift
//  LiXinCEO
//
//  Created by 邓杰豪 on 2024/4/2.
//

import UIKit
import AVFoundation
import SnapKit

@MainActor
public class PTChatVoiceCell: PTChatBaseCell {
    
    public static let ID = "PTChatVoiceCell"

    var audioCachePath:URL?
    var audioDuration:Float = 0
    private var audioGeneration = 0

    public var cellModel:PTChatListModel! {
        didSet {
            guard let cellModel else { return }
            setBaseSubviews(cellModel: cellModel)
            dataContentSets(cellModel: cellModel)
            configureContent(cellModel: cellModel)
        }
    }
    
    fileprivate var audioPlayer: AVAudioPlayer?
    private var progressTask: Task<Void, Never>?
    fileprivate var isPaused: Bool = false

    lazy var playButton:UIButton = {
        let view = UIButton(type: .custom)
        view.setImage(PTChatConfig.share.playButtonImage, for: .normal)
        view.setImage(PTChatConfig.share.pauseButtonImage, for: .selected)
        view.isSelected = false
        // 播放按钮点击事件
        view.addActionHandlers { [weak self] sender in
            guard let self else { return }
            sender.isSelected.toggle()
            if sender.isSelected {
                if let cachePath = self.audioCachePath {
                    let localURL = cachePath.isFileURL ? cachePath : URL(fileURLWithPath: cachePath.path)
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
        setupSubviews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSubviews()
    }
    
    deinit {
        progressTask?.cancel()
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        audioGeneration += 1
        progressTask?.cancel()
        progressTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        audioCachePath = nil
        audioDuration = 0
        isPaused = false
        playButton.isSelected = false
        progressView.progress = 0
        durationLabel.text = "0:00"
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

        resetSubviewsFrame(cellModel: cellModel)
    }

    private func setupSubviews() {
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
            make.left.equalTo(playButton.snp.right).offset(5)
            make.centerY.equalToSuperview()
            make.right.equalTo(durationLabel.snp.left).offset(-5)
        }
    }
    
    // 配置音频内容
    func configureContent(cellModel: PTChatListModel) {
        audioGeneration += 1
        let generation = audioGeneration
        progressTask?.cancel()
        progressTask = nil
        audioPlayer?.stop()
        audioPlayer = nil
        audioCachePath = nil
        audioDuration = 0
        progressView.progress = 0
        durationLabel.text = "0:00"
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
            PTAudioService.shared.fetchDuration(for: url, completion: { [weak self] duration, url in
                PTMainActorBridge.perform { [weak self] in
                    guard let self, self.audioGeneration == generation else { return }
                    self.audioDuration = duration
                    self.audioCachePath = url
                    self.durationLabel.text = duration.floatToPlayTimeString()
                    self.stopWaitAnimation()
                    self.waitImageView.isHidden = true
                    self.waitImageView.isUserInteractionEnabled = false
                }
            })
        }
    }
    
    // 播放音频
    func startAudioPlayback(from url: URL) {
        if self.isPaused {
            self.audioPlayer?.play()
            self.isPaused = false
            if audioPlayer?.isPlaying == true {
                self.startTimerProgres()
            }
        } else {
            self.playAudio(at: url)
            if audioPlayer != nil {
                self.startTimerProgres()
            } else {
                playButton.isSelected = false
            }
        }
    }

    // 暂停音频
    func pauseAudioPlayback() {
        audioPlayer?.pause()
        isPaused = true
    }

    // 播放音频文件
    private func playAudio(at url: URL) {
        guard let player = try? AVAudioPlayer(contentsOf: url) else {
            audioPlayer = nil
            isPaused = false
            return
        }
        audioPlayer = player
        player.delegate = self
        player.play()
    }
    
    func startTimerProgres() {
        progressTask?.cancel()
        progressTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, let player = self.audioPlayer, player.isPlaying else { return }
                self.updateProgress()
                do {
                    try await Task.sleep(nanoseconds: 100_000_000)
                } catch {
                    return
                }
            }
        }
    }
    
    // 更新进度条
    @objc func updateProgress() {
        guard let player = audioPlayer else { return }
        guard player.duration.isFinite, player.duration > 0 else {
            progressView.progress = 0
            return
        }
        progressView.progress = Float(min(max(player.currentTime / player.duration, 0), 1))
        durationLabel.text = player.currentTime.float.floatToPlayTimeString()
    }

    func stopPlaying() {
        progressTask?.cancel()
        progressTask = nil
        audioPlayer?.stop()
        progressView.progress = 0
        playButton.isSelected = false
        audioPlayer = nil
        durationLabel.text = self.audioDuration.floatToPlayTimeString()
        isPaused = false
    }
}

extension PTChatVoiceCell: @MainActor AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlaying()
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {
        stopPlaying()
    }
}
